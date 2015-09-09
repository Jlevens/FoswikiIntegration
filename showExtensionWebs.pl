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

use Scalar::Util qw(reftype)    ;

my $extension = readData( "$scriptDir/work/ExtensionTopics.json" );
my $Forms     = readData( "$scriptDir/work/ExtensionForms.json" );
my $Items     = readData( "$scriptDir/work/Items.json" );
my $repo      = readData( "$scriptDir/work/Repo+.json" );

# Merge data into $extension
for my $thing ($Forms, $Items, $repo) { # $repo follows with different criteria
    for my $ext (keys %$thing) {
        for my $ew (keys %{ $thing->{ $ext } } ) {
            if( ( reftype( $thing->{ $ext }{ $ew } ) // '' ) eq 'HASH' ) {
                for my $major (keys %{ $thing->{ $ext }{ $ew } } ) {
                    if( ( reftype( $thing->{ $ext }{ $ew }{ $major } ) // '' ) eq 'HASH' ) {
                        for my $minor (keys %{ $thing->{ $ext }{ $ew }{ $major } } ) {
                            $extension->{$ext}{$ew}{$major}{$minor} = $thing->{$ext}{$ew}{$major}{$minor};
                        }
                    }
                    else {
                        $extension->{$ext}{$ew}{$major} = $thing->{$ext}{$ew}{$major} if defined $thing->{$ext}{$ew}{$major};
                    }    
                }
            }
            else {
                $extension->{$ext}{$ew} = $thing->{$ext}{$ew} if defined $thing->{$ext}{$ew};
            }
        }
    }
}
dumpData(  $extension, "$scriptDir/work/Merged.json" );

for my $ext ( sort keys %{ $extension } ) {

    next if $ext !~ m/(Contrib|Plugin|AddOn|Skin)\z/;
    
    print $extension->{ $ext }{ Extensions } ? 'E' : '-';
    print $extension->{ $ext }{ Extensions }{ topic } ? 't' : '-';
    
    print $extension->{ $ext }{ 'Extensions/Testing' } ? ' ET' : ' --';
    print $extension->{ $ext }{ 'Extensions/Testing' }{ topic } ? 't' : '-';

    print $extension->{ $ext }{ 'Extensions/Archived' } ? ' EA' : ' --';
    print $extension->{ $ext }{ 'Extensions/Archived' }{ topic } ? 't' : '-';

    print $extension->{ $ext }{ Development }{ topic } ? '  D' : '  -';
    print $extension->{ $ext }{ Support }{ topic } ? 'S' : '-';
    print $extension->{ $ext }{ Tasks }{ topic } ? 'T' : '-';

    print $extension->{ $ext }{ github } ? '  G' : '  -';

    print $extension->{ $ext }{ Tasks }{ Item } ?
            (' I' . ($extension->{ $ext }{ Tasks }{ Item }{ open } ? 'o' : '-') . ($extension->{ $ext }{ Tasks }{ Item }{ closed } ? 'c' : '-') )
            : ' ---'
            ;
    print $extension->{ $ext }{ Support }{ Question } ?
            (' Q' . ($extension->{ $ext }{ Support }{ Question }{ open } ? 'o' : '-') . ($extension->{ $ext }{ Support }{ Question }{ closed } ? 'c' : '-') )
            : ' ---'
            ;

    printf " %-50s ", $ext;

    print "\n";
}

exit 0;
