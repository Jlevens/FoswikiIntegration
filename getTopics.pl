#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib 'lib';
use Setup;
use Rules;
use ReadData;

use Sort::Naturally;
use Archive::Tar;
use Path::Tiny;
use File::Path qw(remove_tree);

use JSON;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->timeout(100);
$ua->env_proxy;

my %topics;
my @noChanges;
for my $web ( sort keys %extWebRule ) {

    my $uri = "http://foswiki.org/Extensions/JsonTopicList?skin=text\&web=$web";
    my $response = $ua->get($uri);

    if( !$response->is_success ) {
        say "Couldn't get $uri because: " . $response->status_line;
        next;
    }

    my $fo_list = JSON::from_json( $response->decoded_content );

    for my $fo_topic ( sort { ncmp($a->{topic},$b->{topic}) } @$fo_list ) {

        my ( $topName, $isodate ) = @{ $fo_topic }{ qw(topic isodate) };
        next if $topName !~ $extWebRule{ $web }{ topicMatch }; # JsonTopicList gives every topic in a Web, we are not interested in every one
        
        my $changed = "$scriptDir/$web/$topName!CHANGED.txt";
        $changed = -e $changed ? path( $changed )->slurp_raw : '';
        
        if( !$isodate || $isodate !~ m/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ ) { # should look like 2014-11-04T17:05:10Z
            print STDERR "FATAL: JsonTopicList for web=$web/$topName did not provide a valid 'isodate' = '$isodate'\n";
            print STDERR "       This is unexpected, please investigate and correct.\n";
            exit 8;
        }

        if( $changed && $changed !~ m/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ ) {
            print STDERR "FATAL: Details in $web/$topName!CHANGED.txt is not a valid date.\n";
            print STDERR "       This is unexpected, please investigate and correct.\n";
            exit 8;
        }
        
#        push @{ $topics{ $topName } }, $web;
        $topics{ $topName }{ $web }{ isodate } = $isodate;

        if( $changed eq $isodate )  {
            push @noChanges, sprintf("%-50s %-24s %-20s %-20s NoChange\n", $topName, $web, $isodate, '');
            print "\n$noChanges[0]" if 1 == @noChanges;
            next;
        }
        path( "$scriptDir/$web/$topName!CHANGED.txt" )->spew_raw( "$isodate");
 
        print "...\n"           if 3 <= @noChanges;
        print $noChanges[-1]    if 2 <= @noChanges;
        @noChanges = ();

        printf "\n%-50s %-24s %-20s %-20s %s\n", $topName, $web, $changed, $isodate, $changed ? 'CHANGED' : 'NEW on JsonTopicList';
        
        # Normally $fetchNew = 1; but it was useful at times during development to not re-load NEW stuff that I knew wasn't actually new
        # Left in place just in case that's useful again
        my $fetchNew = 1;

        if( $changed || (!$changed && $fetchNew) ) { # NB !$changed means it's a new web/topic being fetched
            fetchTopicFiles( $web, $topName );
        }
    }
}
print "...\n"           if 3 <= @noChanges;
print $noChanges[-1]    if 2 <= @noChanges;

dumpData( \%topics, "$scriptDir/work/Topics.json" );

exit 0;

sub fetchTopicFiles {
    my ( $web, $topic ) = @_;

    for my $type ( @{ $extWebRule{ $web }{ fetchAttachType } } ) {
        my $at = $attachType{ $type };

        my $uri  = "http://foswiki.org/" . escape( $at->{requestURL}, web => $web, topic => $topic );
        my $opts = $at->{requestParms} // {};
        my $request = $at->{request};
    
        my $response = $ua->$request($uri, $opts);
    
        unlink( "$scriptDir/$web/$topic$type" );
        remove_tree( "$scriptDir/$web/!$topic$type" ) if -d "$scriptDir/$web/!$topic$type";

        if ($response->is_success) {
            if( $request eq 'post' || $request eq 'get' ) {
                open(my $fh, ">:raw", "$scriptDir/$web/$topic$type");
                print $fh ($response->content);
                close($fh);
            }

            if( $type eq '.tgz' ) {
                mkdir( "$scriptDir/$web/!$topic$type" );
                chdir( "$scriptDir/$web/!$topic$type" );
                Archive::Tar->extract_archive( "$scriptDir/$web/$topic$type" );
            }
        }
        printf "    %-4s %-15s %s\n", $request, $response->is_success ? 'Fetched' : $response->status_line, $uri;
    }
}
