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

for my $web ( keys %extWebRule ) {
    next unless $web =~ m/^Extensions/;
    
    chdir("$scriptDir/$web");
    my @Items = sort ( path(".")->children( qr/^!.*?(Contrib|Plugin|AddOn|Skin)\.tgz\z/ ) );
    
    for my $f ( @Items ) {
        my $e = $f;
        $e =~ s/^!//;
        $e =~ s/\.tgz$//;

        my $iter = path("$scriptDir/distro/$e/lib")->iterator( { recurse => 1 } );
        while ( my $path = $iter->() ) {
            my $base = $path->basename;
            next unless $base eq 'MANIFEST';
            my @slurps = path("$path")->lines_raw( { chomp => 1 } );
            for my $s (@slurps) {
                next if $s =~ m/^\s*?(#|!)/;
                next if $s =~ m/^\A\s*?\z/;
                my ($mf) = split(' ', $s); # =~ m/^(.*?)\s*?.*?/;
                $mf =~ s/^\"//;
                $mf =~ s/\"$//;
#                next if $mf =~ m{^(lib/CPAN|pub/|working/|test/|solr/|locale/)};
#                next if $mf !~ m{^(lib/|data/)};
#                say $mf;
#                next;
                my $gitMD5 = -e "$scriptDir/distro/$e/$mf"
                              ? path("$scriptDir/distro/$e/$mf")->digest("MD5")
                              : '';
                my $extMD5 = -e "$scriptDir/Extensions/!$e\.tgz/$mf"
                              ? path("$scriptDir/Extensions/!$e\.tgz/$mf")->digest("MD5")
                              : '';

                if( $gitMD5 ne $extMD5 || $gitMD5 eq '' || $extMD5 eq '' ) {
                    printf "%-40s %-50s %-32s %-32s\n", $e, $mf, $gitMD5, $extMD5;
                }

                              
#                else {
#                  say "-- $mf" if !-e "$scriptDir/Extensions/!$e\.tgz/$mf";            
#                  say "!! $mf" if !-e "$scriptDir/distro/$e/$mf";
#                }
            }
            last;
        }
    }
}

exit 0;
