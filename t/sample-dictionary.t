use Test::More;

BEGIN { use_ok 'Diameter::Dictionary' };

my $file = (-f './etc/dictionary.yaml' ? './etc/dictionary.yaml' : (-f '../etc/dictionary.yaml' ? '../etc/dictionary.yaml' : undef));

if (!defined $file) {
    BAIL_OUT( "Cannot find sample dictionary file" );
}

my $d = Diameter::Dictionary->from_yaml( FromFile => $file );

ok( defined $d && ref $d, 'Sample dictionary properly resolves' );

done_testing();
