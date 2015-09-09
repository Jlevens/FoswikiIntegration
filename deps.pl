#! /usr/bin/env perl
#
# FoswikiContinuousIntegrationContrib
# Julian Levens
# Copyright (C) 2015 ProjectContributors. All rights reserved.
# ProjectContributors are listed in the AUTHORS file in the root of
# the distribution.

use File::FindLib 'lib';
use Setup;

use MetaCPAN::Client;
use Path::Tiny;
use Module::CoreList;

chdir($scriptDir);

my $dinfo = path('repos')->visit( \&checkNode, { recurse => 1 } );
$Data::Dumper::Indent = 1;
#print Data::Dumper->Dump( [ \$dinfo ], [ 'DEPENDENCIES' ] );

my @types = sort keys %{$dinfo->{deps}};
my @changes;
for my $type (@types) {
    my @dnames = sort keys %{$dinfo->{deps}{$type}};
    for my $dname (@dnames) {
        my @exts = sort keys %{$dinfo->{deps}{$type}{$dname}};
        my ($ptype, $pdname) = ($type, $dname); # For cleaner report style output but loses info if you select further on that report
        for my $ext (@exts) {
            my ($otype, $odname) = @{$dinfo->{deps}{$type}{$dname}{$ext}};

            my $change = ($type ne $otype ? 'T' : ' ') . ($dname ne $odname ? 'N' : ' ');
            my $info = sprintf "%-33s %-s", $ext, join(' | ', $otype, $odname ); # @{$dinfo->{deps}{$type}{$dname}{$ext}} );
                            
            push @changes,
                sprintf "$change %-9s %-43s $info",  $type, $dname  if $change ne '  ';
            printf     ("$change %-9s %-43s $info\n", $ptype, $pdname);
            ($ptype, $pdname) = ('', '');
        }
        print "\n";
    }
}
$" = "\n";
print "\n\nDEPENDENCIES in need of amendment\n\n@changes\n";

exit 0;

sub checkNode {
    my ( $node, $data ) = @_;

    my @dirs = File::Spec->splitdir( $node->stringify );
    my $depth = (scalar @dirs) - 1;
    my $leaf  = $dirs[$depth];
    my $ext = $dirs[ $depth - 1 ];

    my $mcpan  = MetaCPAN::Client->new();

    my %types = (
        external => 'external',
        cpan => 'cpan',
        perl => 'perl',
        plugin => 'perl',
        c => 'external',
        program => 'external',
        unknown => 'unknown',
    );

    if( -f $node && $leaf eq 'DEPENDENCIES' ) {
        my @deps = -e $node ? $node->lines( { chomp => 1 } ) : ();
        my $only = '';
        for my $dep (@deps) {
            next unless $dep;
            next if substr($dep,0,1) eq '#';
            chomp($dep);
            if( $dep =~ m/^ONLYIF/ ) {
                $only = $dep;
                next;
            }
            #print "<<$dep>>\n";
            my ($odname, $select, $otype, $desc) = split(',', $dep);

            $otype  = 'unknown' if !$otype;
            $otype =~ s/\s//g;
            $otype = lc($otype);
            my $type = $otype;
            $type = $types{$type};     
           
            my $dname = $odname;

            $dname = 'unknown' if !$dname;
            $select = 'unknown' if !$select;
            $type  = 'unknown' if !$type;
            $desc  = 'No-desc' if !$desc;

            my ($cf, $cff);
            eval {
                $cf = $mcpan->module($dname, { fields => "distribution,version" } );
            };
            if( !$@ ) { # Found in cpan, so it's a CPAN module and the name is already good
                $type = 'cpan'; # Or at least a module has been found on CPAN = $dname
                $cff = sprintf("%-30s %-10s", $cf->{data}{distribution}, $cf->{data}{version} );
            }
            else { # Not found in cpan, so is it perl and is the name good?
                $cff = '';

                if( $dname !~ m/::/ ) {
                   if(    $dname =~ m/Contrib$/ ) { $dname = "Foswiki::Contrib::$dname"; }
                   elsif( $dname =~ m/Plugin$/ ) { $dname = "Foswiki::Plugins::$dname"; }
                }

                $type = 'perl' if $dname =~ m/^(Foswiki::|TWiki::)/;                            
            }            

            if( $dname =~ m/(ImageMagick|wvHTML)/ ) {
                $type = 'external';
            }
            
            $data->{deps}{$type}{$dname}{$ext} = [ $otype, $odname, $select, $only, $desc, $cff, (Module::CoreList::is_core($dname) ? 'CoreList' : '') ];
        }
    }
}
