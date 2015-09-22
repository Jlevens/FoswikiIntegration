package ReadData;
BEGIN {
    require Exporter;
    our $VERSION     = 0.001;
    our @ISA         = qw(Exporter);
    our @EXPORT      = qw(readData backupData dumpData);
}

sub readData {
    my ($file, $var) = @_;

    return {} if !-e $file;
    
    if( $file =~ m/\.json$/) {
        use JSON;
        use Path::Tiny;
        
        my $json = JSON->new->pretty;
        return $json->decode( path($file)->slurp_raw );
    } 

    $var ||= 'data';

    no strict 'vars'; # Allow var-name in Dumped data file to be created (lacks 'my')
    
    unless (my $return = do $file) {
        warn "couldn't parse $file: $@" if $@;
        warn "couldn't do $file: $!"    unless defined $return;
        warn "couldn't run $file"       unless $return;
    }

    no strict 'refs';
    return $$var;
}

#my $oldData = path("scriptDir/work/ExtensionsTopics.dat")->slurp_raw;
#@paths = path("/tmp")->children( qr/\.txt$/ );


sub backupData {
    use Path::Tiny;
    
    my ($file) = @_;
    return '' unless -e $file; # Nothing to backup if file does not already exist

    my $base = path($file)->basename;
    my $parent = path($file)->parent;
    my @paths = $parent->children( qr/^$base\.\d+\.bak$/ );
    my @nums = reverse sort map { my ($num) = $_->basename =~ /^$base\.(\d+)\.bak$/; $num+=0; } @paths;
    my $num = @nums ? $nums[0]+1 : 1;

    use File::Copy;

    my $backup = "$parent/$base\.$num\.bak";
    copy( $file, $backup );
    return $backup;
}

sub dumpData {
    my ($ref, $file, $backup) = @_;
    
    backupData($file) if ($backup // 1);

    open(my $fh, '>', "$file") or die "Failed to open $file\n";
    my $json = JSON->new->pretty->canonical;
    print $fh $json->encode( $ref );
    close($fh);
}
1;
