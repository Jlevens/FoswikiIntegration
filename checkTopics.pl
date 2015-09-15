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

# Dangerous, if $isodate fails to be picked up from foswiki.org we could delete everything
# Should only be set with manual run when everything is looking good and to remove old files and references
my $reallyDelete = 0; 

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

        my %topic;

        my $changed = "$scriptDir/$web/$topName!CHANGED\.txt";
        $changed = -e $changed ? path( $changed )->slurp_raw : '2000-01-01T00:00:00Z';
        
        if( !$isodate || $isodate !~ m/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ ) { # should look like 2014-11-04T17:05:10Z
            print STDERR "JsonTopicList for web=$web/$topName did not provide a valid 'isodate', really unexpected!\n";
            print STDERR "    This topic will be marked as unchanged and not downloaded. Please investigate and correct.\n";
            print STDERR "    '$isodate'\n";
            next;
        }

        if( !$changed && !$isodate ) {
            print STDERR "FATAL: $web/$topName missing {isodate} and {changed}. Processing halts\n";
            exit 8;
        }
        
        if( $changed && $changed eq $isodate )  {
            push @noChanges, sprintf("%-50s %-24s %-20s %-20s NoChange\n", $topName, $web, $isodate, '');
            print "\n$noChanges[0]" if 1 == @noChanges;
            next;
        }
 
        print "...\n"           if 3 <= @noChanges;
        print $noChanges[-1]    if 2 <= @noChanges;
        @noChanges = ();

        if( !$changed ) {
            deleteTopicFiles( $web, $topName ); # If really NEW not required, but often with recovery it's necessary

            printf "\n%-50s %-24s %-20s %-20s NEW\n", $topName, $web, '', $isodate;
            fetchTopicFiles( $web, $topName, \%topic, $isodate );
        }
        elsif( $changed ne $isodate ) {
            deleteTopicFiles( $web, $topName );
    
            printf "\n%-50s %-24s %-20s %-20s CHANGED\n", $topName, $web, $changed, $isodate;
            fetchTopicFiles( $web, $topName, \%topic, $isodate );
        }

        if( %topic ) {
            $topics{ $topName }{ $web }{ topic } = \%topic;
        }
    }
}
print "...\n"           if 3 <= @noChanges;
print $noChanges[-1]    if 2 <= @noChanges;

dumpData( \%topics, "$scriptDir/work/Topics.json");

exit 0;

sub fetchTopicFiles {
    my ( $web, $topic, $newTopic, $changed ) = @_;
    return;

    for my $type ( @{ $extWebRule{ $web }{ fetchAttachType } } ) {
        my $at = $attachType{ $type };

        my $uri  = "http://foswiki.org/" . escape( $at->{requestURL}, web => $web, topic => $topic );
        my $opts = $at->{requestParms} // {};
        my $request = $at->{request};
    
        my $response = $ua->$request($uri, $opts);
    
        if ($response->is_success) {
            if( $request eq 'post' || $request eq 'get' ) {
                open(my $fh, ">:raw", "$scriptDir/$web/$topic$type");
                print $fh ($response->content);
                close($fh);
            }
            $newTopic->{ changed } = $changed if $type eq '.txt';
            put( "$scriptDir/$web/$topic\.CHANGED\.$changed" )->spew_raw( "$changed\n") if $type eq '.txt';
            $newTopic->{ topic }{ changed } = $changed;

            if( $type eq '.tgz' ) {
                say "WHAT!!!" if -d "$scriptDir/$web/!$topic$type";
                exit 8 if -d "$scriptDir/$web/!$topic$type";

                mkdir( "$scriptDir/$web/!$topic$type" );
                chdir( "$scriptDir/$web/!$topic$type" );
                Archive::Tar->extract_archive( "$scriptDir/$web/$topic$type" );
            }
        }

        $newTopic->{ attachment }{ $type }
            = $response->is_success
            ? 'Fetched'
            : $response->status_line;

        printf "    %-4s %-15s %s\n", $request, $newTopic->{ attachment }{ $type }, $uri;

        last if $type eq '.txt' && !$response->is_success;
    }
}

sub checkTopicFiles {
    my ( $web, $topic, $newTopic, $changed ) = @_;
    return;

    for my $type ( @{ $extWebRule{ $web }{ fetchAttachType } } ) {
        my $at = $attachType{ $type };

        if( -e "$scriptDir/$web/$topic$type" ) {
            put( "$scriptDir/$web/$topic\.CHANGED\.$changed" )->spew_raw( "$changed\n") if $type eq '.txt';
            $newTopic->{ topic }{ changed } = $changed;
    
            if( $type eq '.tgz' && ! -d "$scriptDir/$web/!$topic$type" ) {
                mkdir( "$scriptDir/$web/!$topic$type" );
                chdir( "$scriptDir/$web/!$topic$type" );
                Archive::Tar->extract_archive( "$scriptDir/$web/$topic$type" );
            }
        }    
        $newTopic->{ attachment }{ $type }
            = -e "$scriptDir/$web/$topic$type"
            ? 'Fetched'
            : "404 Not Found";

        printf "    %-4s %-15s %s\n", '-e', $newTopic->{ attachment }{ $type }, "$scriptDir/$web/$topic$type";
    }
}

# Remove old versions
# Note that some new files may not be fetched
# Thus we delete each file of $type to be sure an old version is not left lying around
# Also delete old extracted archive directories if found
sub deleteTopicFiles {
    my ($web, $topic) = @_;
    return;

    for my $type ( @{ $extWebRule{ $web }{ fetchAttachType } } ) {
        unlink( "$scriptDir/$web/$topic$type" );
        remove_tree( "$scriptDir/$web/!$topic$type" ) if -d "$scriptDir/$web/!$topic$type";
    }
}
