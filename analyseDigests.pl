#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib qw( lib );
use Setup;
use ReadData;
use Rules;

use Path::Tiny;
use Digest;

my %digests;

for my $web ( keys %extWebRule ) {
    next unless $web =~ m/^Extensions/;
    
    chdir("$scriptDir/$web");
    my @Items = sort ( path(".")->children( qr/^(?!!).*?(Contrib|Plugin|AddOn|Skin)(_installer|\.sha1|\.md5|\.zip|\.tgz)\z/ ) );
    
    for my $f ( @Items ) {
        my ( $topName ) = $f =~ m/((.*?)(Contrib|Plugin|AddOn|Skin))(_installer|\.sha1|\.md5|\.zip|\.tgz)\z/;   
        next if $digests{ $topName }{ $web };

        say $topName;
        $digests{ $topName }{ $web } = {};

        for my $digest ( keys %attachType ) {
        
            my $dt = $attachType{ $digest };
            next unless $dt->{digest};
            
            my $digestFile = "$topName$digest";
            
            my @dlines = -e $digestFile 
                     ? path( $digestFile )->lines( { chomp => 1 } )
                     : ()
                     ;

            for my $dline ( @dlines ) {
                my ($d_hex, $dType) = $dline =~ m/([a-fA-F0-9]{32,40})\s+?$topName(\S+)\z/;

                next if !defined $d_hex; # Can happen with blank lines

                $digests{ $topName }{ $web }{ Digest }{ $dType }{ $dt->{digest} }{ Stored } = $d_hex;
            }

            for my $digestable ( keys %attachType ) {
                my $dtbl = $attachType{ $digestable };
                next unless $dtbl->{digestable};
                
                my $dAttachment = "$topName$digestable";
                my $digester = Digest->new( $dt->{digest} );

                my $Calculated = -e $dAttachment ? $digester->add( path("$dAttachment")->slurp_raw )->hexdigest : 'C';
                my $Stored = ( $digests{ $topName }{ $web }{ Digest }{ $digestable }{ $dt->{digest} }{ Stored } // 'S');

                my $Test = $Calculated eq $Stored                       ? 'M' # Matches
                         : $Calculated eq 'C' && $Stored eq 'S'         ? 'B' # Both missing
                         : $Calculated eq 'C'                           ? 'C' # Calculated missing (attachment not actually attached)
                         :                       $Stored eq 'S'         ? 'S' # Stored missing (digest not in digest-file or no digest-file at all)
                         :                                                'X' # digests found but mismatch
                         ;
                $digests{ $topName }{ $web }{ Digest }{ $digestable }{ $dt->{digest} }{ Test } = $Test; # if $Test ne 'M';
                $digests{ $topName }{ $web }{ Digest }{ $digestable }{ $dt->{digest} }{ Calculated } = $Calculated if $Test =~ m/S|X/;
            }            
        }    
    }
}

dumpData( \%digests, "$scriptDir/work/Digests.json" );

exit 0;
