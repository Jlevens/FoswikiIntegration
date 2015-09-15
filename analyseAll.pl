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

my %analysis;

for my $extName ( sort keys %{ $topic } ) {

    next if $extName !~ $isExtension;
    
    if( $topic->{ $extName }{ Extensions }{ isodate }
            && ($topic->{ $extName }{ Extensions }{ topic }{ form } // '') eq 'PackageForm' 
            && $topic->{ $extName }{ Extensions }{ install }    )   {
        analyseLiveExtension( $extName, $topic->{ $extName } );
    }
}

my @errors = sort { $a->[0] cmp $b->[0] || $b->[1] <=> $a->[1] } @{$analysis{errors}};
for my $e (@errors) {
    printf "| %-40s | %6d | %-50s |\n", @{$e};
}

exit 0;

sub analyseLiveExtension {
    my ( $name, $ext ) = @_;
    
    push @{$analysis{errors}}, [ $name, 100, 'Missing Support Hub' ] unless $ext->{ Support }{ isodate };
    push @{$analysis{errors}}, [ $name, 100, 'Missing Tasks Hub' ] unless $ext->{ Tasks }{ isodate };
    push @{$analysis{errors}}, [ $name, 400, 'No GitHub repo' ] unless $ext->{ _github };
    push @{$analysis{errors}}, [ $name,   1, 'Version in Extensions/Testing' ] if $ext->{ 'Extensions/Testing' }{ isodate };
    push @{$analysis{errors}}, [ $name, 400, 'Version in Extensions/Archived' ] if $ext->{ 'Extensions/Archived' }{ isodate };
    
    for my $digestable ( keys %{ $ext->{ Extensions }{ Digest } } ) {
        for my $digest ( keys %{ $ext->{ Extensions }{ Digest }{ $digestable } } ) {
        
            my $test = $ext->{ Extensions }{ Digest }{ $digestable }{ $digest }{ Test };
            next if $test eq 'M';
        
               if( $test eq 'B' ) { push @{$analysis{errors}}, [ $name, 100, "$digest for $digestable: no attachment no digest filed" ]; }
            elsif( $test eq 'C' ) { push @{$analysis{errors}}, [ $name, 100, "$digest for $digestable: no attachment to check" ]; }
            elsif( $test eq 'S' ) { push @{$analysis{errors}}, [ $name, 100, "$digest for $digestable: no digest filed" ]; }
            elsif( $test eq 'X' ) { push @{$analysis{errors}}, [ $name, 400, "$digest for $digestable: digests mismatch" ]; }
        }
    }       
}
