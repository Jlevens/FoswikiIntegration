package SimpleMeta;
BEGIN {
    require Exporter;
    our $VERSION     = 0.001;
    our @ISA         = qw(Exporter);
    our @EXPORT      = qw(put putKeyed simpleMeta);
}

sub put {
    my ( $this, $type, $args ) = @_;

    unless ( $this->{$type} ) {
        $this->{$type} = [];
        $this->{_indices}->{$type} = {};
    }

    my $data = $this->{$type};
    my $i    = 0;
    if ($data) {

        # overwrite old single value
        if ( scalar(@$data) && defined $data->[0]->{name} ) {
            delete $this->{_indices}->{$type}->{ $data->[0]->{name} };
        }
        $data->[0] = $args;
    }
    else {
        $i = push( @$data, $args ) - 1;
    }
    if ( defined $args->{name} ) {
        $this->{_indices}->{$type} ||= {};
        $this->{_indices}->{$type}->{ $args->{name} } = $i;
    }
}

# Note: Array is used instead of a hash to preserve sequence
sub putKeyed {
    my ( $this, $type, $args ) = @_;

    my $keyName = $args->{name};

    unless ( $this->{$type} ) {
        $this->{$type} = [];
        $this->{_indices}->{$type} = {};
    }

    my $data = $this->{$type};

    # The \% shouldn't be necessary, but it is
    my $indices = \%{ $this->{_indices}->{$type} };
    if ( defined $indices->{$keyName} ) {
        $data->[ $indices->{$keyName} ] = $args;
    }
    else {
        $indices->{$keyName} = push( @$data, $args ) - 1;
    }
}

sub dataDecode {
    my $datum = shift;

    $datum =~ s/%([\da-f]{2})/chr(hex($1))/gei;
    return $datum;
}

# STATIC Build a hash by parsing name=value space separated pairs
sub _readKeyValues {
    my ($args) = @_;
    my %res;

    # Format of data is name='value' name1='value1' [...]
    $args =~ s/\s*([^=]+)="([^"]*)"/
      $res{$1} = dataDecode( $2 ), ''/ge;

    return \%res;
}

sub _readMETA {
    my ( $meta, $expr, $type, $args ) = @_;

    my $keys = _readKeyValues($args);

    if ( defined( $keys->{name} ) ) {
        putKeyed( $meta, $type, $keys );
    }
    else {
        put( $meta, $type, $keys);
    }
    return '';
}

sub simpleMeta {
    my ($text) = @_;
    my $meta = {};
    $text =~ s/^(%META:([^{]+){([^\n]*)}%(?:\n|\z))/_readMETA($meta, $1, $2, $3)/gems;
    # $meta now good to go; $text now %META...% free
    $meta->{_text} = $text;
    return $meta;
}

1;
