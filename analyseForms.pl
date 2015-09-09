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
use Path::Tiny;
use Sort::Naturally;
use POSIX 'strftime';
use ReadData;
use Scalar::Util qw(reftype);

use readData;

my %webs = (
    Tasks => { formOK => sub { return 1; }, maxText => 500 },
    Support => { formOK => sub { return 1; }, maxText => 500 },
    Development => { formOK => sub { return $_[0] eq 'BasicForm' || $_[0] eq ''; }, maxText => 500 },
    Extensions => { formOK => sub { return 1; }, maxText => 500 },
    'Extensions/Testing' => { formOK => sub { return 1; }, maxText => 500 },
    'Extensions/Archived' => { formOK => sub { return 1; }, maxText => 500 },
);

my %items;

for my $web ( keys %webs ) {
    chdir("$scriptDir/$web");
    my @Items = nsort ( path(".")->children( qr/(Contrib|Plugin|AddOn|Skin)\.txt\z/ ) );
    
    for my $item (@Items) {
        my $text = path("$item")->slurp_raw;
        my $meta = simpleMeta($text);
        my %field = 
            map { $_->{name} => $_->{value} }
            grep { $_->{value} }
            @{ $meta->{FIELD} }
            ;

        my %attachment  = ( reftype ( $meta->{FILEATTACHMENT} ) // '' ) eq 'ARRAY' && 0 < @{ $meta->{FILEATTACHMENT} }
                        ?  map { $_->{name} => ( defined $_->{size} ? $_->{size} : -1 ) }
                           grep { %{$_} } # Some hashes are inexplicably empty
                           @{ $meta->{FILEATTACHMENT} }
                        :  ();

        my $form = $meta->{FORM}[0]{name} || '';
        next unless &{$webs{ $web }->{formOK}}( $form );
        
        my $parent = $meta->{TOPICPARENT}[0]{name} || '';
        
        $meta->{_text} =~ s/%INCLUDE\{([^\}]*?)\}%//;
        my $incl = $1;

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
        $items{ $ext }{ $web }{ topic } = {
            form => $form, include => $incl, parent => $parent, size => length( $meta->{_text} )
        };
        
        $items{ $ext }{ $web }{ topic }{ text } = $meta->{_text} if length($meta->{_text}) <= $webs{ $web }{ maxText };
        $items{ $ext }{ $web }{ topic }{ attachments } = \%attachment if %attachment;
        $items{ $ext }{ $web }{ topic }{ fields } = \%field if %field;
        for (keys %{ $items{ $ext }{ $web }{ topic } } ) {
            next if $items{ $ext }{ $web }{ topic }{ $_ };
            delete $items{ $ext }{ $web }{ topic }{ $_ };
        };
    }        
}    

dumpData( \%items, "$scriptDir/work/ExtensionForms.json" );

exit 0;
