#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib 'lib';
use Setup;
use ReadData;

my $topic = readData( "$scriptDir/work/Merged.json" );

use Path::Tiny;
use Module::CoreList;
use Path::Iterator::Rule;

my $rule = Path::Iterator::Rule->new; # match anything
$rule->skip_dirs(".git")->skip_dirs('core')->file->name('build.pl'); # OK

# iterator interface
my $next = $rule->iter( "$scriptDir/distro" );

my @inactive;
while ( defined( my $file = $next->() ) ) {
    my $text = path($file)->slurp_raw;
    next if $text !~ m/use Foswiki::Contrib::Build;/;
    if( my ($ext) = $file =~ m{distro/([^/]*+)/lib/Foswiki/(Contrib|Plugins)/\1/build\.pl} ) {
        if(  $topic->{ $ext }{ Extensions }{ topic }{ attachment_meta }{ _installer } &&
            ($topic->{ $ext }{ Extensions }{ topic }{ form } // '') =~ '(Extensions\.)?PackageForm' ) {
            my $dir = path($file)->parent->stringify;
            chdir( $dir);
            say '*' x 130;
            say $ext;
            do_commands("perl build.pl release");
#            say $text;
            say '';
        }
        else {
            push @inactive, $ext;
        }
    }
}

say '';
say 'Extensions that have not been published to Foswiki.org';
print join( "\n", @inactive), "\n";

exit 0;

sub do_commands {
    my ($commands) = @_;

    # print $commands . "\n";
    local $ENV{PATH} = untaint( $ENV{PATH} );

    return `$commands`;
}

sub untaint {
    no re 'taint';
    $_[0] =~ /^(.*)$/;
    use re 'taint';

    return $1;
}
