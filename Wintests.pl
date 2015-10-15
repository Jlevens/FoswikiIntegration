
use File::FindLib 'lib';
use Setup;

my %h = ( a => 1, b => 2, c => 'D' );
use Win32::Links opt_in => \%h => opt_out => 'STD' => C => Banana => 'apple';

symlink( "work", "W32a" );

link( "README.md", "W32l" );
link( "work", "W32w" );
symlink( "README.md", "W32s" );

#say $is_l;

say (readlink( $_ ) // '**') for (qw( W32a W32l W32s ));
for my $f (qw( W32a W32l W32s )) {
    say "$f " . (is_l($f) ? 'is' : 'not') . " a symlink";
}
link( "work", "W32w" );


exit 0;