package Rules;

BEGIN {
    require Exporter;
    our $VERSION     = 0.001;
    our @ISA         = qw(Exporter);
    our @EXPORT      = qw(%extWebRule %attachType $isExtension $isExtensionFile escape);
    }

use Setup;

sub escape {
    my ($str, %ref) = @_;
    
    for my $k (keys %ref) {
        my $v = $ref{$k};
        $str =~ s/\$$k/$v/eg;
    }
    return $str;
}

our $isExtension = qr/(Contrib|Plugin|AddOn|Skin)\z/;
our $isExtensionFile = qr/(Contrib|Plugin|AddOn|Skin)\.txt\z/;

our %extWebRule = (
    Extensions           => {
        topicMatch => $isExtension,
        fetchAttachType => [ qw( .txt .sha1 .md5 .zip .tgz _installer ) ] ,
        formOK => sub { return 1; },
        maxText => 500,
    },
    'Extensions/Testing'  => {
        topicMatch => $isExtension,
        fetchAttachType => [ qw( .txt .sha1 .md5 .zip .tgz _installer ) ],
        formOK => sub { return 1; },
        maxText => 500,
    },
    'Extensions/Archived' => {
        topicMatch => $isExtension,
        fetchAttachType => [ qw( .txt .sha1 .md5 .zip .tgz _installer ) ] ,
        formOK => sub { return 1; },
        maxText => 500,
    },
   
    Development          => {
        topicMatch => $isExtension,
        fetchAttachType => [ qw( .txt ) ] ,
        formOK => sub { return $_[0] eq 'BasicForm' || $_[0] eq ''; },
        maxText => 500,
    },
    Tasks => {
        topicMatch      => qr/^Item\d+?\z|$isExtension/,
        fetchAttachType => [ qw( .txt ) ],
        formOK          => sub { return 1; },
        maxText         => 500,
        
        dataThings  => qr/\AItem\d+\.txt\z/,
        sfield      => 'CurrentState',
        closed      => qr/Closed|No Action Required|Duplicate/,
        cfield      => 'Component',
        type        => 'Item',
    },
    Support => {
        topicMatch      => qr/^Question\d+?\z|$isExtension/,
        fetchAttachType => [ qw( .txt ) ],
        formOK          => sub { return 1; },
        maxText         => 500,

        dataThings  => qr/\AQuestion\d+\.txt\z/,
        sfield      => 'Status',
        closed      => qr/Answered|Closed unanswered|Task filed|Task closed|Marked for deletion/,
        cfield      => 'Extension',
        type        => 'Question',
    },
);

our %attachType = (
    _installer => {
        request     => 'get',
        requestURL  => 'pub/$web/$topic/$topic_installer', # $web & $topic are $placeholders escaped later
        digestable  => 1,
    },
    '.txt'    => {
        request     => 'post',
        requestURL  => '$web/$topic',
        requestParms=> {
            skin        => 'text',
            raw         => 'debug',
            username    => $secrets->{'foswiki.org'}{login},
            password    => $secrets->{'foswiki.org'}{pass},
        },
    },
    '.sha1'   => {
        request     => 'get',
        requestURL  => 'pub/$web/$topic/$topic.sha1',
        digest      => 'SHA1',
    },
    '.md5'    => {
        request     => 'get',
        requestURL  => 'pub/$web/$topic/$topic.md5',
        digest      => 'MD5',
    },
    '.zip'    => {
        request     => 'get',
        requestURL  => 'pub/$web/$topic/$topic.zip',
        digestable  => 1,
    },
    '.tgz'    => {
        request     => 'get',
        requestURL  => 'pub/$web/$topic/$topic.tgz',
        digestable  => 1,
    },
);
