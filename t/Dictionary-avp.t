use Test::More;

use strict;
use warnings;

BEGIN { use_ok( 'Diameter::Dictionary' ) }

my $yaml_string =<<EOY;
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
   - Code: 411
     Name: "CC-Correlation-Id"
     Type: "OctetString"
   - Code: 412
     Name: "CC-Input-Octets"
     Type: "Unsigned64"
   - Code: 413
     Name: "CC-Money"
     Type: "Grouped"
   - Code: 414
     Name: "CC-Output-Octets"
     Type: "Unsigned64"
   - Code: 415
     Name: "CC-Request-Number"
     Type: "Unsigned32"
   - Code: 416
     Name: "CC-Request-Type"
     Type: "Enumerated"
   - Code: 417
     Name: "CC-Service-Specific-Units"
     Type: "Unsigned64"
   - Code: 418
     Name: "CC-Session-Failover"
     Type: "Enumerated"
   - Code: 419
     Name: "CC-Sub-Session-Id"
     Type: "Unsigned64"
   - Code: 420
     Name: "CC-Time"
     Type: "Unsigned32"
   - Code: 421
     Name: "CC-Total-Octets"
     Type: "Unsigned64"
   - Code: 422
     Name: "Check-Balance-Result"
     Type: "Enumerated"
   - Code: 423
     Name: "Cost-Information"
     Type: "Grouped"
   - Code: 424
     Name: "Cost-Unit"
     Type: "UTF8String"
   - Code: 425
     Name: "Currency-Code"
     Type: "Unsigned32"
   - Code: 426
     Name: "Credit-Control"
     Type: "Enumerated"
   - Code: 427
     Name: "Credit-Control-Failure-Handling"
     Type: "Enumerated"
   - Code: 428
     Name: "Direct-Debiting-Failure-Handling"
     Type: "Enumerated"
   - Code: 429
     Name: "Exponent"
     Type: "Integer32"
   - Code: 430
     Name: "Final-Unit-Indication"
     Type: "Grouped"
   - Code: 431
     Name: "Granted-Service-Unit"
     Type: "Grouped"
   - Code: 432
     Name: "Rating-Group"
     Type: "Unsigned32"
   - Code: 433
     Name: "Redirect-Address-Type"
     Type: "Enumerated"
   - Code: 434
     Name: "Redirect-Server"
     Type: "Grouped"
   - Code: 435
     Name: "Redirect-Server-Address"
     Type: "UTF8String"
   - Code: 436
     Name: "Requested-Action"
     Type: "Enumerated"
   - Code: 437
     Name: "Requested-Service-Unit"
     Type: "Grouped"
   - Code: 438
     Name: "Restriction-Filter-Rule"
     Type: "IPFilterRule"
   - Code: 439
     Name: "Service-Identifier"
     Type: "Unsigned32"
   - Code: 440
     Name: "Service-Parameter-Info"
     Type: "Grouped"
   - Code: 441
     Name: "Service-Parameter-Type"
     Type: "Unsigned32"
   - Code: 442
     Name: "Service-Parameter-Value"
     Type: "OctetString"
   - Code: 443
     Name: "Subscription-Id"
     Type: "Grouped"
   - Code: 444
     Name: "Subscription-Id-Data"
     Type: "UTF8String"
   - Code: 445
     Name: "Unit-Value"
     Type: "Grouped"
   - Code: 446
     Name: "Used-Service-Unit"
     Type: "Grouped"
   - Code: 447
     Name: "Value-Digits"
     Type: "Integer64"
   - Code: 448
     Name: "Validity-Time"
     Type: "Unsigned32"
   - Code: 449
     Name: "Final-Unit-Action"
     Type: "Enumerated"
   - Code: 450
     Name: "Subscription-Id-Type"
     Type: "Enumerated"
   - Code: 451
     Name: "Tariff-Time-Change"
     Type: "Time"
   - Code: 452
     Name: "Tariff-Change-Usage"
     Type: "Enumerated"
   - Code: 453
     Name: "G-S-U-Pool-Identifier"
     Type: "Unsigned32"
   - Code: 454
     Name: "CC-Unit-Type"
     Type: "Enumerated"
   - Code: 455
     Name: "Multiple-Services-Indicator"
     Type: "Enumerated"
   - Code: 456
     Name: "Multiple-Services-Credit-Control"
     Type: "Grouped"
   - Code: 457
     Name: "G-S-U-Pool-Reference"
     Type: "Grouped"
   - Code: 458
     Name: "User-Equipment-Info"
     Type: "Grouped"
   - Code: 459
     Name: "User-Equipment-Info-Type"
     Type: "Enumerated"
   - Code: 460
     Name: "User-Equipment-Info-Value"
     Type: "OctetString"
   - Code: 461
     Name: "Service-Context-Id"
     Type: "UTF8String"
   - Code: 480
     Name: "Accounting-Record-Type"
     Type: "Enumerated"
   - Code: 483
     Name: "Accounting-Realtime-Required"
     Type: "Enumerated"
   - Code: 485
     Name: "Accounting-Record-Number"
     Type: "Unsigned32"
   - Code: 513
     Name: "Protocol"
     Type: "Unsigned32"
   - Code: 530
     Name: "Port"
     Type: "Unsigned32"
   - Code: 700
     VendorId: 10415
     Name: "User-Identity"
     Type: "Grouped"
   - Code: 703
     VendorId: 10415
     Name: "Data-Reference"
     Type: "Enumerated"
   - Code: 1000
     VendorId: 10415
     Name: "Bearer-Usage"
     Type: "Enumerated"
   - Code: 1001
     VendorId: 10415
     Name: "Charging-Rule-Install"
     Type: "Grouped"
   - Code: 1002
     VendorId: 10415
     Name: "Charging-Rule-Remove"
     Type: "Grouped"
   - Code: 1003
     VendorId: 10415
     Name: "Charging-Rule-Definition"
     Type: "Grouped"
   - Code: 1004
     VendorId: 10415
     Name: "Charging-Rule-Base-Name"
     Type: "OctetString"
   - Code: 1005
     VendorId: 10415
     Name: "Charging-Rule-Name"
     Type: "OctetString"
   - Code: 1006
     VendorId: 10415
     Name: "Event-Trigger"
     Type: "Enumerated"
   - Code: 1007
     VendorId: 10415
     Name: "Metering-Method"
     Type: "Enumerated"
   - Code: 1008
     VendorId: 10415
     Name: "Offline"
     Type: "Enumerated"
   - Code: 1009
     VendorId: 10415
     Name: "Online"
     Type: "Enumerated"
   - Code: 1010
     VendorId: 10415
     Name: "Precedence"
     Type: "Unsigned32"
   - Code: 1011
     VendorId: 10415
     Name: "Primary-CCF-Address"
     Type: "DiameterURI"
   - Code: 1012
     VendorId: 10415
     Name: "Primary-OCS-Address"
     Type: "DiameterURI"
   - Code: 1013
     VendorId: 10415
     Name: "RAT-Type"
     Type: "Enumerated"
   - Code: 1014
     VendorId: 10415
     Name: "Reporting-Level"
     Type: "Enumerated"
   - Code: 1015
     VendorId: 10415
     Name: "Secondary-CCF-Address"
     Type: "DiameterURI"
   - Code: 1016
     VendorId: 10415
     Name: "Secondary-OCS-Address"
     Type: "DiameterURI"
   - Code: 1017
     VendorId: 10415
     Name: "TFT-Filter"
     Type: "IPFilterRule"
   - Code: 1018
     VendorId: 10415
     Name: "TFT-Packet-Filter-Information"
     Type: "Grouped"
   - Code: 1019
     VendorId: 10415
     Name: "ToS-Traffic-Class"
     Type: "OctetString"
   - Code: 2901
     VendorId: 10415
     Name: "Policy-Counter-Identifier"
     Type: "UTF8String"
   - Code: 2902
     VendorId: 10415
     Name: "Policy-Counter-Status"
     Type: "UTF8String"
   - Code: 2903
     VendorId: 10415
     Name: "Policy-Counter-Status-Report"
     Type: "Grouped"
   - Code: 2904
     VendorId: 10415
     Name: "SL-Request-Type"
     Type: "Enumerated"
EOY

my $d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with only single simple MessageType stanza succeeds" );

validate_avp( $d->avp( Name => "User-Name", Value => "tester123" ),
              "User-Name", "tester123", "eq", 0, 1, 0, "0000000100000011746573746572313233000000",
              'Diameter::Dictionary::avp with Name => "User-Name", Value => "tester123"' );

validate_avp( $d->avp( VendorId => 0, Code => 25, Value => "\x50\x51\x52\x53\x54" ),
              "Class", pack( "H*", 5051525354 ), "eq", 0, 25, 0, "000000190000000d5051525354000000",
              'Diameter::Dictionary::avp with VendorId => 0, Code => 25, Value => <octet_stream>' );

validate_avp( $d->avp( Name => "Precedence", Value => 10 ),
              "Precedence", 10, "==", 10415, 1010, 0, "000003f280000010000028af0000000a",
              'Diameter::Dictionary::avp with Name => "Precedence", Value => 10' );


sub validate_avp {
    my ($avp, $name, $value, $operator, $vendorid, $code, $is_mandatory, $expected_encoding, $testname) = @_;

    ok( defined $avp && ref $avp, "($testname) object created" );

    # the rest of the tests will fail if this isn't true
    return unless defined $avp && ref $avp;

    cmp_ok( $avp->name, 'eq', $name, "($testname) name is expected value ($name)" );
    cmp_ok( $avp->data, $operator, $value, "($testname) data is expected value ($value)" );
    cmp_ok( $avp->vendor_id, 'eq', $vendorid, "($testname) vendor_id is expected value ($value)" );
    ok( ($avp->vendor_id != 0 ? $avp->has_vendor_id : !$avp->has_vendor_id), "($testname) has_vendor_id is expected value" );
    cmp_ok( $avp->code, 'eq', $code, "($testname) code is expected value ($code)" );
    cmp_ok( $avp->flags, '==', ($vendorid == 0 ? 0 : 4), "($testname) flags are 0x0" );
    cmp_ok( unpack( "H*", $avp->encode ), 'eq', $expected_encoding, "($testname) encoded value as expected" );
}


done_testing();
