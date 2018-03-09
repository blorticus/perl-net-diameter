use Test::More tests => 27;

my $dwr_msg_hex = "010000408000011800000000a81826d5e77f7c8f0000010840000016706365662e66356e65742e636f6d0000000001284000001166356e65742e636f6d000000";

my $dwa_msg_hex = "010000480000011800000000a81826d5e77f7c8f0000010c4000000c000007d10000012840000013747261666669782e636f6d00000001084000001366355f6469616d6574657200";


BEGIN { use_ok( 'Diameter::Message' ) }

my $dwr;
eval { $dwr = Diameter::Message->decode( pack "H*", $dwr_msg_hex ) };

cmp_ok( $@, 'eq', '', 'Diameter::Message->decode for dwr message exception check' );
isa_ok( $dwr, 'Diameter::Message', "Diameter::Message->decode for dwr produces Diameter::Message object" );

if (!$@ && defined $dwr) {
    dwr_decode_tests( $dwr );
    cmp_ok( unpack( "H*", $dwr->encode ), 'eq', $dwr_msg_hex, 'Diameter::Message->encode for dwr comparison to message hex' );
}


my $dwa;
eval { $dwa = Diameter::Message->decode( pack "H*", $dwa_msg_hex ) };

cmp_ok( $@, 'eq', '', 'Diameter::Message->decode for dwr message exception check' );
isa_ok( $dwr, 'Diameter::Message', "Diameter::Message->decode for dwa produces Diameter::Message object" );

if (!$@ && defined $dwa) {
    dwa_tests( $dwa );
}


sub dwr_decode_tests {
    my $dwr = shift;

    cmp_ok( $dwr->version,       '==', 1,           '$dwr->version check' );
    cmp_ok( $dwr->msg_length,    '==', 64,          '$dwr->msg_length check' );
    cmp_ok( $dwr->flags,         '==', 0x8,         '$dwr->flags check' );
    cmp_ok( $dwr->app_id,        '==', 0,           '$dwr->app_id check' );
    cmp_ok( $dwr->hop_by_hop_id, '==', 0xa81826d5,  '$dwr->hop_by_hop_id check' );
    cmp_ok( $dwr->end_to_end_id, '==', 0xe77f7c8f,  '$dwr->end_to_end_id check' );
    ok( $dwr->is_request, '$dwr->is_request check' );

    my @avps = $dwr->avps;

    cmp_ok( scalar @avps, '==', 2, '$dwr->avps number check' );

    ok( avp_check( $avps[0], 264, 2, 22, 0, undef, join( '', unpack( "H*", pack( "A*", "pcef.f5net.com" ) ) ) ),
            'DWR AVP check for AVP number 1' );

    ok( avp_check( $avps[1], 296, 2, 17, 0, undef, join( '', unpack( "H*", pack( "A*", "f5net.com" ) ) ) ),
            'DWR AVP check for AVP number 2' );
}


sub dwa_tests {
    my $dwa = shift;

    cmp_ok( $dwa->version,       '==', 1,           '$dwa->version check' );
    cmp_ok( $dwa->msg_length,    '==', 72,          '$dwa->msg_length check' );
    cmp_ok( $dwa->flags,         '==', 0,           '$dwa->flags check' );
    cmp_ok( $dwa->app_id,        '==', 0,           '$dwa->app_id check' );
    cmp_ok( $dwa->hop_by_hop_id, '==', 0xa81826d5,  '$dwa->hop_by_hop_id check' );
    cmp_ok( $dwa->end_to_end_id, '==', 0xe77f7c8f,  '$dwa->end_to_end_id check' );
    ok( ! $dwa->is_request, '$dwa->is_request check' );

    my @avps = $dwa->avps;

    cmp_ok( scalar @avps, '==', 3, '$dwa->avps number check' );

    ok( avp_check( $avps[0], 268, 2, 12, 0, undef, sprintf( "%08x", 2001 ) ),
            'CEA AVP check for AVP number 1' );

    ok( avp_check( $avps[1], 296, 2, 19, 0, undef, join( '', unpack( "H*", pack( "A*", "traffix.com" ) ) ) ),
            'CEA AVP check for AVP number 2' );

    ok( avp_check( $avps[2], 264, 2, 19, 0, undef, join( '', unpack( "H*", pack( "A*", "f5_diameter" ) ) ) ),
            'DWR AVP check for AVP number 3' );
}


sub avp_check {
    my ($avp, $code, $flags, $length, $has_vendor_id, $vendor_id, $data_as_hex) = @_;

    my $data_check = 0;
    my $avp_data = $avp->raw_data;

    if (ref $avp->raw_data) {
        if (ref $data_as_hex) {
            if (@{ $avp->raw_data } == @{ $data_as_hex }) {
                my $matches = 0;
                for (my $i = 0; $i < @{ $data_as_hex }; $i++) {
                    $matches++  if avp_check( $avp->raw_data->[$i], @{ $data_as_hex->[$i] } );
                }
                $data_check = $matches == @{ $data_as_hex };
            }
        }
    }
    else {
        if (!ref $data_as_hex) {
            $data_check = unpack( "H*", $avp->raw_data ) eq $data_as_hex;
        }
    }

    return $avp->code == $code && $avp->flags == $flags && $avp->length == $length &&
           ($avp->has_vendor_id ? $has_vendor_id : !$has_vendor_id) &&
           ($avp->has_vendor_id ? $avp->vendor_id == $vendor_id : 1) &&
           $data_check;
}
