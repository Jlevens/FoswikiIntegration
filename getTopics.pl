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
use File::Path qw(remove_tree);

# Grab details from last run. We wish to note any changes and only fetch changed/new topics
my $topics = readData( "$scriptDir/work/Topics.json" );

use JSON;
use LWP::UserAgent;

# Dangerous, if $isodate fails to be picked up from foswiki.org we could delete everything
# Should only be set with manual run when everything is looking good and to remove old files and references
my $reallyDelete = 0; 

my $ua = LWP::UserAgent->new;
$ua->timeout(100);
$ua->env_proxy;

for my $web ( sort keys %extWebRule ) {

    my $uri = "http://foswiki.org/Extensions/JsonTopicList?skin=text\&web=$web";
    my $response = $ua->get($uri);

    if( !$response->is_success ) {
        say "Couldn't get $uri because: " . $response->status_line;
        next;
    }

    my $fo_list = JSON::from_json( $response->decoded_content );

    for my $fo_topic ( sort { ncmp($a->{topic},$b->{topic}) } @$fo_list ) {

        my ( $fo_topic, $fo_changed ) = @{ $fo_topic }{ qw(topic isodate) };
        next if $fo_topic !~ $extWebRule{ $web }{ topicMatch }; # JsonTopicList gives every topic in a Web, we are not interested in every one

        if( !$fo_changed || $fo_changed !~ m/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ ) { # should look like 2014-11-04T17:05:10Z

            print STDERR "JsonTopicList for web=$web/$fo_topic did not provide a valid 'isodate', really unexpected!\n";
            print STDERR "    This topic will be marked as unchanged and not downloaded. Please investigate and correct.\n";
            print STDERR "    '$fo_changed'\n";
            $topics->{ $fo_topic }{ $web }{ topic }{ isodate } =
                $topics->{ $fo_topic }{ $web }{ topic }{ changed }
                //= '2000-01-01T00:00:00Z'; # Paranoia: ensure both same with signature date if not in existing file, this date can be searched to find issues
            next;
        }
        $topics->{ $fo_topic }{ $web }{ topic }{ isodate } = $fo_changed;
    }
}

my @noChanges;
for my $topName ( nsort keys %{ $topics } ) {
    for my $web ( sort keys %{ $topics->{ $topName } } ) {

        my $topic = $topics->{$topName}{$web}{topic};

        my $isodate = $topic->{ isodate } // '';
                
        delete $topics->{ $topName }{ $web }{ topic }{ isodate }; # Ensure next run only uses lastest isodate of topic from foswiki.org

        if( !$topic->{ changed } && !$isodate ) {
            print STDERR "FATAL: $web/$topName missing {isodate} and {changed}. Processing halts\n";
            exit 8;
        }
        
        if( $topic->{ changed } && $topic->{ changed } eq $isodate )  {
            push @noChanges, sprintf("%-50s %-24s %-20s %-20s NoChange\n", $topName, $web, $isodate, '');
            print "\n$noChanges[0]"                     if 1 == @noChanges;
            next;
        }
 
        print "...\n"           if 3 <= @noChanges;
        print $noChanges[-1]    if 2 <= @noChanges;
        @noChanges = ();

        my %newTopic;
               
        if( !$topic->{ changed } ) {
            deleteTopicFiles( $web, $topName ); # If really NEW not required, but often with recovery it's necessary

            printf "\n%-50s %-24s %-20s %-20s NEW\n", $topName, $web, '', $isodate;
            fetchTopicFiles( $web, $topName, \%newTopic, $isodate );
        }
        elsif( !$isodate ) {
            if( $reallyDelete ) { # Dangerous, if $isodate fails to be picked up from foswiki.org we could delete everything
                deleteTopicFiles( $web, $topName );
            }
            else {
                $newTopic{ deleted } = 1;          # So, just mark as deleted
                $newTopic{ changed } = $topic->{ changed }; # In case DELETE was in error this makes recovery easier
            }
            printf "\n%-50s %-24s %-20s %-20s DELETED\n", $topName, $web, $topic->{ changed }, '';
        }
        elsif( $topic->{ changed } ne $isodate ) {
            deleteTopicFiles( $web, $topName );
    
            printf "\n%-50s %-24s %-20s %-20s CHANGED\n", $topName, $web, $topic->{ changed }, $isodate;
            fetchTopicFiles( $web, $topName, \%newTopic, $isodate );
        }
         
        if( %newTopic ) {
            $topics->{ $topName }{ $web }{ topic } = \%newTopic;
        }
        else {
            delete $topics->{ $topName }{ $web };
        }
    }
    
    delete $topics->{ $topName } if !%{ $topics->{ $topName } };
}
print "...\n"           if 3 <= @noChanges;
print $noChanges[-1]    if 2 <= @noChanges;

dumpData( $topics, "$scriptDir/work/Topics.json");

exit 0;

sub fetchTopicFiles {
    my ( $web, $topic, $newTopic, $changed ) = @_;

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

    for my $type ( @{ $extWebRule{ $web }{ fetchAttachType } } ) {
        my $at = $attachType{ $type };

        if( -e "$scriptDir/$web/$topic$type" ) {
            $newTopic->{ changed } = $changed if $type eq '.txt';
    
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
