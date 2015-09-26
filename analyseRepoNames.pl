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
    say $path;
}

exit 0;
