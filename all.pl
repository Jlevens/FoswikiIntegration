#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib 'lib';
use Setup;

use Path::Tiny;

chdir( $scriptDir );

# syncronise all git repos (even the dead ones!)

do_it( 'syncAll' ); #-->> Repo.json



# syncronized fetch of topics and attachments from following webs that match /(Contrib|Plugin|AddOn|Skin)\z/
#    1 Extensions
#    2 Extensions/Archived
#    3 Extensions/Testing
#    4 Development
#    5 Support
#    6 Tasks
#
# For Support web also retrieve topics that match /^Question\d+?\z/
# For Tasks   web also retrieve topics that match /^Item\d+?\z/
#
# Attachments tgz zip sha1 md5 and _installer are only retreieved for the Extensions webs
#
# see lib/Rules.pm for exact specification
#
# Creates work/Topics.json which list the details from Extension/JsonTopicList from f.o
# Therefore this list are the Extensions that customers of the project have available to
# download. This list can be used by later scripts to identify these live Extensions in
# reports

do_it( 'getTopics' ); #-->> Topics.json



# Scan *Extension* topic and canonicalise then analyse especially Forms but _text, attachments and all other meta
#    PackageForm in real extensions
#    Other forms for consistency checks
#
# Creates work/Forms.json

do_it( 'analyseForms' ); #-->> Forms.json



# Analyse ItemNNNN     topics from Tasks web and
#         QuestionNNNN topics from Support web
#
# Cross references back to the Extension it refers to listing all
# states that are primarily "open" or "closed" the specific states within those and recording for each state
# the last modified date of that task (allows counting how many are open/closed and assessing if tasks are being dealt with)

do_it( 'analyseItems' ); #-->> Items.json



# Analyse the digests (md5 and sha1) comparing and contrasting to find differences in .tgz .zip and _installer files

do_it( 'analyseDigests' ); #-->> Digests.json



# Analyse the installer scripts for inconsistencies and fix up to latest standards

do_it( 'analyseInstallers' ); #-->> Installers.json



# Combine the above json outputs into one
#
# 1st key  is the extension name
# 2nd key are the web name(s) it is found in
# nth key  various depending on web

# Therefore, futures scripts can loop thru all extensions one by one and cross check all data

# Crucially the primary key will exist for any reference to something that looks like any extension
# either in git or f.o candidate webs

do_it( 'mergeJson' ); #-->>Merged.json



# Simple summary of each extension - needs work though

do_it( 'showSummary' );



do_it( 'analyseAll' );



exit 0;

sub do_it {
    my ($it) = @_;
    
    my $op = `perl $it.pl`;
    if( $op ) {
        say $op;
        path("work/$it.txt")->spew_raw( $op );
    }
}
