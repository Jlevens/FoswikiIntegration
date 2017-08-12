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

my @results;

print "|*Summary*|*Extension Name*|\n";

for my $ext ( sort keys %{ $topic } ) {

    next if $ext !~ $isExtension;
    
    my $line = '| ';

    $line .=  $topic->{ $ext }{ Extensions } ? 'E' : 'x';
    $line .=  $topic->{ $ext }{ Extensions }{ topic }{ attachment_meta }{ _installer } ? 'I' : 'x';
    $line .=  "" . ($topic->{ $ext }{ Extensions }{ topic }{ form } // '') =~ '(Extensions\.)?PackageForm' ? 'P' : 'x';
    $line .=  $topic->{ $ext }{ Extensions }{ isodate } ? 't' : 'x';
    
    $line .=  $topic->{ $ext }{ 'Extensions/Testing' } ? ' ET' : ' xx';
    $line .=  $topic->{ $ext }{ 'Extensions/Testing' }{ isodate } ? 't' : 'x';

    $line .=  $topic->{ $ext }{ 'Extensions/Archived' } ? ' EA' : ' xx';
    $line .=  $topic->{ $ext }{ 'Extensions/Archived' }{ isodate } ? 't' : 'x';

    $line .=  $topic->{ $ext }{ Development }{ isodate } ? '  D' : '  x';
    $line .=  $topic->{ $ext }{ Support }{ isodate } ? 'S' : 'x';
    $line .=  $topic->{ $ext }{ Tasks }{ isodate } ? 'T' : 'x';

    $line .=  $topic->{ $ext }{ pushed_at } ? '  G' : '  x';

    $line .=  $topic->{ $ext }{ Tasks }{ Item } ?
            (' I' . ($topic->{ $ext }{ Tasks }{ Item }{ open } ? 'o' : 'x') . ($topic->{ $ext }{ Tasks }{ Item }{ closed } ? 'c' : 'x') )
            : ' ---'
            ;
    $line .=  $topic->{ $ext }{ Support }{ Question } ?
            (' Q' . ($topic->{ $ext }{ Support }{ Question }{ open } ? 'o' : 'x') . ($topic->{ $ext }{ Support }{ Question }{ closed } ? 'c' : 'x') )
            : ' ---'
            ;

    $line .= sprintf "| %-50s ", $ext;

    $line .= "|\n";
    
    push @results, $line;
}

print sort @results;

exit 0;
