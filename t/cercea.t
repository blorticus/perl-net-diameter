use Test::More tests => 58;

my $cer_msg_hex =
"010000a48000010100000000a81826d1e77f7c8b0000010840000016706365662e66356e65742e636f6d0000000001284000001166356e65742e636f6d000000000001014000000e00010a96960100000000010a4000000c00000d2f0000010d0000000e4249472d49500000000001094000000c000028af000001024000000c0100001600000104400000200000010a4000000c000028af000001024000000c01000016";

my $cea_msg_hex =
"010000ac0000010100000000a81826d1e77f7c8b0000010c4000000c000007d10000012840000013747261666669782e636f6d00000001084000001366355f6469616d65746572000000010a4000000c0000027d000001094000000c000028af000001024000000c0100001600000104400000200000010a4000000c000028af000001024000000c010000160000010d4000000e4249472d49500000000001014000000e00010a9696020000";

#                              |DIAMETER-HEADER                       |OriginHost                                      |OriginRealm                            |HostIPAddress                  |VendorId               |ProductName
my $constructed_cer_msg_hex = "010000708000010100000000000012340000abcd0000010840000017746573742e663564656d6f2e636f6d000000012840000012663564656d6f2e636f6d0000000001014000000e0001c0a8190100000000010a4000000c000015a80000010d40000014746573742d6861726e657373";

BEGIN { use_ok( 'Diameter::Message' ) }

## test decode of $cer_msg_hex
my $cer;
eval { $cer = Diameter::Message->decode( pack "H*", $cer_msg_hex ) };

cmp_ok( $@, 'eq', '', 'Diameter::Message->decode for cer message exception check' );
isa_ok( $cer, 'Diameter::Message', "Diameter::Message->decode for cer produces Diameter::Message object" );

if (!$@ && defined $cer) {
    cer_decode_tests( $cer );
    cmp_ok( unpack( "H*", $cer->encode ), 'eq', $cer_msg_hex, 'Diameter::Message->encode for cer comparison to message hex' );
}


## re-encode decoded message
my $encoded = $cer->encode;


## test decode of $cea_msg_hex
my $cea;
eval { $cea = Diameter::Message->decode( pack "H*", $cea_msg_hex ) };

cmp_ok( $@, 'eq', '', 'Diameter::Message->decode for cer message exception check' );
isa_ok( $cer, 'Diameter::Message', "Diameter::Message->decode for cea produces Diameter::Message object" );

if (!$@ && defined $cea) {
    cea_tests( $cea );
}



## test encode of basic CER message
eval {
    $cer = Diameter::Message::CER->new(
        HopByHopId      => 0x1234,
        EndToEndId      => 0xabcd,
        OriginHost      => 'test.f5demo.com',
        OriginRealm     => 'f5demo.com',
        HostIPAddress   => "192.168.25.1",
        VendorId        => 5544,
        ProductName     => "test-harness",
    );
};

cmp_ok( $@, 'eq', '', 'Diameter::Message::CER->new() for valid CER does not throw exception' );
isa_ok( $cer, 'Diameter::Message', "Diameter::Message::CER->new() for valid CER produces Diameter::Message instance" );

cmp_ok( $cer->version, '==', 1, 'Diameter::Message::CER->new() for valid CER version == 1' );
ok( $cer->is_request, 'Diameter::Message::CER->new() for valid CER is_request is true' );
cmp_ok( $cer->command_code, '==', 257, 'Diameter::Message::CER->new() for valid CER command_code == 257' );
cmp_ok( $cer->hop_by_hop_id, '==', 0x1234, 'Diameter::Message::CER->new() for valid CER hop_by_hop_id == 0x1234' );
cmp_ok( $cer->end_to_end_id, '==', 0xabcd, 'Diameter::Message::CER->new() for valid CER end_to_end_id == 0xabcd' );
cmp_ok( $cer->app_id, '==', 0, 'Diameter::Message::CER->new() for valid CER app_id == 0' );

my @avps = $cer->avps;
cmp_ok( scalar(@avps), '==', 5, 'Diameter::Message::CER->new() for valid CER AVP count is 5' );

is_deeply( [sort { $a <=> $b } (map { $_->code } @avps)], [257, 264, 266, 269, 296], 'Diameter::Message::CER->new() for valid CER all required AVPs present' );

my $encoded = $cer->encode;
my $hex = unpack( "H*", $encoded );
cmp_ok( $hex, 'eq', $constructed_cer_msg_hex, 'Diameter::Message::CER->new() for valid CER encoded properly' );

## decode encoded stream and verify
my $decoded_cer = Diameter::Message->decode( $encoded );

cmp_ok( $decoded_cer->version,       '==', 1,                   '$decoded_cer->version check' );
cmp_ok( $decoded_cer->msg_length,    '==', length($encoded),    '$decoded_cer->msg_length check' );
cmp_ok( $decoded_cer->flags,         '==', 0x8,                 '$decoded_cer->flags check' );
cmp_ok( $decoded_cer->app_id,        '==', 0,                   '$decoded_cer->app_id check' );
cmp_ok( $decoded_cer->hop_by_hop_id, '==', 0x1234,              '$decoded_cer->hop_by_hop_id check' );
cmp_ok( $decoded_cer->end_to_end_id, '==', 0xabcd,              '$decoded_cer->end_to_end_id check' );
ok( $decoded_cer->is_request, '$decoded_cer->is_request check' );

my @avps = $decoded_cer->avps;

cmp_ok( scalar @avps, '==', 5, '$decoded_cer->avps number check' );




sub cer_decode_tests {
    my $cer = shift;

    cmp_ok( $cer->version,       '==', 1,           '$cer->version check' );
    cmp_ok( $cer->msg_length,    '==', 164,         '$cer->msg_length check' );
    cmp_ok( $cer->flags,         '==', 0x8,         '$cer->flags check' );
    cmp_ok( $cer->app_id,        '==', 0,           '$cer->app_id check' );
    cmp_ok( $cer->hop_by_hop_id, '==', 0xa81826d1,  '$cer->hop_by_hop_id check' );
    cmp_ok( $cer->end_to_end_id, '==', 0xe77f7c8b,  '$cer->end_to_end_id check' );
    ok( $cer->is_request, '$cer->is_request check' );

    my @avps = $cer->avps;

    cmp_ok( scalar @avps, '==', 8, '$cer->avps number check' );

    ok( avp_check( $avps[0], 264, 2, 22, 0, undef, join( '', unpack( "H*", pack( "A*", "pcef.f5net.com" ) ) ) ),
            'CER AVP check for AVP number 1' );

    ok( avp_check( $avps[1], 296, 2, 17, 0, undef, join( '', unpack( "H*", pack( "A*", "f5net.com" ) ) ) ),
            'CER AVP check for AVP number 2' );

    ok( avp_check( $avps[2], 257, 2, 14, 0, undef, "00010a969601" ),
            'CER AVP check for AVP number 3' );

    ok( avp_check( $avps[3], 266, 2, 12, 0, undef, sprintf( "%08x", 3375 ) ),
            'CER AVP check for AVP number 4' );

    ok( avp_check( $avps[4], 269, 0, 14, 0, undef, join( '', unpack( "H*", pack( "A*", "BIG-IP" ) ) ) ),
            'CER AVP check for AVP number 5' );

    ok( avp_check( $avps[5], 265, 2, 12, 0, undef, sprintf( "%08x", 10415 ) ),
            'CER AVP check for AVP number 6' );

    ok( avp_check( $avps[6], 258, 2, 12, 0, undef, sprintf( "%08x", 16777238 ) ),
            'CER AVP check for AVP number 7' );

    ok( avp_check( $avps[7], 260, 2, 32, 0, undef, [
                [266, 2, 12, 0, undef, sprintf( "%08x", 10415 )],
                [258, 2, 12, 0, undef, sprintf( "%08x", 16777238 )]
            ] ),
            'CER AVP check for AVP number 8' );
}


sub cea_tests {
    my $cea = shift;

    cmp_ok( $cea->version,       '==', 1,           '$cea->version check' );
    cmp_ok( $cea->msg_length,    '==', 172,         '$cea->msg_length check' );
    cmp_ok( $cea->flags,         '==', 0x0,         '$cea->flags check' );
    cmp_ok( $cea->app_id,        '==', 0,           '$cea->app_id check' );
    cmp_ok( $cea->hop_by_hop_id, '==', 0xa81826d1,  '$cea->hop_by_hop_id check' );
    cmp_ok( $cea->end_to_end_id, '==', 0xe77f7c8b,  '$cea->end_to_end_id check' );
    ok( ! $cea->is_request, '$cea->is_request check' );

    my @avps = $cea->avps;

    cmp_ok( scalar @avps, '==', 9, '$cea->avps number check' );

    ok( avp_check( $avps[0], 268, 2, 12, 0, undef, sprintf( "%08x", 2001 ) ),
            'CEA AVP check for AVP number 1' );

    ok( avp_check( $avps[1], 296, 2, 19, 0, undef, join( '', unpack( "H*", pack( "A*", "traffix.com" ) ) ) ),
            'CEA AVP check for AVP number 2' );

    ok( avp_check( $avps[2], 264, 2, 19, 0, undef, join( '', unpack( "H*", pack( "A*", "f5_diameter" ) ) ) ),
            'CEA AVP check for AVP number 3' );

    ok( avp_check( $avps[3], 266, 2, 12, 0, undef, sprintf( "%08x", 637 ) ),
            'CEA AVP check for AVP number 4' );

    ok( avp_check( $avps[4], 265, 2, 12, 0, undef, sprintf( "%08x", 10415 ) ),
            'CEA AVP check for AVP number 5' );

    ok( avp_check( $avps[5], 258, 2, 12, 0, undef, sprintf( "%08x", 16777238 ) ),
            'CEA AVP check for AVP number 6' );

    ok( avp_check( $avps[6], 260, 2, 32, 0, undef, [
                [266, 2, 12, 0, undef, sprintf( "%08x", 10415 )],
                [258, 2, 12, 0, undef, sprintf( "%08x", 16777238 )]
            ] ),
            'CER AVP check for AVP number 7' );

    ok( avp_check( $avps[7], 269, 2, 14, 0, undef, join( '', unpack( "H*", pack( "A*", "BIG-IP" ) ) ) ),
            'CER AVP check for AVP number 8' );


    ok( avp_check( $avps[8], 257, 2, 14, 0, undef, "00010a969602" ),
            'CER AVP check for AVP number 9' );

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
