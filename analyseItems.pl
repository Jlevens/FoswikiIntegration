#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib 'lib';
use Setup;
use SimpleMeta;
use ReadData;
use Rules;

use Path::Tiny;
use Sort::Naturally;

my %items;

for my $web ( keys %extWebRule ) {
    next unless exists $extWebRule{ $web }{ dataThings };

    my $at = $extWebRule{ $web };
    my ($tglob, $sfield, $closed, $cfield, $type) = @{$at}{ qw(dataThings sfield closed cfield type) };
    chdir("$scriptDir/$web");
    my @Items = nsort ( path(".")->children( $tglob ) );

    for my $item ( @Items ) {
        my $text = path("$item")->slurp_raw;
        my $meta = simpleMeta($text);
        my %field = 
            map { $_->{name} => $_; }
            @{ $meta->{FIELD} }
            ;
        $field{$sfield}{value} //= '';
        my $itemState = ($field{$sfield}{value} =~ $closed) ? 'closed' : 'open';
    
        my $edate = $meta->{TOPICINFO}[0]{date} // 1100000000;
        
        my @components = split(',', $field{$cfield}{value} // '');
        for my $c (@components) {
            $c =~ s/\s//g;
            next if $c !~ $isExtension;
            $c =~ s/Trash.Extensions//;
            say $c;
            
            if( $c =~ m/[\.\/]([A-Za-z0-9]*?)$/ ) { $c = $1 }
            say "-- $c";
            if( $itemState eq 'closed' ) {          
                $items{ $c }{ $web }{ $type }{ closed }++;
            }
            else {
                push @{$items{ $c }{ $web }{ $type }{ $itemState }{ $field{$sfield}{value} }}, $edate;
            }
        }
    }        
}    

dumpData( \%items, "$scriptDir/work/Items.json" );

exit 0;
