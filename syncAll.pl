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

use Net::GitHub;
use Path::Tiny;
use POSIX qw(strftime);

my $this_run = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time)); # Capture this *before* we access github to ensure no time gap between runs

if( ! -d "$scriptDir/distro" ) {
    printf "Cloning distro - base for everything else\n";
    chdir($scriptDir);
    `git clone https://github.com/foswiki/distro.git`;
}

my $github = $secrets->{ github }{token}
           ? Net::GitHub->new( access_token => $secrets->{ github }{token}, version => 3 ) 
           : Net::GitHub->new( login => $secrets->{ github }{login}, pass => $secrets->{ github }{pass} );

my $repos = $github->repos;

my @rp = $repos->list_org('foswiki');

#use Data::Dumper;
#$Data::Dumper::Indent = 1;
#$Data::Dumper::Sortkeys = 1;
#print Data::Dumper->Dump( [ \@rp ], [ 'rp' ] );
#
while ( $repos->has_next_page ) {
    push @rp, $repos->next_page;
}

my @ext = path("$scriptDir/distro")->children( qr/^(?!DEL_)(core|.*?(Plugin|Contrib|Skin|Add[Oo]n))$/ );
my %repo = map {
        my $b = path("$_")->basename;
        $b = 'distro' if $b eq 'core';
        my $ldir = $b eq 'distro' ? "distro" : "distro/$b";
        $b => { dir => $ldir }
    }
    @ext;

my $last = readData( "$scriptDir/work/LastRun.json" );

print "\nLooking for changes to pull or new repos to clone:\n\n";

for my $r ( @rp ) {
    my ($name, $description, $pushed_at) = @{$r}{ qw( name description pushed_at ) };
    
    $description =~ s/\h+/ /g;
    $pushed_at //= '0000-00-00T00:00:00Z';
    next unless $name =~ m/^(distro|.*?(Plugin|Contrib|Skin|Add[Oo]n))$/;
    next if $description =~ m/^OBSOLETE/; # Is this the only field avail for the Foswiki project to control it's processes?

    # To be stored in Json file for reference in later scripts
    $repo{ $name }{ description } = $description;
    $repo{ $name }{ pushed_at } = $pushed_at; # Not sure this is needed in later scripts but ...

    if( $pushed_at lt $last->{ pushed_at } ) {
        printf "%-22s %-9s %-40s %s\n", $pushed_at, 'no change', $name, $description;
        next;
    }

    if( $repo{$name}{dir} ) {
        chdir( "$scriptDir/$repo{$name}{dir}" );

        printf "%-22s %-9s %-40s %s\n", $pushed_at, 'pull', $name, $description;
        `git remote update`;
        `git pull --rebase`; # Expectation is that this local repo is *NOT* used for any dev work
        next;
    }

    printf "%-22s %-9s %-40s %s\n", $pushed_at, 'clone', $name, $description;
    chdir( "$scriptDir/distro" );
    `git clone $r->{clone_url}`;    
}

printf "\n\n%-22s %-9s %-40s %s\n", $this_run, '', 'Timestamp of this run', '';

$last->{pushed_at} = $this_run;
dumpData( $last, "$scriptDir/work/LastRun.json" );

dumpData( \%repo, "$scriptDir/work/Repo.json" );

exit 0;
