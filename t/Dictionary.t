use Test::More;

use strict;
use warnings;

BEGIN { use_ok( 'Diameter::Dictionary' ) }

ok( !Diameter::Dictionary->new(), "Diameter\:\:Dictionary->new() returns undef" );
ok( !Diameter::Dictionary->new( FromString => undef ), "Diameter\:\:Dictionary->new() FromString cannot be undef" );
ok( !Diameter::Dictionary->new( FromFile => undef ), "Diameter\:\:Dictionary->new() FromFile cannot be undef" );
ok( !Diameter::Dictionary->new( FromFile => "" ), "Diameter\:\:Dictionary->new() FromFile cannot be empty string" );
ok( !Diameter::Dictionary->new( FromFoo => "this" ), "Diameter\:\:Dictionary->new() FromFile or FromString must be defined" );

ok( !Diameter::Dictionary->new( FromString => "" ), "Diameter\:\:Dictionary->new() cannot have FromString be empty" );
ok( !Diameter::Dictionary->new( FromString => "---\n" ), "Diameter\:\:Dictionary->new() string cannot be empty yaml" );
ok( !Diameter::Dictionary->new( FromString => "---\nFoo:\nBar:\n  - This: that\n" ), "Diameter\:\:Dictionary->new() string must define MessageTypes or AvpTypes" );

my $yaml_string =<<EOY;
---
MessageTypes:
EOY

my $d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with only MessageTypes stanza succeeds" );

$yaml_string =<<EOY;
---
MessageTypes:
   - Code: 272
     ApplicationId: 0
     Proxiable: false
     Request:
         Names: ["Capabilities-Exchange-Request", "CER"]
         AvpOrder: []
         MandatoryAvps: []
         OptionalAvps: []
     Answer:
         Names: ["Capabilities-Exchange-Answer", "CEA"]
         AvpOrder: []
         MandatoryAvps: []
         OptionalAvps: []
EOY

$d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with only single simple MessageType stanza succeeds" );

$yaml_string =<<EOY;
---
AvpTypes:
   - Code: 264
     VendorId: 0
     Names: ["Origin-Host"]
     Type: "DiamIdent"
EOY

$d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with only single simple AvpType stanza succeeds" );

$yaml_string =<<EOY;
---
AvpTypes:
   - Code: 1
     Names: ["User-Name"]
     Type: "UTF8String"
   - Code: 25
     Names: ["Class"]
     Type: "OctetString"
   - Code: 27
     Names: ["Session-Timeout"]
     Type: "Unsigned32"
   - Code: 33
     Names: ["Proxy-State"]
     Type: "OctetString"
   - Code: 44
     Names: ["Accounting-Session-Id"]
     Type: "OctetString"
   - Code: 50
     Names: ["Acct-Multi-Session-Id"]
     Type: "UTF8String"
   - Code: 55
     Names: ["Event-Timestamp"]
     Type: "Time"
   - Code: 85
     Names: ["Acct-Interim-Interval"]
     Type: "Unsigned32"
   - Code: 257
     Names: ["Host-IP-Address"]
     Type: "Address"
   - Code: 258
     Names: ["Auth-Application-Id"]
     Type: "Unsigned32"
   - Code: 259
     Names: ["Acct-Application-Id"]
     Type: "Unsigned32"
   - Code: 260
     Names: ["Vendor-Specific-Application-Id"]
     Type: "Grouped"
   - Code: 261
     Names: ["Redirect-Host-Usage"]
     Type: "Enumerated"
   - Code: 262
     Names: ["Redirect-Max-Cache-Time"]
     Type: "Unsigned32"
   - Code: 263
     Names: ["Session-Id"]
     Type: "UTF8String"
   - Code: 264
     Names: ["Origin-Host"]
     Type: "DiamIdent"
   - Code: 265
     Names: ["Supported-Vendor-Id"]
     Type: "Unsigned32"
   - Code: 266
     Names: ["Vendor-Id"]
     Type: "Unsigned32"
   - Code: 267
     Names: ["Firmware-Revision"]
     Type: "Unsigned32"
   - Code: 268
     Names: ["Result-Code"]
     Type: "Unsigned32"
   - Code: 269
     Names: ["Product-Name"]
     Type: "UTF8String"
   - Code: 270
     Names: ["Session-Binding"]
     Type: "Unsigned32"
   - Code: 271
     Names: ["Session-Server-Failover"]
     Type: "Enumerated"
   - Code: 272
     Names: ["Multi-Round-Time-Out"]
     Type: "Unsigned32"
   - Code: 273
     Names: ["Disconnect-Cause"]
     Type: "Enumerated"
   - Code: 274
     Names: ["Auth-Request-Type"]
     Type: "Enumerated"
   - Code: 276
     Names: ["Auth-Grace-Period"]
     Type: "Unsigned32"
   - Code: 277
     Names: ["Auth-Session-State"]
     Type: "Enumerated"
   - Code: 278
     Names: ["Origin-State-Id"]
     Type: "Unsigned32"
   - Code: 279
     Names: ["Failed-AVP"]
     Type: "Grouped"
   - Code: 280
     Names: ["Proxy-Host"]
     Type: "DiamIdent"
   - Code: 281
     Names: ["Error-Message"]
     Type: "UTF8String"
   - Code: 282
     Names: ["Route-Record"]
     Type: "DiamIdent"
   - Code: 283
     Names: ["Destination-Realm"]
     Type: "DiamIdent"
   - Code: 284
     Names: ["Proxy-Info"]
     Type: "Grouped"
   - Code: 285
     Names: ["Re-Auth-Request-Type"]
     Type: "Enumerated"
   - Code: 287
     Names: ["Accounting-Sub-Session-Id"]
     Type: "Unsigned64"
   - Code: 291
     Names: ["Authorization-Lifetime"]
     Type: "Unsigned32"
   - Code: 292
     Names: ["Redirect-Host"]
     Type: "DiamURI"
   - Code: 293
     Names: ["Destination-Host"]
     Type: "DiamIdent"
   - Code: 294
     Names: ["Error-Reporting-Host"]
     Type: "DiamIdent"
   - Code: 295
     Names: ["Termination-Cause"]
     Type: "Enumerated"
   - Code: 296
     Names: ["Origin-Realm"]
     Type: "DiamIdent"
   - Code: 297
     Names: ["Experimental-Result"]
     Type: "Grouped"
   - Code: 298
     Names: ["Experimental-Result-Code"]
     Type: "Unsigned32"
   - Code: 299
     Names: ["Inband-Security-Id"]
     Type: "Unsigned32"
   - Code: 300
     Names: ["E2E-Sequence"]
     Type: "Grouped"
   - Code: 480
     Names: ["Accounting-Record-Type"]
     Type: "Enumerated"
   - Code: 483
     Names: ["Accounting-Realtime-Required"]
     Type: "Enumerated"
   - Code: 485
     Names: ["Accounting-Record-Number"]
     Type: "Unsigned32"
EOY

$d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with AVP definitions but no Message definitions succeeds" );

$yaml_string =<<EOY;
---
MessageTypes:
   - Code: 272
     ApplicationId: 0
     Proxiable: false
     Request:
         Names: ["Capabilities-Exchange-Request", "CER"]
         AvpOrder:
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address
            - Vendor-Id
            - Product-Name
            - Origin-State-Id
            - Supported-Vendor-Id
            - Auth-Application-Id
            - Inband-Security-Id
            - Acct-Application-Id
            - Vendor-Specific-Application-Id
            - Firmware-Revision
            - AVP
         MandatoryAvps:
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address:1*
            - Vendor-Id
            - Product-Name
         OptionalAvps:
            - Origin-State-Id
            - Supported-Vendor-Id:*
            - Auth-Application-Id:*
            - Inband-Security-Id:*
            - Acct-Application-Id:*
            - Vendor-Specific-Application-Id:*
            - Firmware-Revision
            - AVP:*
     Answer:
         Names: ["Capabilities-Exchange-Answer", "CEA"]
         AvpOrder:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address
            - Vendor-Id
            - Product-Name
            - Origin-State-Id
            - Error-Message
            - Failed-AVP
            - Supported-Vendor-Id
            - Auth-Application-Id
            - Inband-Security-Id
            - Acct-Application-Id
            - Vendor-Specific-Application-Id
            - Firmware-Revision
            - AVP
         MandatoryAvps:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address:1*
            - Vendor-Id
            - Product-Name
         OptionalAvps:
            - Origin-State-Id
            - Error-Message
            - Failed-AVP
            - Supported-Vendor-Id:*
            - Auth-Application-Id:*
            - Inband-Security-Id:*
            - Acct-Application-Id:*
            - Vendor-Specific-Application-Id:*
            - Firmware-Revision
            - AVP:*
   - Code: 282
     ApplicationId: 0
     Proxiable: false
     Request:
         Names: ["Disconnect-Peer-Request", "DPR"]
         AvpOrder:
            - Origin-Host
            - Origin-Realm
            - Disconnect-Cause
            - AVP
         MandatoryAvps:
            - Origin-Host
            - Origin-Realm
            - Disconnect-Cause
         OptionalAvps:
            - AVP:*
     Answer:
         Names: ["Capabilities-Exchange-Answer", "CEA"]
         AvpOrder:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Error-Message
            - Failed-AVP
            - AVP
         MandatoryAvps:
            - Result-Code
            - Origin-Host
            - Origin-Realm
         OptionalAvps:
            - Error-Message
            - Failed-AVP
            - AVP:*

EOY

$d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( !defined $d, "Diameter\:\:Dictionary->new() with Message definitions but no AVPs fails because AVPs are not defined" );


$yaml_string =<<EOY;
---
MessageTypes:
   - Code: 272
     ApplicationId: 0
     Proxiable: false
     Request:
         Names: ["Capabilities-Exchange-Request", "CER"]
         AvpOrder:
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address
            - Vendor-Id
            - Product-Name
            - Origin-State-Id
            - Supported-Vendor-Id
            - Auth-Application-Id
            - Inband-Security-Id
            - Acct-Application-Id
            - Vendor-Specific-Application-Id
            - Firmware-Revision
            - AVP
         MandatoryAvps:
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address:1*
            - Vendor-Id
            - Product-Name
         OptionalAvps:
            - Origin-State-Id
            - Supported-Vendor-Id:*
            - Auth-Application-Id:*
            - Inband-Security-Id:*
            - Acct-Application-Id:*
            - Vendor-Specific-Application-Id:*
            - Firmware-Revision
            - AVP:*
     Answer:
         Names: ["Capabilities-Exchange-Answer", "CEA"]
         AvpOrder:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address
            - Vendor-Id
            - Product-Name
            - Origin-State-Id
            - Error-Message
            - Failed-AVP
            - Supported-Vendor-Id
            - Auth-Application-Id
            - Inband-Security-Id
            - Acct-Application-Id
            - Vendor-Specific-Application-Id
            - Firmware-Revision
            - AVP
         MandatoryAvps:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address:1*
            - Vendor-Id
            - Product-Name
         OptionalAvps:
            - Origin-State-Id
            - Error-Message
            - Failed-AVP
            - Supported-Vendor-Id:*
            - Auth-Application-Id:*
            - Inband-Security-Id:*
            - Acct-Application-Id:*
            - Vendor-Specific-Application-Id:*
            - Firmware-Revision
            - AVP:*
   - Code: 282
     ApplicationId: 0
     Proxiable: false
     Request:
         Names: ["Disconnect-Peer-Request", "DPR"]
         AvpOrder:
            - Origin-Host
            - Origin-Realm
            - Disconnect-Cause
            - AVP
         MandatoryAvps:
            - Origin-Host
            - Origin-Realm
            - Disconnect-Cause
         OptionalAvps:
            - AVP:*
     Answer:
         Names: ["Capabilities-Exchange-Answer", "CEA"]
         AvpOrder:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Error-Message
            - Failed-AVP
            - AVP
         MandatoryAvps:
            - Result-Code
            - Origin-Host
            - Origin-Realm
         OptionalAvps:
            - Error-Message
            - Failed-AVP
            - AVP:*
AvpTypes:
   - Code: 1
     Names: ["User-Name"]
     Type: "UTF8String"
   - Code: 25
     Names: ["Class"]
     Type: "OctetString"
   - Code: 27
     Names: ["Session-Timeout"]
     Type: "Unsigned32"
   - Code: 33
     Names: ["Proxy-State"]
     Type: "OctetString"
   - Code: 44
     Names: ["Accounting-Session-Id"]
     Type: "OctetString"
   - Code: 50
     Names: ["Acct-Multi-Session-Id"]
     Type: "UTF8String"
   - Code: 55
     Names: ["Event-Timestamp"]
     Type: "Time"
   - Code: 85
     Names: ["Acct-Interim-Interval"]
     Type: "Unsigned32"
   - Code: 257
     Names: ["Host-IP-Address"]
     Type: "Address"
   - Code: 258
     Names: ["Auth-Application-Id"]
     Type: "Unsigned32"
   - Code: 259
     Names: ["Acct-Application-Id"]
     Type: "Unsigned32"
   - Code: 260
     Names: ["Vendor-Specific-Application-Id"]
     Type: "Grouped"
   - Code: 261
     Names: ["Redirect-Host-Usage"]
     Type: "Enumerated"
   - Code: 262
     Names: ["Redirect-Max-Cache-Time"]
     Type: "Unsigned32"
   - Code: 263
     Names: ["Session-Id"]
     Type: "UTF8String"
   - Code: 264
     Names: ["Origin-Host"]
     Type: "DiamIdent"
   - Code: 265
     Names: ["Supported-Vendor-Id"]
     Type: "Unsigned32"
   - Code: 266
     Names: ["Vendor-Id"]
     Type: "Unsigned32"
   - Code: 267
     Names: ["Firmware-Revision"]
     Type: "Unsigned32"
   - Code: 268
     Names: ["Result-Code"]
     Type: "Unsigned32"
   - Code: 269
     Names: ["Product-Name"]
     Type: "UTF8String"
   - Code: 270
     Names: ["Session-Binding"]
     Type: "Unsigned32"
   - Code: 271
     Names: ["Session-Server-Failover"]
     Type: "Enumerated"
   - Code: 272
     Names: ["Multi-Round-Time-Out"]
     Type: "Unsigned32"
   - Code: 273
     Names: ["Disconnect-Cause"]
     Type: "Enumerated"
   - Code: 274
     Names: ["Auth-Request-Type"]
     Type: "Enumerated"
   - Code: 276
     Names: ["Auth-Grace-Period"]
     Type: "Unsigned32"
   - Code: 277
     Names: ["Auth-Session-State"]
     Type: "Enumerated"
   - Code: 278
     Names: ["Origin-State-Id"]
     Type: "Unsigned32"
   - Code: 279
     Names: ["Failed-AVP"]
     Type: "Grouped"
   - Code: 280
     Names: ["Proxy-Host"]
     Type: "DiamIdent"
   - Code: 281
     Names: ["Error-Message"]
     Type: "UTF8String"
   - Code: 282
     Names: ["Route-Record"]
     Type: "DiamIdent"
   - Code: 283
     Names: ["Destination-Realm"]
     Type: "DiamIdent"
   - Code: 284
     Names: ["Proxy-Info"]
     Type: "Grouped"
   - Code: 285
     Names: ["Re-Auth-Request-Type"]
     Type: "Enumerated"
   - Code: 287
     Names: ["Accounting-Sub-Session-Id"]
     Type: "Unsigned64"
   - Code: 291
     Names: ["Authorization-Lifetime"]
     Type: "Unsigned32"
   - Code: 292
     Names: ["Redirect-Host"]
     Type: "DiamURI"
   - Code: 293
     Names: ["Destination-Host"]
     Type: "DiamIdent"
   - Code: 294
     Names: ["Error-Reporting-Host"]
     Type: "DiamIdent"
   - Code: 295
     Names: ["Termination-Cause"]
     Type: "Enumerated"
   - Code: 296
     Names: ["Origin-Realm"]
     Type: "DiamIdent"
   - Code: 297
     Names: ["Experimental-Result"]
     Type: "Grouped"
   - Code: 298
     Names: ["Experimental-Result-Code"]
     Type: "Unsigned32"
   - Code: 299
     Names: ["Inband-Security-Id"]
     Type: "Unsigned32"
   - Code: 300
     Names: ["E2E-Sequence"]
     Type: "Grouped"
   - Code: 480
     Names: ["Accounting-Record-Type"]
     Type: "Enumerated"
   - Code: 483
     Names: ["Accounting-Realtime-Required"]
     Type: "Enumerated"
   - Code: 485
     Names: ["Accounting-Record-Number"]
     Type: "Unsigned32"

EOY

$d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with Message definitions and all corresponding AVP definitions succeeds" );

my $expected_cer_ds = {
    Properties    => { Code => 272, ApplicationId => 0, Proxiable => 0, Error => 0 },
    AvpOrder      => [qw(0:264 0:296 0:257 0:266 0:269 0:278 0:265 0:258 0:299 0:259 0:260 0:267 AVP)], 
    MandatoryAvps => {qw(0:264 1 0:296 1 0:257 1* 0:266 1 0:269 1)},
    OptionalAvps  => {qw(0:278 1 0:265 * 0:258 *  0:299 * 0:259 * 0:260 * 0:267 1 AVP *)},
};

my $msg_ds = $d->describe_message( Name => "CER" );
foreach my $p (qw(Proxiable Error)) {
    # normalize these boolean values for the purposes of comparison
    if (exists $msg_ds->{Properties}->{$p}) {
        if ($msg_ds->{Properties}->{$p}) { $msg_ds->{Properties}->{$p} = 1 }
        else                             { $msg_ds->{Properties}->{$p} = 0 }
    }
}

is_deeply( $msg_ds, $expected_cer_ds, "describe_message() on complete message and avpset 1 returns expected data structure for Name => CER" );

my $avp_ds = $d->describe_avp( Name => "Origin-Host" );
my $expected_origin_host_ds = {
    Code            => 264,
    VendorId        => 0,
    Names           => [ 'Origin-Host' ],
    Type            => 'DiamIdent',
};

is_deeply( $avp_ds, $expected_origin_host_ds, "describe_avp() on expected data structure for Name => Origin-Host" );


done_testing();
