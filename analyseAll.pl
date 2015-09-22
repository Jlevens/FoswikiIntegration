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
use Rules;

my $topic = readData( "$scriptDir/work/Merged.json" );

my $PackageForm = <<'HERE';
| Author | text | 60 | | |
| Version | text | 60 | | Numerical version number e.g. 1.2 |
| Release | text | 60 | | Release identifier (usually the date) |
| Copyright | text | 60 | | e.g. 2015, The Artist, All Rights Reserved |
| License | text | 60 | | e.g GPL ([[http://www.gnu.org/copyleft/gpl.html][GNU General Public License]]) |
| Home | text | 60 | | e.g. http://foswiki.org/Extensions/%TOPIC% |
| Support | text | 60 | | e.g. http://foswiki.org/Support/%TOPIC% |
| Repository | text | 60 | | URL of source control repository e.g. https://github.com/foswiki/ExtensionName |
| ExtensionClassification | select+multi | 9 |  | Classify the package |
| ExtensionType | select | 1 | PluginPackage, SkinPackage, ContribPackage, WikiApplicationPackage | Classify the type of package |
| Compatibility | text | 60 | | Compatibility notes |
| IncompatibleWith | checkbox | 5 | | Foswiki versions the extension has been tested on *and found not to work* |
| ImageUrl | text | 60 |  | A URL where the image for this package resides. |
| DemoUrl | text | 60 | http:// | A URL where this package can be seen in action |
| SupportUrl | text | 60 | Support.%BASETOPIC% | A URL where users can get support, and talk to other users of the extension |
| ModificationPolicy | radio | 3 | PleaseFeelFreeToModify, CoordinateWithAuthor, FollowsReleaseProcess | What does the author wants you to do before making modifications to this package. !FollowsReleaseprocess is only used for the set of default extensions that ship with Foswiki. |
| NewsFlash | text | 80 | | |
HERE

my @pflines = split(/\n/, $PackageForm );
my %pForm;
for my $lin ( @pflines ) {
    my @parts = map { s/^\s*?//g; s/\s*?$//g; $_; } split(/\|/, $lin);
    $pForm{ $parts[1] } = [ @parts[2..5] ];
}


my %analysis;

for my $extName ( sort keys %{ $topic } ) {

    next if $extName !~ $isExtension;
    
    if( $topic->{ $extName }{ Extensions }{ isodate }
            && ($topic->{ $extName }{ Extensions }{ topic }{ form } // '') eq 'PackageForm' 
            && $topic->{ $extName }{ Extensions }{ install }    )   {
        analyseLiveExtension( $extName, $topic->{ $extName } );
    }
}
#    my ($tglob, $sfield, $closed, $cfield, $type) = @{$at}{ qw(dataThings sfield closed cfield type) };

for my $name ( sort keys %analysis ) {

    my $ae = $analysis{$name}{errors};
    next unless $ae;
    
    my @errors = 
        sort { $a->{major} cmp $b->{major} || ($a->{minor}//'') cmp ($b->{minor}//'') || $b->{err} <=> $a->{err} }
#        grep { $_->{err} != 333 } 
        @{$ae};
    
    my $pname = $name;
    say "" if @errors;
    for my $e (@errors) {

        my ($err, $major, $minor, $patch, $desc) = @{$e}{ qw(err major minor patch desc) };

        printf "| %-40s | %6d | %-20s | %-24s | %-15s | %-100s |\n", $pname, $err, $major, $minor // '', $patch // '', $desc;
        $pname = '';
    }
}

exit 0;


sub analyseLiveExtension {
    my ( $name, $ext ) = @_;
    
    my $ae = $analysis{$name}{errors} //= [];
    
    push @{$ae}, { err=>100, major=>'Support Hub', desc=>'Missing'} unless $ext->{ Support }{ isodate };
    push @{$ae}, { err=>100, major=>'Tasks Hub', desc=>'Missing' } unless $ext->{ Tasks }{ isodate };
    push @{$ae}, { err=>400, major=>'GitHub', desc=>'Missing' } unless $ext->{ pushed_at };
    push @{$ae}, { err=>  1, major=>'Extensions/Testing', desc=>'Found'} if $ext->{ 'Extensions/Testing' }{ isodate };
    push @{$ae}, { err=>400, major=>'Extensions/Archived', desc=>'Found' } if $ext->{ 'Extensions/Archived' }{ isodate };
    
    for my $digestable ( keys %{ $ext->{ Extensions }{ Digest } } ) {
        my @mm = ( major=>'Digest' );
        for my $digest ( keys %{ $ext->{ Extensions }{ Digest }{ $digestable } } ) {
        
            my $test = $ext->{ Extensions }{ Digest }{ $digestable }{ $digest }{ Test };
            next if $test eq 'M';
        
               if( $test eq 'B' ) { push @{$ae}, { @mm, err=>100, desc=>"$digest for $digestable: no attachment & no digest filed" }; }
            elsif( $test eq 'C' ) { push @{$ae}, { @mm, err=>100, desc=>"$digest for $digestable: no attachment to check" }; }
            elsif( $test eq 'S' ) { push @{$ae}, { @mm, err=>100, desc=>"$digest for $digestable: no digest filed" }; }
            elsif( $test eq 'X' ) { push @{$ae}, { @mm, err=>400, desc=>"$digest for $digestable: digests mismatch" }; }
        }
    }       
    
    my $install = $ext->{ Extensions }{ install };
    my @mm = ( major=>'Installer', minor=>'OC' );
    push @{$ae}, { @mm, err=> 5, patch=>'shebang',  desc=>"'$install->{shebang}' not expected '#! /usr/bin/env perl'" }  if $install->{ shebang };
    push @{$ae}, { @mm, err=>20, patch=>'Date',     desc=>"'$install->{OC}{Date}' not expected '2004-2015 Foswiki '" }   if $install->{ OC }{Date};
    push @{$ae}, { @mm, err=>50, patch=>'name',     desc=>"'$install->{OC}{name}' not expected 'Foswiki'" }              if $install->{ OC }{name};
    push @{$ae}, { @mm, err=> 5, patch=>'link',     desc=>"'$install->{OC}{link}' not expected 'http://c-dot.co.uk'" }   if $install->{ OC }{link};
    push @{$ae}, { @mm, err=> 5, patch=>'Fragment', desc=>"'$install->{OC}{Fragment}' not expected 'OC-STD-75f65ab..'" } if $install->{ OC }{Fragment};
    

    if( $install->{ EM } ) {
        my @mm = ( major=>'Installer', minor=>'EM' );
        if( $install->{EM}{notFound} ) {
            push @{$ae}, { @mm, err=>500, desc=>"Not-found! How can this install?" };
        }
        elsif( my $frag = $install->{ EM }{Fragment} ) {
        
            my @mmp = ( @mm, patch=>'Fragment' );

            if(    $frag eq 'EM-XXX-3aaadcca48f165fb3f461c9f0d49831f.txt' ) {
                push @{$ae}, { @mmp, err=>100, desc=>"#1 Older version with TWiki refs, similar to #2" };
            }
            elsif( $frag eq 'EM-XXX-7b170f6b4033b4d2d19c062516ddc4a6.txt' ) {
                push @{$ae}, { @mmp, err=>100, desc=>"#2 Older version with TWiki refs, similar to #2" };
            }
            elsif( $frag eq 'EM-XXX-e3f9b596b66025969ee734bb9e6168a8.txt' ) {
                push @{$ae}, { @mmp, err=>500, desc=>"#3 Very old TWiki version does 'extender.pl' needs replacing" };
            }
            elsif( $frag eq 'EM-XXX-c88853da66ad24bb86bea0dd8818bed9.txt' ) {
                push @{$ae}, { @mmp, err=> 10, desc=>"#4 Almost standard: difference in message only" }
            }
        }
    }

    my $subs = '';
    for my $sub (qw(preinstall postinstall preuninstall postuninstall)) {
        $subs .= "$sub " if $install->{ $sub };
    }
    @mm = ( major=>'Installer' );
    push @{$ae}, { @mm, err=>  0, minor=>'subs',     desc=>$subs }if $subs;

    push @{$ae}, { @mm, err=>100, minor=>'Extender', desc=>"'$install->{Extender}' not expected" } if $install->{Extender};

    push @{$ae}, { @mm, err=>100, minor=>'Package',  desc=>"'$install->{Package}' not expected 'http://foswiki.org/pub/Extensions'" } if $install->{Package};

    if( my $frag = $install->{REM}{Fragmemt} ) {
        my @mm = ( major=>'Installer', minor=>'REM', patch=>'Fragment' );
        if(    $frag eq 'REM-XXX-cc443555efddfeeec11cd396bf31ebea.txt' ) {
            push @{$ae}, { @mm, err=>400, desc=>"#1 Same as STD except TWiki does need replacing" };
        }
        elsif( $frag eq 'REM-XXX-e23986d5fbe3cf0ee2863d00bcbf8a3b.txt' ) {
            push @{$ae}, { @mm, err=>400, desc=>"#2 Old TWiki version needs replacing" };
        }
    }

    for my $type ( qw(_installer .tgz .zip .sha1 .md5) ) {
    
        my $size = $ext->{ Extensions }{ topic }{ attachment_meta }{ $type };
        my $attach = -e "$scriptDir/Extensions/$name$type" ? 'Found  ' : 'Missing';
        my $meta = $size ? 'Found  ' : 'Missing';

        my @mm = ( major=>'Attach' );
        if( $size && $attach eq 'Found  ' ) {
            my $fileSz = (stat("$scriptDir/Extensions/$name$type"))[7];
            push @{$ae}, { @mm, err=>500, desc=>"$type $fileSz: meta $size" } if $size != $fileSz;
        }
        else {
            my $err = { '.tgz' => 500, '.zip' => 300, '_installer' => 500, '.md5' => 200, '.sha1' => 100 }->{ $type };
            push @{$ae}, { @mm, err=>$err, desc=>"$type $attach: meta $meta" };
        }
    }

    # Missing PackageForm details can often be obtained from a table in the Topic text

    # DevelopedInSVN and TopicClassification are redundant and should be removed
    # Strictly ShibLdapContrib and LdapGuiPlugin claim to not use SVN and the former does not exist in GitHub
    # However, it also is FeelFreeToModify and no Author is listed

    # Repository is rarely populated
    # SupportUrl is always Support.ExtensionName unless it's not given or it is Support.%TOPIC%, i.e essentially redundant
    # Support appears to be there for the same need and is never populated
    
    # ExtensionClassification in good use it seems
    # ModificationPolicy also
    
    # ExtensionType reflects the Extension name (i.e. PluginPackage eq *Plugin check any discrepancies), sometimes missing this can be fixed, 

    for my $k ( qw(Author Copyright DemoUrl Home License Release Version SupportUrl ) ) {
        if( !$ext->{Extensions}{topic}{fields}{$k} ) {
            my $table = $ext->{Extensions}{topic}{table}{$k} // [];
            $ext->{Extensions}{topic}{fields}{$k} = join(';', @$table);
        }
    }

    my %allFields = ( %{ $ext->{Extensions}{topic}{fields} // {} }, %pForm );
    for my $field ( sort keys %allFields) {
        my $fstate =  ref $pForm{ $field } eq 'ARRAY' ? 'L' : 'R';
        next unless $fstate eq 'L';

#        next unless $field eq 'ExtensionType';
        my $value = $ext->{Extensions}{topic}{fields}{$field} // '';
        $value =~ s/\n/\\n/g;
        $value =~ s/\r//g;
        push @{$ae}, { major=>'Fields', minor=>$field, err=>333, desc=>$value };
    }
}
