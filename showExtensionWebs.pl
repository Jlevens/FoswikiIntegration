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

use Scalar::Util qw(reftype)    ;

my $topic = readData( "$scriptDir/work/Topics.json" );
my $Forms = readData( "$scriptDir/work/Forms.json" );
my $Items = readData( "$scriptDir/work/Items.json" );
my $repo  = readData( "$scriptDir/work/Repo+.json" );

# Merge data into $topic
for my $thing ($Forms, $Items, $repo) {
    for my $ext (keys %$thing) {
        for my $ew (keys %{ $thing->{ $ext } } ) {
            if( ( reftype( $thing->{ $ext }{ $ew } ) // '' ) eq 'HASH' ) {
                for my $major (keys %{ $thing->{ $ext }{ $ew } } ) {
                    if( ( reftype( $thing->{ $ext }{ $ew }{ $major } ) // '' ) eq 'HASH' ) {
                        for my $minor (keys %{ $thing->{ $ext }{ $ew }{ $major } } ) {
                            $topic->{$ext}{$ew}{$major}{$minor} = $thing->{$ext}{$ew}{$major}{$minor};
                        }
                    }
                    else {
                        $topic->{$ext}{$ew}{$major} = $thing->{$ext}{$ew}{$major} if defined $thing->{$ext}{$ew}{$major};
                    }    
                }
            }
            else {
                $topic->{$ext}{$ew} = $thing->{$ext}{$ew} if defined $thing->{$ext}{$ew};
            }
        }
    }
}
dumpData( $topic, "$scriptDir/work/Merged.json" );

for my $ext ( sort keys %{ $topic } ) {

    next if $ext !~ $isExtension;
    
    print $topic->{ $ext }{ Extensions } ? 'E' : '-';
    print $topic->{ $ext }{ Extensions }{ topic } ? 't' : '-';
    
    print $topic->{ $ext }{ 'Extensions/Testing' } ? ' ET' : ' --';
    print $topic->{ $ext }{ 'Extensions/Testing' }{ topic } ? 't' : '-';

    print $topic->{ $ext }{ 'Extensions/Archived' } ? ' EA' : ' --';
    print $topic->{ $ext }{ 'Extensions/Archived' }{ topic } ? 't' : '-';

    print $topic->{ $ext }{ Development }{ topic } ? '  D' : '  -';
    print $topic->{ $ext }{ Support }{ topic } ? 'S' : '-';
    print $topic->{ $ext }{ Tasks }{ topic } ? 'T' : '-';

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
