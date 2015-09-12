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

my $repo = readData( "$scriptDir/work/Repo.json" );

# Logically set-up extensions that are part of distro
chdir("$scriptDir/repos/distro");
my @distroExtensions = glob("*");
for my $distroExt ( @distroExtensions ) {
    next if $distroExt =~ m/^DEL_/;
    next if $distroExt !~ m/(Plugin|Contrib|AddOn|Skin)$/;
    %{$repo->{ $distroExt }} = ( %{$repo->{ distro }}, distro => 'distro/' );
}

dumpData( $repo, "$scriptDir/work/Repo+.json" );

exit 0;
