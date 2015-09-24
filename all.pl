#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib 'lib';
use Setup;

chdir( $scriptDir );

# syncronise all git repos (even the dead ones!)

`perl syncAll.pl`;


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

`perl getTopics.pl`;



# Scan Extension topics for Forms
#    PackageForm in real extensions
#    Other forms for consistency checks
#
# Creates work/Forms.json

`perl analyseForms.pl`;



# Scan Extension topics for Forms
#    PackageForm in real extensions
#    Other forms for consistency checks
#
# Creates work/Forms.json

`perl analyseForms.pl`;

`perl analyseItems.pl`;

`perl analyseDigests.pl`;

`perl analyseInstallers.pl`;

`perl mergeJson.pl`;

`perl showSummary.pl`;

`perl analyseAll.pl`;

exit 0;



