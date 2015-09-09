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

# Grab details from last run. We wish to note any changes and only fetch changed/new topics
my $extension = readData( "$scriptDir/work/ExtensionTopics.json" );

use JSON;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->timeout(100);
$ua->env_proxy;

my %extWebs = (
    Extensions           => { topics => qr/(Contrib|Plugin|AddOn|Skin)$/, fetch => [ '.txt', '.sha1', '.md5', '.zip', '.tgz', '.installer' ] },
   'Extensions/Testing'  => { topics => qr/(Contrib|Plugin|AddOn|Skin)$/, fetch => [ '.txt', '.sha1', '.md5', '.zip', '.tgz', '.installer' ] },
   'Extensions/Archived' => { topics => qr/(Contrib|Plugin|AddOn|Skin)$/, fetch => [ '.txt', '.sha1', '.md5', '.zip', '.tgz', '.installer' ] },
    Development          => { topics => qr/(Contrib|Plugin|AddOn|Skin)$/, fetch => [ '.txt' ] },
    Tasks                => { topics => qr/(^Item\d+?|Contrib|Plugin|AddOn|Skin)$/, fetch => [ '.txt' ] },
    Support              => { topics => qr/(^Question\d+?|Contrib|Plugin|AddOn|Skin)$/, fetch => [ '.txt' ] },
);

for my $ew ( sort keys %extWebs ) {

    my $uri = "http://foswiki.org/Extensions/JsonTopicList?skin=text\&web=$ew";
    my $response = $ua->get($uri);
    
    if( !$response->is_success ) {
        say "Couldn't get $uri because: " . $response->status_line;
        next;
    }
    my $extTopics = $response->decoded_content;
    my $list = JSON::from_json( $extTopics );
    for my $extJ ( @$list ) {
    
        if( $extJ->{topic} !~ $extWebs{ $ew }{topics} ) {
            delete $extension->{ $extJ->{topic} };
            next;
        }

        # X & Y dummy dates deliberately different to ensure we pick these up as changes
        if( ($extension->{ $extJ->{topic} }{ $ew }{ topic }{ changed } || 'X') eq ($extJ->{ changed } || 'Y') ) {
            say "No changes for  $ew/$extJ->{topic}";
            next;
        }
        delete $extension->{ $extJ->{topic} }{ $ew }{ topic };

        my %types = (
            '.txt'       => ['post', "$ew/$extJ->{topic}", { skin => 'text', raw => 'debug', username => 'JulianLevens', password => 'Queex25@' } ],
            '.sha1'      => ['get',  "pub/$ew/$extJ->{topic}/$extJ->{topic}.sha1", {} ],
            '.md5'       => ['get',  "pub/$ew/$extJ->{topic}/$extJ->{topic}.md5", {} ],
            '.installer' => ['get',  "pub/$ew/$extJ->{topic}/$extJ->{topic}_installer", {} ],
            '.tgz'       => ['get',  "pub/$ew/$extJ->{topic}/$extJ->{topic}.tgz", {} ],
            '.zip'       => ['get',  "pub/$ew/$extJ->{topic}/$extJ->{topic}.zip", {} ],
        );

        for my $type ( @{ $extWebs{ $ew }{ fetch } } ) {
            my ($request, $suffix, $opts) = @{ $types{$type} };
            my $uri = "http://foswiki.org/$suffix";
            my $file = "$ew/$extJ->{topic}$type";
            
            my $response = $ua->$request($uri, $opts);
  
            if ($response->is_success) {
                if( $request eq 'post' || $request eq 'get' ) {
                    open(my $fh, ">:raw", "$scriptDir/$file");
                    print $fh ($response->content);
                    close($fh);
                }
                printf "%-4s %-60s %s\n", $request, $file, $uri;
                $extension->{ $extJ->{topic} }{ $ew }{ topic }{ changed } = $extJ->{changed};
                $extension->{ $extJ->{topic} }{ $ew }{ topic }{ $type } = 'Fetched';
            }
            else {
                printf "Failed  %-60s %s\n", $response->status_line, $uri;
                $extension->{ $extJ->{topic} }{ $ew }{ topic }{ $type } = $response->status_line;
            }
        }
    }        
}

dumpData( $extension, "$scriptDir/work/ExtensionTopics.json");

exit 0;
