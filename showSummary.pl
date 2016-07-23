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
    
    print $topic->{ $ext }{ Extensions } ? 'E' : 'x';
    print $topic->{ $ext }{ Extensions }{ topic }{ attachment_meta }{ _installer } ? 'I' : 'x';
    print "" . ($topic->{ $ext }{ Extensions }{ topic }{ form } // '') eq 'PackageForm' ? 'P' : 'x';
    print $topic->{ $ext }{ Extensions }{ isodate } ? 't' : 'x';
    
    print $topic->{ $ext }{ 'Extensions/Testing' } ? ' ET' : ' xx';
    print $topic->{ $ext }{ 'Extensions/Testing' }{ isodate } ? 't' : 'x';

    print $topic->{ $ext }{ 'Extensions/Archived' } ? ' EA' : ' xx';
    print $topic->{ $ext }{ 'Extensions/Archived' }{ isodate } ? 't' : 'x';

    print $topic->{ $ext }{ Development }{ isodate } ? '  D' : '  x';
    print $topic->{ $ext }{ Support }{ isodate } ? 'S' : 'x';
    print $topic->{ $ext }{ Tasks }{ isodate } ? 'T' : 'x';

    print $topic->{ $ext }{ pushed_at } ? '  G' : '  x';

    print $topic->{ $ext }{ Tasks }{ Item } ?
            (' I' . ($topic->{ $ext }{ Tasks }{ Item }{ open } ? 'o' : 'x') . ($topic->{ $ext }{ Tasks }{ Item }{ closed } ? 'c' : 'x') )
            : ' ---'
            ;
    print $topic->{ $ext }{ Support }{ Question } ?
            (' Q' . ($topic->{ $ext }{ Support }{ Question }{ open } ? 'o' : 'x') . ($topic->{ $ext }{ Support }{ Question }{ closed } ? 'c' : 'x') )
            : ' ---'
            ;

    printf " %-50s ", $ext;

    print "\n";
}

exit 0;
