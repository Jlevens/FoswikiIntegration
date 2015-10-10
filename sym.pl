#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib 'lib';
use Setup;

BEGIN {
    package WinSymlinks;
    use English qw( -no_match_vars ) ;
    
    if( $OSNAME eq 'MSWin32' ) {
        *CORE::GLOBAL::symlink = __PACKAGE__->can('symlink');
        *CORE::GLOBAL::readlink = __PACKAGE__->can('readlink');
    }

    use Cwd qw(realpath);
    use File::Spec;        

    sub symlink {
        my ($target, $link) = @_;
        
        $target = File::Spec->canonpath( realpath($target) );
        die "Links->symlink: $target does not exist\n" unless -e $target;
        return 0 if -e $link; # What does linux do?

        $link = File::Spec->canonpath( $link );

        my $switch = -d $target ? '/D' : '';
        my $op = `mklink $switch $link $target`;
        return $op =~ /symbolic link created/i ? 1 : 0; # SMELL: Too dependent on format of mklink output
    }

    sub readlink {
        my ($link) = @_;

        return undef unless -e $link; # SMELL: die instead?
        
        $link = File::Spec->canonpath( realpath($link) );

        my $op = `DIR /A:L /N $link*`; # SMELL: get 'File Not Found' in STDERR if $link not a symlink
#        say "((\n$op))";
        if( my ($dest) = $op =~ m/<SYMLINKD?> [^[]*? \[ ([^]]*?) \] /x ) {
            return $dest;
        }
        return undef; # SMELL: die instead?
    }
}

# Alas overriding -l filetest is difficult for CORE::GLOBAL case
# (can override -X for method of object, but that's not complete enough)

sub isSymlink {
    return defined WinSymlinks::readlink( $_[0] ) ? 1 : 0;
}

use Path::Tiny;
use File::Spec;
use Cwd qw(abs_path realpath);
use English qw( -no_match_vars ) ;

#chdir($scriptDir);
say "$scriptDir";
say $OSNAME;
my $rc = symlink("$scriptDir/README.md", "$scriptDir/README3" );
say $rc;
say "readlink '" . (readlink( "$scriptDir/README3" ) // '**') . "'";
say "readlink '" . (readlink( "$scriptDir/w" ) // '**') . "'";

say -e "$scriptDir/w" ? "w exists" : 'w does not exist';
say -d "$scriptDir/w" ? "w is a Dir" : 'w is not a Dir';
say -f "$scriptDir/w" ? "w is a File" : 'w is not a File';

say -e "$scriptDir/README3" ? "3 exists" : '3 does not exist';
say -d "$scriptDir/README3" ? "3 is a Dir" : '3 is not a Dir';
say -f "$scriptDir/README3" ? "3 is a File" : '3 is not a File';

say isSymlink("README3") ? '3 symlink' : '3 not-symlink';
say isSymlink("README.md") ? 'md symlink' : 'md not-symlink';
say isSymlink("w") ? 'w symlink' : 'w not-symlink';
say -f "README3" ? 'file' : 'not-file';
say -f "README.md" ? 'file' : 'not-file';

$, = " -- ";
say stat("README3");
say stat("README.md");

say path("README3")->slurp_raw;

say abs_path($scriptDir);
say realpath($scriptDir);
say File::Spec->canonpath($scriptDir);

exit 0;
