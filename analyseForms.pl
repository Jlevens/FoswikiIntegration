#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib 'lib';
use Setup;
use SimpleMeta;
use ReadData;
use Rules;

use Path::Tiny;
use Scalar::Util qw(reftype);

my %items;

for my $web ( sort keys %extWebRule ) {
    chdir("$scriptDir/$web");
    my @Items = path(".")->children( $isExtensionFile );
    
    for my $item (@Items) {
        my $text = path("$item")->slurp_raw;
        my $meta = simpleMeta($text);
        my %field = 
            map { $_->{name} => $_->{value} }
            grep { $_->{value} }
            @{ $meta->{FIELD} }
            ;

        my $topName = substr($item, 0, -4);
        say $topName;
        my %attachment  = ( reftype ( $meta->{FILEATTACHMENT} ) // '' ) eq 'ARRAY' && 0 < @{ $meta->{FILEATTACHMENT} }
                        ?  map { my $n = $_->{name}; $n =~ s/^$topName//; $n => ( defined $_->{size} ? $_->{size} : -1 ) }
                           grep { %{$_} && $_->{name} =~ m/^$topName(\.sha1|\.md5|\.zip|\.tgz|_installer)$/ } # Some hashes are inexplicably empty
                           @{ $meta->{FILEATTACHMENT} }
                        :  ();

        my $form = $meta->{FORM}[0]{name} || '';
#        next unless &{ $extWebRule{ $web }->{ formOK } }( $form );
        
        my $parent = $meta->{TOPICPARENT}[0]{name} || '';
        
        $meta->{_text} =~ s/%INCLUDE\{([^\}]*?)\}%//;
        my $incl = $1 // '';

        # We want indication of substantive text and its size
        # So, remove standard bits of noise
        $meta->{_text} =~ s/%COMMENT%//g;
        $meta->{_text} =~ s/StandardReleaseComponent//g;
        $meta->{_text} =~ s/^-- Main\.[A-Za-z]+ - [^\n]*(\n|\z)/\n/msg;
        $meta->{_text} =~ s/\h+/ /g;
        $meta->{_text} = "\n$meta->{_text}\n"; # Improve formatting to make Dump easier to read
        $meta->{_text} =~ s/\v+/\n/g; # But remove doubled new lines
        $meta->{_text} = '' if $meta->{_text} =~ m/\A\s*\z/;

        my $ext = substr($item, 0, -4);
        
        my $textLen = length( $meta->{_text} );
        $items{ $ext }{ $web }{ topic }{ filteredTextsize } = $textLen;
        $items{ $ext }{ $web }{ topic }{ text } = $meta->{_text} if $textLen > 0 && $textLen <= $extWebRule{ $web }{ maxText };

        $items{ $ext }{ $web }{ topic }{ parent } = $parent; # if $parent;
        $items{ $ext }{ $web }{ topic }{ form } = $form; # if $form;
        $items{ $ext }{ $web }{ topic }{ include } = $incl; # if $incl;
        $items{ $ext }{ $web }{ topic }{ attachment_meta } = \%attachment if %attachment;
        $items{ $ext }{ $web }{ topic }{ fields } = \%field if %field;


#        for (keys %{ $items{ $ext }{ $web }{ topic } } ) {
#            next if $items{ $ext }{ $web }{ topic }{ $_ };
#            delete $items{ $ext }{ $web }{ topic }{ $_ };
#        };
    }        
}    

dumpData( \%items, "$scriptDir/work/Forms.json" );

exit 0;
