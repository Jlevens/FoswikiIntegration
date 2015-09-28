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
use Rules;

use Path::Tiny;
use Scalar::Util qw(reftype);

my (%items, %allkeys);

my $web = 'Extensions';
chdir("$scriptDir/distro");

my $iter = path("$scriptDir/distro")->iterator( { recurse => 1 } );

while ( my $path = $iter->() ) {
    my $parent = $path->parent;
    next if $parent =~ m{/\.git(/|\z)};
    my $base = lc($path->basename);
    $items{ $parent }{ $base }++;
#    printf "%-40s %s\n", $base, $parent;
}

say "\nHere's the list\n";

for my $parent ( sort keys %items ) {
    for my $base ( sort keys $items{ $parent } ) {
        printf "%-40s %s\n", $base, $parent if $items{ $parent }{ $base } > 1;
    }
}

say "\nHere's the next list\n";

exit 0;
