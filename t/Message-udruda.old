use Test::More tests => 10;

#                  |DIAMETER-HEADER
my $udr_msg_hex = "010000b4c0000132010000010000000200000003" .
#                    |Vendor-Specific-Application-Id
                    "0000010440000014" .
#                         |Vendor-Id
                         "0000010a4000000c01000001" .
#                    |Auth-Session-State
                    "000001154000000c00000001" .
#                    |Origin-Host
                    "0000010840000018746573742e6578616d706c652e636f6d" .
#                    |Origin-Realm
                    "00000128400000136578616d706c652e636f6d00" .
#                    |Destination-Realm
                    "0000011b4000001272656d6f74652e636f6d0000" .
#                    |Data-Reference
                    "000002bfc0000010000028af00000016" .
#                    |User-Identity
                    "000002bcc0000030000028af" .
#                        |Framed-IP-Address
                        "000000080000000cc0a80a01" .
#                        |Proto
                        "000002010000000c00000006" .
#                        |Port
                        "000002120000000c00008bcf"
;

BEGIN { use_ok( 'Diameter::Message' ) }

my $udr = Diameter::Message->new(
    IsRequest       => 1,
    CommandCode     => 306,
    ApplicationId   => 16777217,
    HopByHopId      => 2,
    EndToEndId      => 3,
    Avps            => [
        Diameter::Message::AVP->new( Code => 260, IsMandatory => 1, Data => [
            Diameter::Message::AVP->new( Code => 266, IsMandatory => 1, Data => 16777217 ),
        ] ),
        Diameter::Message::AVP->new( Code => 277, IsMandatory => 1, Data => 1 ),
        Diameter::Message::AVP->new( Code => 264, IsMandatory => 1, Data => 'test.example.com' ),
        Diameter::Message::AVP->new( Code => 296, IsMandatory => 1, Data => 'example.com' ),
        Diameter::Message::AVP->new( Code => 283, IsMandatory => 1, Data => 'remote.com' ),
        Diameter::Message::AVP->new( Code => 703, VendorId => 10415, IsMandatory => 1, Data => 22 ),
        Diameter::Message::AVP->new( Code => 700, VendorId => 10415, IsMandatory => 1, Data => [
            Diameter::Message::AVP->new( Code => 8, Data => "\xc0\xa8\x0a\01" ),  # 192.168.10.1
            Diameter::Message::AVP->new( Code => 513, Data => 6 ),
            Diameter::Message::AVP->new( Code => 530, Data => 35791 ),
        ] ),
    ],
);

my $encoded = $udr->encode();
my $hex     = unpack( "H*", $encoded );

cmp_ok( substr( $hex, 0, length( $udr_msg_hex ) ), 'eq', $udr_msg_hex, "Encoded UDR matches expected byte stream" );


## and now decode back to an object
$decoded_udr = Diameter::Message->decode( $encoded );

cmp_ok( $decoded_udr->version,        '==', 1,                   '$decoded_udr->version check' );
cmp_ok( $decoded_udr->msg_length,     '==', length($encoded),    '$decoded_udr->msg_length check' );
cmp_ok( $decoded_udr->flags,          '==', 0xc,                 '$decoded_udr->flags check' );
cmp_ok( $decoded_udr->application_id, '==', 16777217,            '$decoded_udr->application_id check' );
cmp_ok( $decoded_udr->hop_by_hop_id,  '==', 0x2,                 '$decoded_udr->hop_by_hop_id check' );
cmp_ok( $decoded_udr->end_to_end_id,  '==', 0x3,                 '$decoded_udr->end_to_end_id check' );
ok( $decoded_udr->is_request, '$decoded_udr->is_request check' );

my @avps = $decoded_udr->avps;

cmp_ok( scalar @avps, '==', 7, '$decoded_udr->avps number check' );


