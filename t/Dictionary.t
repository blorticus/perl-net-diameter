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
         Name: "Capabilities-Exchange-Request"
         AbbreviatedName: "CER"
         AvpOrder: []
         MandatoryAvps: []
         OptionalAvps: []
     Answer:
         Name: "Capabilities-Exchange-Answer"
         AbbreviatedName: "CEA"
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
     Name: "Origin-Host"
     Type: "DiameterIdentity"
EOY

$d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with only single simple AvpType stanza succeeds" );

$yaml_string =<<EOY;
---
AvpTypes:
   - Code: 1
     Name: "User-Name"
     Type: "UTF8String"
   - Code: 25
     Name: "Class"
     Type: "OctetString"
   - Code: 27
     Name: "Session-Timeout"
     Type: "Unsigned32"
   - Code: 33
     Name: "Proxy-State"
     Type: "OctetString"
   - Code: 44
     Name: "Accounting-Session-Id"
     Type: "OctetString"
   - Code: 50
     Name: "Acct-Multi-Session-Id"
     Type: "UTF8String"
   - Code: 55
     Name: "Event-Timestamp"
     Type: "Time"
   - Code: 85
     Name: "Acct-Interim-Interval"
     Type: "Unsigned32"
   - Code: 257
     Name: "Host-IP-Address"
     Type: "Address"
   - Code: 258
     Name: "Auth-Application-Id"
     Type: "Unsigned32"
   - Code: 259
     Name: "Acct-Application-Id"
     Type: "Unsigned32"
   - Code: 260
     Name: "Vendor-Specific-Application-Id"
     Type: "Grouped"
   - Code: 261
     Name: "Redirect-Host-Usage"
     Type: "Enumerated"
   - Code: 262
     Name: "Redirect-Max-Cache-Time"
     Type: "Unsigned32"
   - Code: 263
     Name: "Session-Id"
     Type: "UTF8String"
   - Code: 264
     Name: "Origin-Host"
     Type: "DiameterIdentity"
   - Code: 265
     Name: "Supported-Vendor-Id"
     Type: "Unsigned32"
   - Code: 266
     Name: "Vendor-Id"
     Type: "Unsigned32"
   - Code: 267
     Name: "Firmware-Revision"
     Type: "Unsigned32"
   - Code: 268
     Name: "Result-Code"
     Type: "Unsigned32"
   - Code: 269
     Name: "Product-Name"
     Type: "UTF8String"
   - Code: 270
     Name: "Session-Binding"
     Type: "Unsigned32"
   - Code: 271
     Name: "Session-Server-Failover"
     Type: "Enumerated"
   - Code: 272
     Name: "Multi-Round-Time-Out"
     Type: "Unsigned32"
   - Code: 273
     Name: "Disconnect-Cause"
     Type: "Enumerated"
   - Code: 274
     Name: "Auth-Request-Type"
     Type: "Enumerated"
   - Code: 276
     Name: "Auth-Grace-Period"
     Type: "Unsigned32"
   - Code: 277
     Name: "Auth-Session-State"
     Type: "Enumerated"
   - Code: 278
     Name: "Origin-State-Id"
     Type: "Unsigned32"
   - Code: 279
     Name: "Failed-AVP"
     Type: "Grouped"
   - Code: 280
     Name: "Proxy-Host"
     Type: "DiameterIdentity"
   - Code: 281
     Name: "Error-Message"
     Type: "UTF8String"
   - Code: 282
     Name: "Route-Record"
     Type: "DiameterIdentity"
   - Code: 283
     Name: "Destination-Realm"
     Type: "DiameterIdentity"
   - Code: 284
     Name: "Proxy-Info"
     Type: "Grouped"
   - Code: 285
     Name: "Re-Auth-Request-Type"
     Type: "Enumerated"
   - Code: 287
     Name: "Accounting-Sub-Session-Id"
     Type: "Unsigned64"
   - Code: 291
     Name: "Authorization-Lifetime"
     Type: "Unsigned32"
   - Code: 292
     Name: "Redirect-Host"
     Type: "DiameterURI"
   - Code: 293
     Name: "Destination-Host"
     Type: "DiameterIdentity"
   - Code: 294
     Name: "Error-Reporting-Host"
     Type: "DiameterIdentity"
   - Code: 295
     Name: "Termination-Cause"
     Type: "Enumerated"
   - Code: 296
     Name: "Origin-Realm"
     Type: "DiameterIdentity"
   - Code: 297
     Name: "Experimental-Result"
     Type: "Grouped"
   - Code: 298
     Name: "Experimental-Result-Code"
     Type: "Unsigned32"
   - Code: 299
     Name: "Inband-Security-Id"
     Type: "Unsigned32"
   - Code: 300
     Name: "E2E-Sequence"
     Type: "Grouped"
   - Code: 480
     Name: "Accounting-Record-Type"
     Type: "Enumerated"
   - Code: 483
     Name: "Accounting-Realtime-Required"
     Type: "Enumerated"
   - Code: 485
     Name: "Accounting-Record-Number"
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
         Name: "Capabilities-Exchange-Request"
         AbbreviatedName: "CER"
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
         Name: "Capabilities-Exchange-Answer"
         AbbreviatedName: "CEA"
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
         Name: "Disconnect-Peer-Request"
         AbbreviatedName: "DPR"
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
         Name: "Capabilities-Exchange-Answer"
         AbbreviatedName: "CEA"
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
         Name: "Capabilities-Exchange-Request"
         AbbreviatedName: "CER"
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
         Name: "Capabilities-Exchange-Answer"
         AbbreviatedName: "CEA"
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
         Name: "Disconnect-Peer-Request"
         AbbreviatedName: "DPR"
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
         Name: "Capabilities-Exchange-Answer"
         AbbreviatedName: "CEA"
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
     Name: "User-Name"
     Type: "UTF8String"
   - Code: 25
     Name: "Class"
     Type: "OctetString"
   - Code: 27
     Name: "Session-Timeout"
     Type: "Unsigned32"
   - Code: 33
     Name: "Proxy-State"
     Type: "OctetString"
   - Code: 44
     Name: "Accounting-Session-Id"
     Type: "OctetString"
   - Code: 50
     Name: "Acct-Multi-Session-Id"
     Type: "UTF8String"
   - Code: 55
     Name: "Event-Timestamp"
     Type: "Time"
   - Code: 85
     Name: "Acct-Interim-Interval"
     Type: "Unsigned32"
   - Code: 257
     Name: "Host-IP-Address"
     Type: "Address"
   - Code: 258
     Name: "Auth-Application-Id"
     Type: "Unsigned32"
   - Code: 259
     Name: "Acct-Application-Id"
     Type: "Unsigned32"
   - Code: 260
     Name: "Vendor-Specific-Application-Id"
     Type: "Grouped"
   - Code: 261
     Name: "Redirect-Host-Usage"
     Type: "Enumerated"
   - Code: 262
     Name: "Redirect-Max-Cache-Time"
     Type: "Unsigned32"
   - Code: 263
     Name: "Session-Id"
     Type: "UTF8String"
   - Code: 264
     Name: "Origin-Host"
     Type: "DiameterIdentity"
   - Code: 265
     Name: "Supported-Vendor-Id"
     Type: "Unsigned32"
   - Code: 266
     Name: "Vendor-Id"
     Type: "Unsigned32"
   - Code: 267
     Name: "Firmware-Revision"
     Type: "Unsigned32"
   - Code: 268
     Name: "Result-Code"
     Type: "Unsigned32"
   - Code: 269
     Name: "Product-Name"
     Type: "UTF8String"
   - Code: 270
     Name: "Session-Binding"
     Type: "Unsigned32"
   - Code: 271
     Name: "Session-Server-Failover"
     Type: "Enumerated"
   - Code: 272
     Name: "Multi-Round-Time-Out"
     Type: "Unsigned32"
   - Code: 273
     Name: "Disconnect-Cause"
     Type: "Enumerated"
   - Code: 274
     Name: "Auth-Request-Type"
     Type: "Enumerated"
   - Code: 276
     Name: "Auth-Grace-Period"
     Type: "Unsigned32"
   - Code: 277
     Name: "Auth-Session-State"
     Type: "Enumerated"
   - Code: 278
     Name: "Origin-State-Id"
     Type: "Unsigned32"
   - Code: 279
     Name: "Failed-AVP"
     Type: "Grouped"
   - Code: 280
     Name: "Proxy-Host"
     Type: "DiameterIdentity"
   - Code: 281
     Name: "Error-Message"
     Type: "UTF8String"
   - Code: 282
     Name: "Route-Record"
     Type: "DiameterIdentity"
   - Code: 283
     Name: "Destination-Realm"
     Type: "DiameterIdentity"
   - Code: 284
     Name: "Proxy-Info"
     Type: "Grouped"
   - Code: 285
     Name: "Re-Auth-Request-Type"
     Type: "Enumerated"
   - Code: 287
     Name: "Accounting-Sub-Session-Id"
     Type: "Unsigned64"
   - Code: 291
     Name: "Authorization-Lifetime"
     Type: "Unsigned32"
   - Code: 292
     Name: "Redirect-Host"
     Type: "DiameterURI"
   - Code: 293
     Name: "Destination-Host"
     Type: "DiameterIdentity"
   - Code: 294
     Name: "Error-Reporting-Host"
     Type: "DiameterIdentity"
   - Code: 295
     Name: "Termination-Cause"
     Type: "Enumerated"
   - Code: 296
     Name: "Origin-Realm"
     Type: "DiameterIdentity"
   - Code: 297
     Name: "Experimental-Result"
     Type: "Grouped"
   - Code: 298
     Name: "Experimental-Result-Code"
     Type: "Unsigned32"
   - Code: 299
     Name: "Inband-Security-Id"
     Type: "Unsigned32"
   - Code: 300
     Name: "E2E-Sequence"
     Type: "Grouped"
   - Code: 480
     Name: "Accounting-Record-Type"
     Type: "Enumerated"
   - Code: 483
     Name: "Accounting-Realtime-Required"
     Type: "Enumerated"
   - Code: 485
     Name: "Accounting-Record-Number"
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
    Name            => 'Origin-Host',
    Type            => 'DiameterIdentity',
};

is_deeply( $avp_ds, $expected_origin_host_ds, "describe_avp() on expected data structure for Name => Origin-Host" );


done_testing();
