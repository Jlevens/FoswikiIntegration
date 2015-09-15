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

my $Repo  = readData( "$scriptDir/work/Repo.json" );
my $Forms = readData( "$scriptDir/work/Forms.json" );
my $Items = readData( "$scriptDir/work/Items.json" );
my $Digests = readData( "$scriptDir/work/Digests.json" );
my $Installers  = readData( "$scriptDir/work/Installers.json" );

# Merge data into $topic
for my $thing ($Forms, $Items, $Repo, $Installers, $Digests) {
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

exit 0;
