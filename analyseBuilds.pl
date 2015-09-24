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
                my ($mf, $digest) = split(' ', $s); # =~ m/^(.*?)\s*?.*?/;
                $mf =~ s/^\"//;
                $mf =~ s/\"$//;
                next if $mf =~ m{^(lib/CPAN|pub/|working/|test/|solr/|locale/)};
                next if $mf !~ m{^(lib/|data/)};

                if( -e "$scriptDir/distro/$e/$mf" ) {        
                    say path("$scriptDir/distro/$e/$mf")->digest("MD5") . "--" . $digest;
                    say path("$scriptDir/Extensions/!$e\.tgz/$mf")->digest("MD5") if -e "$scriptDir/Extensions/!$e\.tgz/$mf";
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
