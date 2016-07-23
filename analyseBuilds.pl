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

my %builds;

for my $web ( keys %extWebRule ) {
    next unless $web =~ m/^Extensions/;
    
    chdir("$scriptDir/$web");
    my @Items = sort ( path(".")->children( qr/^!.*?(Contrib|Plugin|AddOn|Skin)\.tgz\z/ ) );
    
    for my $f ( @Items ) {
        my $e = $f;
        $e =~ s/^!//;
        $e =~ s/\.tgz$//;
        
        say $e;

        my $iter = path("$scriptDir/distro/$e")->iterator( { recurse => 1 } );
        
        my %manifest;
        while ( my $path = $iter->() ) {
            my $base = $path->basename;

            next if -d $path;
            my ($suffix) = $base =~ m/(?:.*?)\.([^.]*?)\z/;
#            printf "%-10s %s\n", $suffix // '--', $base;
            $builds{ Suffices }{ $suffix // '--' } += 1;

#            say "     $base";
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
#                say "!!         $mf";
                
                
                my $gitMD5 = -e "$scriptDir/distro/$e/$mf"
                              ? path("$scriptDir/distro/$e/$mf")->digest("MD5")
                              : 'G';
                my $extMD5 = -e "$scriptDir/Extensions/!$e\.tgz/$mf"
                              ? path("$scriptDir/Extensions/!$e\.tgz/$mf")->digest("MD5")
                              : 'E';

                if( $gitMD5 eq $extMD5 ) {
                    push @{ $manifest{ matches } }, $mf;
                    next;
                }
                push @{ $manifest{ firstFail } }, { mf => $mf, git=>$gitMD5, tgz=>$extMD5 };
                next;
            }
        }
        $manifest{ notFound } = 1 if !%manifest;
        $manifest{ matched } = 1 if !$manifest{ firstFail } && $manifest{ matches };
        $builds{ $e }{ $web }{ build } = \%manifest;
    }
}
say "\n\nDumping ...";
dumpData( \%builds, "$scriptDir/work/Builds2.json" );

for my $k ( sort keys %{$builds{ Suffices }} ) {
    say "$k   $builds{ Suffices }{ $k }";
}

exit 0;
