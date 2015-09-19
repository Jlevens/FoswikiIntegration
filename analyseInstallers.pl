#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib qw( lib );
use Setup;
use ReadData;
use Rules;

use Path::Tiny;

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
    use Digest;
    my $MD5 = Digest->new('MD5')->add( $frag )->hexdigest;
    $fragment{ $ID }{ $STDXXX || 'XXX' }{ $MD5 } = $frag;
    return "$ID-" . ($STDXXX || 'XXX') . "-$MD5.txt";
}

# Add STD fragments to write out later as files for comparison to non-standard versions discovered
for my $stdID (keys %std) {
    frag_md5( $std{ $stdID }, $stdID, 'STD' );
}

my %installers;

for my $web ( keys %extWebRule ) {
    next unless $web =~ m/^Extensions/;

    chdir("$scriptDir/$web");
    my @Items = sort ( path(".")->children( qr/(Contrib|Plugin|AddOn|Skin)_installer\z/ ) );
    
    for my $f ( @Items ) {
        my ( $topName ) = $f =~ m/((.*?)(Contrib|Plugin|AddOn|Skin))_installer\z/;   

        my $installer = "$scriptDir/$web/${topName}_installer";
        next if !-e $installer;
        
        $installer = path($installer)->slurp_raw;
        
        my %install = (); # We always want to know that an installer exists even if there's nothing else worth reporting
        ($installer) = $installer =~ m{ (.*?) ^(1;|__DATA__)$ }mxs; 

        $installer =~ s/\A(.*?)$//m;
        $install{shebang} = $1 if $1 ne "#! /usr/bin/env perl";

        $installer =~ s{(\A.*?)(?:^use\ strict;$)}{}msx;

        my $openingComments = $1;
        $openingComments =~ s/(2(\d){3}-2(\d){3} .*? )/2004-2015 Foswiki /;
        $install{OC}{Date} = $1 if $1 ne '2004-2015 Foswiki '; # && $1 ne '2004-2007 Foswiki ';

        $openingComments =~ s/$topName/SameNamePlugin/g; # Needs to be before following in case the extension-name ($ext) contains TWiki
        $openingComments =~ s/(NextWiki|TWiki)/Foswiki/;
        $install{OC}{name} = $1 if $1;
        
        if( $openingComments =~ s{(http://wikiring\.com)}{http://c-dot\.co\.uk} ) {
            $install{OC}{link} = $1;
        }

        # Because of the fixes applied above, I only expect 1 standard OC, but to trap the unexpected we store away what we find
        $install{OC}{Fragment} = frag_md5( $openingComments, 'OC' ) if $openingComments ne $std{ OC };

        if($installer =~ s{^undef (.*?)(?=^sub preuninstall)}{}ms) {
            my $extractManifest = $1;

            # Later versions appear to have this line TIDY'ed, no value seeing that as different
            $extractManifest =~ s/\( ?defined \$return ?\)/\( defined \$return \)/g;

            $install{EM}{Fragment} = frag_md5( $extractManifest, 'EM' ) if $extractManifest ne $std{ EM };
        }
        else {
            $install{EM}{notFound} = 1;
        }

        $installer =~ s{(^\=pod(.*?)^\=cut$)}{}gms;
        my $pod = $1;
        $pod =~ s/$topName/SameNamePlugin/g;
        $install{POD}{Fragment} = frag_md5( $pod, 'POD' ) if $pod ne $std{ POD }; # In practice, so far, all pods were found to be identical

        for my $sub (qw(preinstall postinstall preuninstall postuninstall)) {
            $installer =~ s/^sub $sub \{(.*?)^\}(?=\s*?(?:sub |Foswiki::|TWiki::))//ms;
            if( !$1 ) {
                $install{$sub}{nonStd} = 'not-found';
                next;
            }
            my $subBody = $1;
            $subBody =~ s{^\s*?\#[^\n]*$}{}gm;

            if( $subBody !~ m/\A\s+\z/ms ) {
                $install{$sub}{Fragment} = frag_md5( $subBody, $sub );
                $install{$sub}{Code} = $subBody;
            }
        }

        my $extender = '';
        $installer =~ s/^((?:TWiki|Foswiki)::Extender::install\(.*?\));$//gms;
        if($1) {
            $extender = $1;
            $extender =~ s/\n//g;
            $extender =~ s/\s{2,}/ /g;
            $extender =~ s/$topName/SameNamePlugin/g;
        }
        $install{Extender} = $extender if $extender ne "Foswiki::Extender::install( \$PACKAGES_URL, 'SameNamePlugin', 'SameNamePlugin', \@DATA )";
                
        $installer =~ s/^my \$PACKAGES_URL\s*?=\s*+([^\n]*?);$//gms;
        $install{Package} = $1 if $1 ne "'http://foswiki.org/pub/$web'";
        
        $installer =~ s/\n{2,}/\n/g;
        $install{REM}{Fragmemt} = frag_md5( $installer, 'REM' ) if $installer ne $std{ REM };

        $installers{ $topName }{ $web }{ install } = \%install; # if %install;
    }
}

unlink path("$scriptDir/Fragments")->children;
for my $ID (keys %fragment) {
    for my $STDXXX (keys %{ $fragment{$ID} }) {
        for my $MD5 (keys %{ $fragment{$ID}{ $STDXXX } }) {
            path("$scriptDir/Fragments/$ID-$STDXXX-$MD5.txt")->spew_raw( $fragment{ $ID }{ $STDXXX }{ $MD5 } );
#            print "$scriptDir/Fragments/$ID-$STDXXX-$MD5.txt  --- $fragment{$ID}{$STDXXX}{$MD5}\n";
        }
    }
}

dumpData( \%installers, "$scriptDir/work/Installers.json");

exit 0;
