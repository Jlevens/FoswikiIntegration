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

my $topic = readData( "$scriptDir/work/Merged.json" );

for my $ext ( sort keys %{ $topic } ) {

    next if $ext !~ $isExtension;
    
    print $topic->{ $ext }{ Extensions } ? 'E' : '-';
    print $topic->{ $ext }{ Extensions }{ isodate } ? 't' : '-';
    print "" . ($topic->{ $ext }{ Extensions }{ topic }{ form } // '') eq 'PackageForm' ? 'P' : '-';
    print $topic->{ $ext }{ Extensions }{ install } ? 'I' : '-';
    
    print $topic->{ $ext }{ 'Extensions/Testing' } ? ' ET' : ' --';
    print $topic->{ $ext }{ 'Extensions/Testing' }{ isodate } ? 't' : '-';

    print $topic->{ $ext }{ 'Extensions/Archived' } ? ' EA' : ' --';
    print $topic->{ $ext }{ 'Extensions/Archived' }{ isodate } ? 't' : '-';

    print $topic->{ $ext }{ Development }{ isodate } ? '  D' : '  -';
    print $topic->{ $ext }{ Support }{ isodate } ? 'S' : '-';
    print $topic->{ $ext }{ Tasks }{ isodate } ? 'T' : '-';

    print $topic->{ $ext }{ _github } ? '  G' : '  -';

    print $topic->{ $ext }{ Tasks }{ Item } ?
            (' I' . ($topic->{ $ext }{ Tasks }{ Item }{ open } ? 'o' : '-') . ($topic->{ $ext }{ Tasks }{ Item }{ closed } ? 'c' : '-') )
            : ' ---'
            ;
    print $topic->{ $ext }{ Support }{ Question } ?
            (' Q' . ($topic->{ $ext }{ Support }{ Question }{ open } ? 'o' : '-') . ($topic->{ $ext }{ Support }{ Question }{ closed } ? 'c' : '-') )
            : ' ---'
            ;

    printf " %-50s ", $ext;

    print "\n";
}

exit 0;
