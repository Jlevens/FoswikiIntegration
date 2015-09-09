#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib qw( lib );
use Setup;
use SimpleMeta;
use ReadData;

use Path::Tiny;
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex);

my $form      = readData( "$scriptDir/work/ExtensionForms.json" );
my $extension = readData( "$scriptDir/work/ExtensionTopics.json" );

my %fragment;
my %std;

# This is the standard Opening Comments block
$std{ OC } = <<'HERE';

#
# Install script for SameNamePlugin
#
# Copyright (C) 2004-2015 Foswiki Contributors. All Rights Reserved.
# Foswiki Contributors are listed in the AUTHORS file in the root of
# this distribution. NOTE: Please extend that file, not this notice.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# As per the GPL, removal of this notice is prohibited.
#
# Author: Crawford Currie http://c-dot.co.uk
#
# NOTE TO THE DEVELOPER: THIS FILE IS GENERATED AUTOMATICALLY
# BY THE BUILD PROCESS DO NOT EDIT IT - IT WILL BE OVERWRITTEN
#
HERE

# This is that standard POD
$std{ POD } = <<'HERE';
=pod

---+ SameNamePlugin_installer
This is the installer script. The basic function of this script is to
locate an archive and unpack it.

It will also check the dependencies listed in DEPENDENCIES and assist
the user in installing any that are missing. The script also automatically
maintains the revision histories of any files that are being installed by the
package but already have ,v files on disc (indicating that they are
revision controlled).

The script also functions as an *uninstaller* by passing the parameter
=uninstall= on the command-line. Note that uninstallation does *not* revert
the history of any topic changed during the installation.

The script allows the definition of PREINSTALL and POSTINSTALL scripts.
These scripts can be used for example to modify the configuration during
installation, using the functions described below.

Refer to the documentation of =configure=

=cut
HERE
chomp( $std{POD} ); # We do not want the trailing newline from the HERE-doc

# This is the standard Extract Manifest code
$std{ EM } = <<'HERE';
$/;
my @DATA = split( /<<<< (.*?) >>>>\s*\n/, <DATA> );
shift @DATA;    # remove empty first element

# Establish where we are
my @path = ( 'tools', 'extender.pl' );
my $wd = Cwd::cwd();
$wd =~ /^(.*)$/;    # untaint
unshift( @path, $1 ) if $1;
my $script = File::Spec->catfile(@path);

unless ( my $return = do $script ) {
    my $message = <<MESSAGE;
************************************************************
Could not load $script

Change to the root directory of your Foswiki installation
before running this installer.

MESSAGE
    if ($@) {
        $message .= "There was a compile error: $@\n";
    }
    elsif ( defined $return ) {
        $message .= "There was a file error: $!\n";
    }
    else {
        $message .= "An unspecified error occurred\n";
    }

    # Try again, using open. This cures some uncooperative platforms.
    if ( open( F, '<', $script ) ) {
        local $/;
        my $data = <F>;
        close(F);
        $data =~ /^(.*)$/s;    # untaint
        eval $1;
        if ($@) {
            $message .= "Error when trying to eval the file content: $@\n";
        }
        else {
            print STDERR
              "'do $script failed, but install was able to proceed: $message";
            undef $message;
        }
    }
    else {
        $message .= "Could not open file using open() either: $!\n";
    }
    die $message if $message;
}

HERE

# After extracting known pieces from the installer script this is the REMnant
$std{ REM } = <<'HERE';

use warnings;
require 5.008;
use File::Spec;
use Cwd;
# This is all done in package Foswiki so that reading LocalSite.cfg and Foswiki.cfg
# will put the config vars into the right namespace.
package Foswiki;
# The root of package URLs
# Extract MANIFEST and DEPENDENCIES from the __DATA__
HERE

sub frag_md5 {
    my ($frag, $ID, $STDXXX) = @_;
    my $MD5 = md5_hex( $frag );
    $fragment{ $ID }{ $STDXXX || 'XXX' }{ $MD5 } = $frag;
    return $MD5;
}

# Add STD fragments to write out later as files for comparison to non-standard versions discovered
for my $stdID (keys %std) {
    frag_md5( $std{ $stdID }, $stdID, 'STD' );
}

my %rules = (
    txt         => {
        fileExt     => '.txt',
    },
    zip         => {
        fileExt     => '.zip',
        tests       => { attachFound => 1, metaFound => 1, sha1 => 1, md5 => 1, },
    },
    tgz         => {
        fileExt     => '.tgz',
        tests       => { attachFound => 1, metaFound => 1, sha1 => 1, md5 => 1, },
    },
    installer   => {
        fileExt     => '.installer',
        tests       => { attachFound => 1, metaFound => 1, sha1 => 1, md5 => 1, },
    },
    sha1        => {
        fileExt     => '.sha1',
        tests       => { attachFound => 1, metaFound => 1 },
        isDigest    => \&sha1_hex, 
    },
    md5         => {
        tests       => { attachFound => 1, metaFound => 1 },
        isDigest    => \&md5_hex,
    },
);

for my $extName ( sort keys %{$extension} ) {
    my @errors;

    next unless $extension->{ $extName }{ Extensions }{ topic }{ '.installer' };
    next unless $form->{ $extName }{ Extensions }{ topic }{ form } // '' eq 'PackageName';
    
    say $extName;
    
    my $text = path("$scriptDir/Extensions/$extName.txt")->slurp_raw();
#    my $meta = simpleMeta( $text );
    my $ext = $extension->{ $extName }{ Extensions };
    
    $ext->{ attach } = $form->{ $extName }{ Extensions }{ topic }{ attachments };
#        {
#        map { m/\A$ext(.*?)\z/; my $suf = $1; $suf =~ s/^_/\./; $suf => 1; }
#        grep { /^$ext/; }
#        keys %{ $meta->{_indices}{FILEATTACHMENT} }
#        };

    for my $digest ( grep { $rules{ $_ }->{isDigest}; } keys %rules ) {
        my @dlines = -e "$scriptDir/Extensions/$ext.$digest" 
                 ? path("$scriptDir/Extensions/$ext.$digest")->lines( { chomp => 1 } )
                 : ()
                 ;
        $ext->{ $digest } = { '.installer' => '*no_inst*', '.tgz' => '*no.tgz*', '.zip' => '*no.zip*' };

        for my $dline ( @dlines ) {
            my ($dhex, $file) = split(' ', $dline);
            next if !defined $dhex; # Can happen with blank lines
            $file =~ s/_/\./; # _installer to .installer
            my ($suffix) = $file =~ m{.*?(\..*?)$};
            $ext->{ digest }{ $digest }{ $suffix } = $dhex;
        }
    }

    for my $suffix ( qw(.installer .tgz .zip .md5 .sha1 ) ) {
        my $file = "$extName$suffix";

        # Attachment found or not Y/N; META:FILEATTACHMENT found Y/N; md5 matches or not 5/x; sha1 matches or not 1/x
        my $aerrs = '';

        $aerrs .= $ext->{ topic }{ $suffix } eq 'Fetched'
                ? 'Y' : 'N';
        $aerrs .= $ext->{ attach }{$suffix}
                ? 'Y' : 'N';
        
        if( $suffix =~ m/installer|tgz|zip/ ) {
            my $fdigest;
            eval {
                $fdigest = -e "$scriptDir/Extensions/$file" ? $rules{ $suffix }->isDigest( path("$scriptDir/Extensions/$file")->slurp_raw ) : 'Y';
            };
            $fdigest = "@\: $@" if $@;
            $aerrs .= $ext->{ $fdigest }{ $suffix } // 'X' eq $fdigest
                    ? 'Y' : 'N';
        }
           
#        push @errors, "$suffix | MD5 Mismatch: .md5=$ext->{$suffix}{$digest} actual=$fdigest" if $ext->{ $suffix }{ $digest } ne $fdigest;
        print "$suffix: $aerrs\n";
    }
    my $installer = "$scriptDir/Extensions/$extName.installer";
    if( -e $installer ) {
        $installer = path($installer)->slurp_raw;
        ($installer) = $installer =~ m{ (.*?) ^(1;|__DATA__)$ }mxs; 

        $installer =~ s/\A(.*?)$//m;
        my $shebang = $1;
        #push @errors, "Shebang '$shebang'" if $shebang ne '#! /usr/bin/env perl';

        $installer =~ s{(\A.*?)(?:^use\ strict;$)}{}msx;

        my $openingComments = $1;
        $openingComments =~ s/(2(\d){3}-2(\d){3} .*? )/2004-2015 Foswiki /;
        push @errors, "OC: $1" if $1 ne '2004-2015 Foswiki ' && $1 ne '2004-2007 Foswiki ';

        $openingComments =~ s/$ext/SameNamePlugin/g; # Needs to be before following in case the extension-name ($ext) contains TWiki
        $openingComments =~ s/NextWiki|TWiki/Foswiki/; # Not treated as an error as it's repeated in the above '2nnn-2nnn' bit
        
        if( $openingComments =~ s{(http://wikiring\.com)}{http://c-dot\.co\.uk} ) {
            push @errors, "OC: $1" if $1 ne 'http://c-dot.co.uk';
        }

        # Because of the fixes applied above, I only expect 1 standard OC, but to trap the unexpected we store away what we find
        push @errors, "OC: " . frag_md5( $openingComments, 'OC' ) if $openingComments ne $std{ OC };

        if($installer =~ s{^undef (.*?)(?=^sub preuninstall)}{}ms) {
            my $extractManifest = $1;

            # Later versions appear to have this line TIDY'ed, no value seeing that as different
            $extractManifest =~ s/\( ?defined \$return ?\)/\( defined \$return \)/g;

            push @errors, "EM: " . frag_md5( $extractManifest, 'EM' ) . ($extractManifest =~ /twiki/i ? ' +TWiki' : '') if $extractManifest ne $std{ EM };
        }
        else {
            push @errors, "EM: ''";
        }

        $installer =~ s{(^\=pod(.*?)^\=cut$)}{}gms;
        my $pod = $1;
        $pod =~ s/$ext/SameNamePlugin/g;
        push @errors, "pod: " . frag_md5( $pod, 'POD' ) if $pod ne $std{ POD }; # In practice, so far, all pods were found to be identical

        for my $sub (qw(preinstall postinstall preuninstall postuninstall)) {
            $installer =~ s/^sub $sub \{(.*?)^\}(?=\s*?(?:sub |Foswiki::|TWiki::))//ms;
            if( !$1 ) {
                push @errors, "$sub: (not-found)";
                next;
            }
            my $subBody = $1;
            $subBody =~ s{^\s*?\#[^\n]*$}{}gm;
            push @errors, "$sub: " . frag_md5( $subBody, $sub ) if $subBody !~ m/\A\s+\z/ms;
        }

        my $extender = '';
        $installer =~ s/^((?:TWiki|Foswiki)::Extender::install\(.*?\));$//gms;
        if($1) {
            $extender = $1;
            $extender =~ s/\n//g;
            $extender =~ s/\s{2,}/ /g;
            $extender =~ s/$ext/SameNamePlugin/g;
        }
        push @errors, "$extender" if $extender ne "Foswiki::Extender::install( \$PACKAGES_URL, 'SameNamePlugin', 'SameNamePlugin', \@DATA )";
                
        $installer =~ s/^my \$PACKAGES_URL\s*?=\s*+([^\n]*?);$//gms;
        my $packages_url = $1;
        push @errors, "Package '$packages_url'" if $packages_url ne "'http://foswiki.org/pub/Extensions'";
    
        $installer =~ s/\n{2,}/\n/g;
        push @errors, "Remnants: " . frag_md5( $installer, 'REM' ) . ($installer =~ /twiki/i ? ' +TWiki' : '') if $installer ne $std{ REM };
    }

    for my $err (@errors) {
        say "| $extName | $err |";
    }
}

for my $ID (keys %fragment) {
    for my $STDXXX (keys %{ $fragment{$ID} }) {
        for my $MD5 (keys %{ $fragment{$ID}{ $STDXXX } }) {
            path("$scriptDir/Fragments/$ID-$STDXXX-$MD5.txt")->spew_raw( $fragment{ $ID }{ $STDXXX }{ $MD5 } );
        }
    }
}

exit 0;
