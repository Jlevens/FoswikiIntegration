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

use Path::Tiny;
use Sort::Naturally;

my %items;

my %things = (
    Support => {
        glob => qr/\AQuestion\d+\.txt\z/,
        sfield => 'Status',
        closed => qr/Answered|Closed unanswered|Task filed|Task closed|Marked for deletion/,
        cfield => 'Extension',
        type   => 'Question',
    },
    Tasks => {
        glob => qr/\AItem\d+\.txt\z/,
        sfield => 'CurrentState',
        closed => qr/Closed|No Action Required|Duplicate/,
        cfield => 'Component',
        type   => 'Item',
    },
);        

for my $web ( keys %things ) {
    my $thing = $things{ $web };
    my ($tglob, $sfield, $closed, $cfield, $type) = @{$thing}{ qw(glob sfield closed cfield type) };
    chdir("$scriptDir/$web");
    my @Items = nsort ( path(".")->children( $tglob ) );
    
    for my $item (@Items) {
        my $text = path("$item")->slurp_raw;
        my $meta = simpleMeta($text);
        my %field = 
            map { $_->{name} => $_; }
            @{ $meta->{FIELD} }
            ;
        $field{$sfield}{value} //= '';
        my $itemState = $field{$sfield}{value} =~ $closed ? 'closed' : 'open';
    
        my $edate = $meta->{TOPICINFO}[0]{date} // 1100000000;
        
        my @components = split(',', $field{$cfield}{value} // '');
        for my $c (@components) {
            $c =~ s/\s//g;
            next if $c !~ m/(Contrib|Plugin|AddOn|Skin)\z/;
            if( $field{$sfield}{value} =~ $closed ) {          
                $items{ $c }{ $web }{ $type }{ closed }++;
            }
            else {
                push @{$items{ $c }{$web}{$type}{$itemState}{ $field{$sfield}{value} }}, $edate;
            }
        }
    }        
}    

dumpData( \%items, "$scriptDir/work/Items.json" );

exit 0;
