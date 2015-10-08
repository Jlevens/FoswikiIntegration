package Setup2;
BEGIN {
    require Exporter;
    our $VERSION     = 0.001;
    our @ISA         = qw(Exporter);
    our @EXPORT      = qw($scriptDir $secrets);
    }

use English qw( -no_match_vars ) ;

#if( $OSNAME eq 'MSWin32' ) {
#    die <<"HERE";
#Not recommended for running under Windows!
#Too many issues regarding case insensitive file names to be certain everything works well - subtle problems lurk.
#Also, CRLF issues may could some of the calculations of Digests between live and freshly built artifacts.
#
#
#HERE
#}

use Cwd qw(abs_path);
use File::Basename;
our $scriptDir = dirname abs_path(__FILE__ . '/..');

use JSON;
use Path::Tiny;
our $secrets = JSON::from_json( path("$scriptDir/Secrets.json")->slurp_raw );

1;
