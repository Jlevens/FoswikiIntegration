package Setup;
use parent 'Import::Base';

# ---+ Foswiki Continuous Integration Contrib
#
# This project at the outset is expected to exist independently of a Foswiki installation. It's designed to help with automated building of the Foswiki core and all active Extensions.
#
# This extends to being able to create a new Foswiki site from scratch on a *new* Server, VM or Container. The emphasis on *new* is that by starting on a new base machine and OS it will significantly simplify the process.
#
# Current development will not give serious consideration to being able to upgrade an installation in place. Nonetheless, future developments *may* allow for significant upgrades (more than FW code). This 'future development' is of course dependent on someone taking up this baton and running with it.

# Feature :5.14, because:
#    1 Exception handling fixes., therefore
#       * I'm using eval { ... } if( $@ ) { ... } it's now safe
#       * no Try::Tiny (blocks are subs so control flow issues)
#       * no TryCatch; blocks work but lots of dependencies as do other similar modules
#    1 For "say" as a bonus
#    1 Better unicode

our @IMPORT_MODULES = (
    'strict',
    'warnings',
    'feature' => [ qw( :5.14 ) ], # I like to 'say' things
    'Setup2',
);

1;