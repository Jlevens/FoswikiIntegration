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

my $repoDir = "$scriptDir/repos";
my %repo;

my $github = $secrets->{ github }{token}
           ? Net::GitHub->new( access_token => $secrets->{ github }{token} ) 
           : Net::GitHub->new( login => $secrets->{ github }{login}, pass => $secrets->{ github }{pass} );

my $search = $github->search;
my $repos = $github->repos;

my $page = 0;
while (1) {

    my %data = $search->repositories({
        q => 'user:foswiki',
        order => 'desc',
        per_page => 100,
        page => ++$page,
    });

    my @refs = @{ $data{items} };
    last unless @refs;

    print "Page: $page\n";

    for my $r (@refs) {
        next if $r->{description} =~ m/^OBSOLETE:/; # Is this the only field avail for the Foswiki project to control it's processes?

        $repo{ $r->{name} }{ _github }{ description } = $r->{ description };
        $repo{ $r->{name} }{ _github }{ clone_url } = $r->{ clone_url };
        $repo{ $r->{name} }{ _github }{ default_branch } = $r->{ default_branch };
        $repo{ $r->{name} }{ _github }{ sha } = '';
    }
}

# Rarely (and it's appears to be random) we get a '' commit-id from github, it's usually a lie so we loop round
# at least twice.

# As each time around we only retrieve the missing { _github }{sha}. Therefore, the 2nd (or more) times around
# we will only talk to the github API (which is slow) one or twice, if at all.

for my $repeat (1..2) {
    print "\n\nFetching from github the sha commit-id of all repos: #$repeat\n\n";
    for my $name (sort keys %repo) {
        next if $repo{ $name }{ _github }{ sha } ne '';  # only if we haven't got this sha yet

        # SMELL: For all foswiki repos {default_branch} is 'master' in principle that could change.
        # The code uses the default_branch as provided by github, but I'm not sure that's enough
        
        # A repo may be 'Empty' both on github and locally. It's useful to give these cases a
        # special commit-id of 'Empty'. As and when the github commit-id becomes a real one
        # then it will not-match 'Empty' and we will pull in the latest changes

        my $commit;
        eval {
            $commit = $repos->commit( 'foswiki', $name, $repo{ $name }{ _github }{ default_branch } );
        };
        if( $@ ) {
            #print "repos->commit error: '$@'\n";
            $commit->{sha} = 'Empty'; # SMELL: Only error that I know of, so this might be fragile
        }
        $repo{ $name }{ _github }{ sha } = $commit->{sha};
        printf "%-40s %s\n", $name, $commit->{sha};
    }
}

print "\n\nFetching from all local repos directory the sha commit-id:\n\n";

chdir($repoDir); # We want to glob leaf names (therefore the repository name) only
for my $name (glob("*")) {
    next unless -d $name; # Ignore files etc

    my $branch = $repo{ $name }{ _github }{ default_branch } || 'master';
    # say "$repoDir/$name/.git";
        
    # Possibly I should read 'HEAD' and infer the branch I need, OTOH maybe master is always the one we need
    if( -d "$repoDir/$name/.git" ) {  
        my $lsha = "$repoDir/$name/.git/refs/heads/$branch";      
        $lsha = -e $lsha ? path($lsha)->slurp : 'Empty';
        chomp($lsha);
        $repo{ $name }{ _local }{ sha } = $lsha // 'Empty';
    }
    else {
        $repo{ $name }{ _local }{ sha } = 'Dir-is-not-a-git-repo';
    }
    printf "%-40s %s\n", $name, $repo{ $name }{ _local }{ sha };
}

print "\n\nLooking for changes to pull or new repos to clone:\n\n";

for my $name (sort keys %repo) {
    my $lsha = $repo{$name}{ _local }{sha} || '';
    my $gsha = $repo{$name}{ _github }{sha} || '';

    if( $lsha && $gsha ) {      # Repo already local and on github, so maybe git pull to sync
        next if $gsha eq $lsha; # but only if the commit-ids have changed
        printf "pull  %-30s %-40s %-40s\n", $name, $gsha, $lsha;
        chdir("$repoDir/$name");
        `git pull --rebase`; # Expectation is that this local repo is *NOT* used for any dev work
    }
    elsif( $gsha ) {
        printf "clone %-30s %-40s %-40s\n", $name, $gsha, $repo{$name}{ _github }{clone_url};
        chdir($repoDir);
        `git clone $repo{$name}{ _github }{clone_url}`;
    }
    else {
        printf "Dele? %-30s %-40s %-40s\n", $name, '', $lsha unless $lsha eq 'Dir-is-not-a-git-repo';
    }
}

# Logically set-up extensions that are part of distro
chdir("$scriptDir/repos/distro");
my @distroExtensions = glob("*");
for my $distroExt ( @distroExtensions ) {
    next if $distroExt =~ m/^DEL_/;
    next if $distroExt !~ m/(Plugin|Contrib|AddOn|Skin)$/;
    %{$repo{ $distroExt }} = ( %{$repo{ distro }}, distro => 'distro/' );
}

dumpData( \%repo, "$scriptDir/work/Repo.json" );

exit 0;
