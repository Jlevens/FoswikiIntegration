
package CRO {
    sub new { return bless { {}, 'CRO' }; }
    sub this { print "This on $_[0]\n"; }
    sub that { print "That on $_[0]\n"; }
}

package LazyClass {
    # use $parent; or similar
    @ISA = ( 'CRO' ); # use parent CRO;
    sub new { return bless { {}, 'CRO' }; }
    sub this { print "This on $_[0]\n"; }
    sub that { print "That on $_[0]\n"; }
}

my $api = undef;

my $o = sub {
    return $api if defined $api;
    $api = CRO->new();
    return $api;
};



print ref $o, "\n";

my $a = CRO->new();

$a->this;
$a->that;

# my $o = ref $oLazy eq 'CODE' ? $oLazy->() : $oLazy;

#  my $api = $store->awake->readTopic( ... );

$o->()->this;
$o->()->that;
$o->()->this;
$o->()->that;

