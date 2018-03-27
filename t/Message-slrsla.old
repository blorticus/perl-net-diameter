use Test::More;

BEGIN { use_ok( 'Diameter::Message' ) }

my $slr_msg_hex = "01000118c080001b010000565820003a736089e600000107400000327065657230312e6578616d706c652e636f6d3b31323334353637383b313233343536373b6162636465660000000001024000000c01000056000001084000001a7065657230312e6578616d706c652e636f6d0000000001284000001673792e6578616d706c652e636f6d000000000b58c0000010000028af000000010000011b4000001a7461726765742e6578616d706c652e636f6d0000000001bb40000028000001c24000000c00000001000001bc40000014313233343536373839303132000001254000001e7379312e7461726765742e6578616d706c652e636f6d00000000011a4000001a70726f7879312e6578616d706c652e636f6d0000";

my $slr;
eval { $slr = Diameter::Message->decode( pack "H*", $slr_msg_hex ) };

cmp_ok( $@, 'eq', '', 'Diameter::Message->decode for dlr message produces no exception' );
isa_ok( $slr, 'Diameter::Message', 'Diameter::Message->decode for slr produces Diameter::Message object' );

my $m = Diameter::Message->new(
    CommandCode => 8388635,
    ApplicationId => 16777302,
    IsRequest => 1,
    HopByHopId => 0x5820003a,
    EndToEndId => 0x736089e6,
    Avps => [
        Diameter::Message::AVP->new( Code => 263, IsMandatory => 1, Data => "peer01.example.com;12345678;1234567;abcdef" ),
        Diameter::Message::AVP->new( Code => 258, IsMandatory => 1, Data => 16777302 ),
        Diameter::Message::AVP->new( Code => 264, IsMandatory => 1, Data => "peer01.example.com" ),
        Diameter::Message::AVP->new( Code => 296, IsMandatory => 1, Data => "sy.example.com" ),
        Diameter::Message::AVP->new( Code => 2904, VendorId => 10415, IsMandatory => 1, Data => 1 ),
        Diameter::Message::AVP->new( Code => 283, IsMandatory => 1, Data => "target.example.com" ),
        Diameter::Message::AVP->new( Code => 443, IsMandatory => 1, Data => [
            Diameter::Message::AVP->new( Code => 450, IsMandatory => 1, Data => 1 ),
            Diameter::Message::AVP->new( Code => 444, IsMandatory => 1, Data => "123456789012" ),
        ] ),
        Diameter::Message::AVP->new( Code => 293, IsMandatory => 1, Data => "sy1.target.example.com" ),
        Diameter::Message::AVP->new( Code => 282, IsMandatory => 1, Data => "proxy1.example.com" ),
    ],
);

cmp_ok( unpack( "H*", $m->encode ), 'eq', $slr_msg_hex, "Encoded slr from object creation matches expected encoding" );


done_testing();
