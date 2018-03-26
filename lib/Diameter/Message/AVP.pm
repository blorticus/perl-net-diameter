package Diameter::Message::AVP;

use strict;
use warnings;



# Indexed by AVP code, value is listref of [ $avp_name, $class_basename, $datatype, $vendorid ]
#
# $avp_name is the RFC defined name; $class_basename is class basename in Diameter::Message::AVP
#  (i.e., class name is Diameter::Message::AVP::$class_basename); $datatype is RFC defined data type;
#  $vendorid is the VendorID field value or undef if VendorID is not included.  Diameter::Message::AVP::$class_basename
#  must be defined.
# If AVP code is nnn:yyy then it is vendorid:code
my %AVP_DEFINITION_BY_CODE;

# indexed by AVP class, points to the Code value for that class.  As above, if the Code is nnn:yyy
# it represents AVP Code and VendorId.  Auto-populate this in BEGIN block to avoid having to make
# config change in two places since this just reverses the mapping above
my %AVP_CLASS_CODE;

BEGIN {
%AVP_DEFINITION_BY_CODE = (
    1   => [ 'User-Name', 'UserName', 'UTF8String', undef ],
    25  => [ 'Class', 'Class', 'OctetString', undef ],
    27  => [ 'Session-Timeout', 'SessionTimeout', 'Unsigned32', undef ],
    33  => [ 'Proxy-State', 'ProxyState', 'OctetString', undef ],
    44  => [ 'Accounting-Session-Id', 'AccountingSessionId', 'OctetString', undef ],
    50  => [ 'Acct-Multi-Session-Id', 'AcctMultiSessionId', 'UTF8String', undef ],
    55  => [ 'Event-Timestamp', 'EventTimestamp', 'Time', undef ],
    85  => [ 'Acct-Interim-Interval', 'AcctInterimInterval', 'Unsigned32', undef ],
    257 => [ 'Host-IP-Address', 'HostIPAddress', 'Address', undef ],
    258 => [ 'Auth-Application-Id', 'AuthApplicationId', 'Unsigned32', undef ],
    259 => [ 'Acct-Application-Id', 'AcctApplicationId', 'Unsigned32', undef ],
    260 => [ 'Vendor-Specific-Application-Id', 'VendorSpecificApplicationId', 'Grouped', undef ],
    261 => [ 'Redirect-Host-Usage', 'RedirectHostUsage', 'Enumerated', undef ],
    262 => [ 'Redirect-Max-Cache-Time', 'RedirectMaxCacheTime', 'Unsigned32', undef ],
    263 => [ 'Session-Id', 'SessionId', 'UTF8String', undef ],
    264 => [ 'Origin-Host', 'OriginHost', 'DiamIdent', undef ],
    265 => [ 'Supported-Vendor-Id', 'SupportedVendorId', 'Unsigned32', undef ],
    266 => [ 'Vendor-Id', 'VendorId', 'Unsigned32', undef ],
    267 => [ 'Firmware-Revision', 'FirmwareRevision', 'Unsigned32', undef ],
    268 => [ 'Result-Code', 'ResultCode', 'Unsigned32', undef ],
    269 => [ 'Product-Name', 'ProductName', 'UTF8String', undef ],
    270 => [ 'Session-Binding', 'SessionBinding', 'Unsigned32', undef ],
    271 => [ 'Session-Server-Failover', 'SessionServerFailover', 'Enumerated', undef ],
    272 => [ 'Multi-Round-Time-Out', 'MultiRoundTimeOut', 'Unsigned32', undef ],
    273 => [ 'Disconnect-Cause', 'DisconnectCause', 'Enumerated', undef ],
    274 => [ 'Auth-Request-Type', 'AuthRequestType', 'Enumerated', undef ],
    276 => [ 'Auth-Grace-Period', 'AuthGracePeriod', 'Unsigned32', undef ],
    277 => [ 'Auth-Session-State', 'AuthSessionState', 'Enumerated', undef ],
    278 => [ 'Origin-State-Id', 'OriginStateId', 'Unsigned32', undef ],
    279 => [ 'Failed-AVP', 'FailedAVP', 'Grouped', undef ],
    280 => [ 'Proxy-Host', 'ProxyHost', 'DiamIdent', undef ],
    281 => [ 'Error-Message', 'ErrorMessage', 'UTF8String', undef ],
    282 => [ 'Route-Record', 'RouteRecord', 'DiamIdent', undef ],
    283 => [ 'Destination-Realm', 'DestinationRealm', 'DiamIdent', undef ],
    284 => [ 'Proxy-Info', 'ProxyInfo', 'Grouped', undef ],
    285 => [ 'Re-Auth-Request-Type', 'ReAuthRequestType', 'Enumerated', undef ],
    287 => [ 'Accounting-Sub-Session-Id', 'AccountingSubSessionId', 'Unsigned64', undef ],
    291 => [ 'Authorization-Lifetime', 'AuthorizationLifetime', 'Unsigned32', undef ],
    292 => [ 'Redirect-Host', 'RedirectHost', 'DiamURI', undef ],
    293 => [ 'Destination-Host', 'DestinationHost', 'DiamIdent', undef ],
    294 => [ 'Error-Reporting-Host', 'ErrorReportingHost', 'DiamIdent', undef ],
    295 => [ 'Termination-Cause', 'TerminationCause', 'Enumerated', undef ],
    296 => [ 'Origin-Realm', 'OriginRealm', 'DiamIdent', undef ],
    297 => [ 'Experimental-Result', 'ExperimentalResult', 'Grouped', undef ],
    298 => [ 'Experimental-Result-Code', 'ExperimentalResultCode', 'Unsigned32', undef ],
    299 => [ 'Inband-Security-Id', 'InbandSecurityId', 'Unsigned32', undef ],
    300 => [ 'E2E-Sequence', 'E2ESequence', 'Grouped', undef ],
    411 => [ 'CC-Correlation-Id', 'CCCorrelationId', 'OctetString' ],
    412 => [ 'CC-Input-Octets', 'CCInputOctets', 'Unsigned64' ],
    413 => [ 'CC-Money', 'CCMoney', 'Grouped' ],
    414 => [ 'CC-Output-Octets', 'CCOutputOctets', 'Unsigned64' ],
    415 => [ 'CC-Request-Number', 'CCRequestNumber', 'Unsigned32' ],
    416 => [ 'CC-Request-Type', 'CCRequestType', 'Enumerated' ],
    417 => [ 'CC-Service-Specific-Units', 'CCServiceSpecificUnits', 'Unsigned64' ],
    418 => [ 'CC-Session-Failover', 'CCSessionFailover', 'Enumerated' ],
    419 => [ 'CC-Sub-Session-Id', 'CCSubSessionId', 'Unsigned64' ],
    420 => [ 'CC-Time', 'CCTime', 'Unsigned32' ],
    421 => [ 'CC-Total-Octets', 'CCTotalOctets', 'Unsigned64' ],
    422 => [ 'Check-Balance-Result', 'CheckBalanceResult', 'Enumerated' ],
    423 => [ 'Cost-Information', 'CostInformation', 'Grouped' ],
    424 => [ 'Cost-Unit', 'CostUnit', 'UTF8String' ],
    425 => [ 'Currency-Code', 'CurrencyCode', 'Unsigned32' ],
    426 => [ 'Credit-Control', 'CreditControl', 'Enumerated' ],
    427 => [ 'Credit-Control-Failure-Handling', 'CreditControlFailureHandling', 'Enumerated' ],
    428 => [ 'Direct-Debiting-Failure-Handling', 'DirectDebitingFailureHandling', 'Enumerated' ],
    429 => [ 'Exponent', 'Exponent', 'Integer32' ],
    430 => [ 'Final-Unit-Indication', 'FinalUnitIndication', 'Grouped' ],
    431 => [ 'Granted-Service-Unit', 'GrantedServiceUnit', 'Grouped' ],
    432 => [ 'Rating-Group', 'RatingGroup', 'Unsigned32' ],
    433 => [ 'Redirect-Address-Type', 'RedirectAddressType', 'Enumerated' ],
    434 => [ 'Redirect-Server', 'RedirectServer', 'Grouped' ],
    435 => [ 'Redirect-Server-Address', 'RedirectServerAddress', 'UTF8String' ],
    436 => [ 'Requested-Action', 'RequestedAction', 'Enumerated' ],
    437 => [ 'Requested-Service-Unit', 'RequestedServiceUnit', 'Grouped' ],
    438 => [ 'Restriction-Filter-Rule', 'RestrictionFilterRule', 'IPFiltrRule' ],
    439 => [ 'Service-Identifier', 'ServiceIdentifier', 'Unsigned32' ],
    440 => [ 'Service-Parameter-Info', 'ServiceParameterInfo', 'Grouped' ],
    441 => [ 'Service-Parameter-Type', 'ServiceParameterType', 'Unsigned32' ],
    442 => [ 'Service-Parameter-Value', 'ServiceParameterValue', 'OctetString' ],
    443 => [ 'Subscription-Id', 'SubscriptionId', 'Grouped' ],
    444 => [ 'Subscription-Id-Data', 'SubscriptionIdData', 'UTF8String' ],
    445 => [ 'Unit-Value', 'UnitValue', 'Grouped' ],
    446 => [ 'Used-Service-Unit', 'UsedServiceUnit', 'Grouped' ],
    447 => [ 'Value-Digits', 'ValueDigits', 'Integer64' ],
    448 => [ 'Validity-Time', 'ValidityTime', 'Unsigned32' ],
    449 => [ 'Final-Unit-Action', 'FinalUnitAction', 'Enumerated' ],
    450 => [ 'Subscription-Id-Type', 'SubscriptionIdType', 'Enumerated' ],
    451 => [ 'Tariff-Time-Change', 'TariffTimeChange', 'Time' ],
    452 => [ 'Tariff-Change-Usage', 'TariffChangeUsage', 'Enumerated' ],
    453 => [ 'G-S-U-Pool-Identifier', 'GSUPoolIdentifier', 'Unsigned32' ],
    454 => [ 'CC-Unit-Type', 'CCUnitType', 'Enumerated' ],
    455 => [ 'Multiple-Services-Indicator', 'MultipleServicesIndicator', 'Enumerated' ],
    456 => [ 'Multiple-Services-Credit-Control', 'MultipleServicesCreditControl', 'Grouped' ],
    457 => [ 'G-S-U-Pool-Reference', 'GSUPoolReference', 'Grouped' ],
    458 => [ 'User-Equipment-Info', 'UserEquipmentInfo', 'Grouped' ],
    459 => [ 'User-Equipment-Info-Type', 'UserEquipmentInfoType', 'Enumerated' ],
    460 => [ 'User-Equipment-Info-Value', 'UserEquipmentInfoValue', 'OctetString' ],
    461 => [ 'Service-Context-Id', 'ServiceContextId', 'UTF8String' ],
    480 => [ 'Accounting-Record-Type', 'AccountingRecordType', 'Enumerated', undef ],
    483 => [ 'Accounting-Realtime-Required', 'AccountingRealtimeRequired', 'Enumerated', undef ],
    485 => [ 'Accounting-Record-Number', 'AccountingRecordNumber', 'Unsigned32', undef ],
    513 => [ 'Protocol', 'Protocol', 'Unsigned32' ],
    530 => [ 'Port', 'Port', 'Unsigned32' ],

    '10415:700'  => [ 'User-Identity', 'UserIdentity', 'Grouped' ],
    '10415:703'  => [ 'Data-Reference', 'DataReference', 'Enumerated' ],
    '10415:1000' => [ 'Bearer-Usage', 'BearerUsage', 'Enumerated' ],
    '10415:1001' => [ 'Charging-Rule-Install', 'ChargingRuleInstall', 'Grouped' ],
    '10415:1002' => [ 'Charging-Rule-Remove', 'ChargingRuleRemove', 'Grouped' ],
    '10415:1003' => [ 'Charging-Rule-Definition', 'ChargingRuleDefinition', 'Grouped' ],
    '10415:1004' => [ 'Charging-Rule-Base-Name', 'ChargingRuleBaseName', 'OctetString' ],
    '10415:1005' => [ 'Charging-Rule-Name', 'ChargingRuleName', 'OctetString' ],
    '10415:1006' => [ 'Event-Trigger', 'EventTrigger', 'Enumerated' ],
    '10415:1007' => [ 'Metering-Method', 'MeteringMethod', 'Enumerated' ],
    '10415:1008' => [ 'Offline', 'Offline', 'Enumerated' ],
    '10415:1009' => [ 'Online', 'Online', 'Enumerated' ],
    '10415:1010' => [ 'Precedence', 'Precedence', 'Unsigned32' ],
    '10415:1011' => [ 'Primary-CCF-Address', 'PrimaryCCFAddress', 'DiameterURI' ],
    '10415:1012' => [ 'Primary-OCS-Address', 'PrimaryOCSAddress', 'DiameterURI' ],
    '10415:1013' => [ 'RAT-Type', 'RATType', 'Enumerated' ],
    '10415:1014' => [ 'Reporting-Level', 'ReportingLevel', 'Enumerated' ],
    '10415:1015' => [ 'Secondary-CCF-Address', 'SecondaryCCFAddress', 'DiameterURI' ],
    '10415:1016' => [ 'Secondary-OCS-Address', 'SecondaryOCSAddress', 'DiameterURI' ],
    '10415:1017' => [ 'TFT-Filter', 'TFTFilter', 'IPFilterRule' ],
    '10415:1018' => [ 'TFT-Packet-Filter-Information', 'TFTPacketFilterInformation', 'Grouped' ],
    '10415:1019' => [ 'ToS-Traffic-Class', 'ToSTrafficClass', 'OctetString' ],
    '10415:2901' => [ 'Policy-Counter-Identifier', 'PolicyCounterIdentifier', 'UTF8String' ],
    '10415:2902' => [ 'Policy-Counter-Status', 'PolicyCounterStatus', 'UTF8String' ],
    '10415:2903' => [ 'Policy-Counter-Status-Report', 'PolicyCounterStatusReport', 'Grouped' ],
    '10415:2904' => [ 'SL-Request-Type', 'SLRequestType', 'Enumerated' ],
);


foreach my $code (keys %AVP_DEFINITION_BY_CODE) {
    $AVP_CLASS_CODE{'Diameter::Message::AVP::' . $AVP_DEFINITION_BY_CODE{$code}->[1]} = $code;
}

};


# For each AVP data type, the data are stored in their encoded format (and available as such).
#  These methods encode data from text or number to underlying type.  These methods are passed
#  the decoded version and return the encoded version.  Methods may die() with message
#  starting with "Invalid AVP Value Exception" if the value provided is invalid.  The type
#  'Grouped' is special.  It must receive a listref of AVPs and it simply returns the same.

my %AVP_DATA_TYPE_ENCODERS = (
 # IPv4 or IPv6 address as text.
 # XXX: NOTE: Currently only supports IPv4
 'Address'      => sub {
    my $addr = shift;
    my @octets = split /\./, $addr;

    die "Invalid AVP Value Exception"   unless (grep { /^\d+$/ && $_ >= 0 && $_ <= 255 } @octets) == 4;

    return pack "nN", 0x0001, ($octets[0] << 24) | ($octets[1] << 16) | ($octets[2] << 8) | $octets[3];
 },

 # plain text, e.g., pcrf.f5net.com
 'DiamIdent'    => sub {
    return pack "A*", shift;
 },

 'DiamURI'      => sub {
    return pack "A*", shift;
  },

 # encoded as uint32
 'Enumerated'   => sub {
    return pack "N", shift;
  },

 'Grouped'      => sub {
    my $g = shift;
    die "Invalid AVP Value Exception"   unless ref $g eq "ARRAY" && (grep { $_->isa( 'Diameter::Message::AVP' ) } @{$g}) == @{$g};
    return $g;
  },

 # already encoded
 'OctetString'  => sub {
    return shift;
  },

 # provide as unix epoch time
 'Time'         => sub {
    return pack "N", shift;
  },

 # utf-8 encoded string
 'UTF8String'   => sub {
    return pack "A*", shift;
  },

 # uint32
 'Unsigned32'   => sub {
    return pack "N", shift;
  },

 # uint64
 'Unsigned64'   => sub {
    return pack "NN", shift;
  },
);


# Decoders for "decode" method.  Methods are supplied raw (encoded) value.  If the encoded value
#  can't be decoded, die() with message starting with "Invalid Encoded AVP Exception".
#
my %AVP_DATA_TYPE_DECODERS = (
 # IPv4 or IPv6 address as text.
 # XXX: NOTE: Currently only supports IPv4
 'Address'      => sub {
    my $raw = shift;
    my $family = unpack "n", $raw;

    if ($family == 0x0001) { # IPv4
        my $enaddr = unpack "N", substr $raw, 2;
        return join ".", unpack( "CCCC", $enaddr );
    }
    else {
        die "Invalid Encoded AVP Exception";
    }
 },

 # plain text, e.g., pcrf.f5net.com
 'DiamIdent'    => sub {
    return unpack "A*", shift;
 },

 'DiamURI'      => sub {
    return unpack "A*", shift;
  },

 # encoded as uint32
 'Enumerated'   => sub {
    return unpack "N", shift;
  },

 'Grouped'      => sub {
    return shift;
  },

 'OctetString'  => sub {
    return shift;
  },

 # provide as unix epoch time
 'Time'         => sub {
    return unpack "N", shift;
  },

 # utf-8 encoded string
 'UTF8String'   => sub {
    return unpack "A*", shift;
  },

 # uint32
 'Unsigned32'   => sub {
    return unpack "N", shift;
  },

 # uint64
 'Unsigned64'   => sub {
    return unpack "NN", shift;
  },
);




# Blessed data structure for Diameter::Message::AVP is listref.  These are the elements
#
use constant {
    AVP_CODE                => 0,
    AVP_FLAGS               => 1,
    AVP_LENGTH              => 2,   # excludes AVP_DATA_PAD_LENGTH
    AVP_VENDOR_ID_PRESENT   => 3,
    AVP_VENDOR_ID           => 4,
    AVP_DATA                => 5,
    AVP_ENCODED             => 6,
    AVP_DATA_PAD_LENGTH     => 7,
    AVP_DATA_DECODED        => 8,
};




# $avp = Diameter::Message::AVP->new( Code => $code, VendorId => $vendorid, IsMandatory => 1|0, Flags => $flags,
#                                     EncodedData => $encoded_data, Data => $data );
#
# Provide AVP code ($code), which is required.  If $vendorid is provided and isn't undef, set V flag and add
# VendorID field.  If IsMandatory is true, set M flag.  If $flags provided, override IsMandatory based on that.
# If $flags provided and $vendorid is provided, set V flag.  $flags must be packed flags field, which means
# one unsigned byte, from high-order bit: V, V, P followed by 5 zeroes (this is how the field is stored internally).
# $encoded_data is trusted as encoded data.  $data is decoded data (which will be encoded for storage).  If $data
# and $encoded_data are set simultaneously, only $encoded_data is honored
#
# $code and either $data or $encoded_data are required.  By default $vendorid is undef (not set) and IsMandatory is 0.
#
# If $data (or $encoded_data) is a listref, then it must contain only Diameter::Message::AVP or sub-types

sub new {
    my $class = shift;
    my %params = @_;

    my $code = $params{Code};
    my $vendorid = (exists $params{VendorId} ? $params{VendorId} : undef);

    if ($class eq 'Diameter::Message::AVP') {
        if (defined $vendorid) {
            if (exists $AVP_DEFINITION_BY_CODE{"$vendorid:$code"}) {
                my $class_base = $AVP_DEFINITION_BY_CODE{"$vendorid:$code"}->[1];
                my $new_class = 'Diameter::Message::AVP::' . $class_base;
                return $new_class->new( %params );
            }
        }
        elsif (exists $AVP_DEFINITION_BY_CODE{$code}) {
            my $class_base = $AVP_DEFINITION_BY_CODE{$code}->[1];
            my $new_class = 'Diameter::Message::AVP::' . $class_base;
            return $new_class->new( %params );
        }
    }
    elsif (exists $AVP_CLASS_CODE{$class}) {
        if ($AVP_CLASS_CODE{$class} =~ /^(\d+):(\d+)$/) {
            $vendorid = $1;
            $code = $2;
        }
        else {
            $vendorid = undef;
            $code = $AVP_CLASS_CODE{$class};
        }
    }

    unless (defined $code && $code =~ /^\d+$/ && $code >= 0 && $code <= 0xffffffff) {
        die "Invalid AVP Code Exception: ($code)";
    }

    if (!exists $params{IsMandatory} && defined $params{IsMandatory})    { $params{IsMandatory} = 0 }

    my $packed_flags;
    if (exists $params{Flags} && defined $params{Flags}) {
        $packed_flags = pack "C", unpack( "C", $params{Flags} );
    }
    else {
        $packed_flags = ($params{IsMandatory} ? 0x40 : 0x00);
    }

    if (defined $vendorid) {
        $packed_flags |= 0x80;
    }

    my $avp_length = 8 + (defined $vendorid ? 4 : 0);

    my $data_pad_bytes = 0;

    # even if non-encoded data are provided, we don't store it.  This is because
    # the encoded version may differ from the provided decoded version if there
    # was an error in the data provided.  For example, if a 64-bit integer is
    # supplied for something that is a 32-bit data type, the encoded version will
    # include only the low 32-bits
    #
    my $encoded_data;

    if (exists $params{EncodedData}) {
        die "Invalid AVP Data Exception"    unless defined $params{EncodedData};
        $encoded_data = $params{EncodedData};
    }
    elsif (exists $params{Data}) {
        my $key = (defined $vendorid ? "$vendorid:$code" : $code);

        if (exists $AVP_DEFINITION_BY_CODE{$key}) {
            my $data_type = $AVP_DEFINITION_BY_CODE{$key}->[2];
            $encoded_data = $AVP_DATA_TYPE_ENCODERS{$data_type}->( $params{Data} );
        }
        else {
            $encoded_data = $params{Data};
        }
    }
    else {
        die "Invalid AVP Data Exception";
    }

    if (ref $encoded_data eq "ARRAY") {
        foreach my $subavp (@{ $params{Data} }) {
            # for calculation of the group AVP overall length, it must include padding for contained AVPs
            die "Invalid AVP Data"  unless ref $subavp && $subavp->isa( 'Diameter::Message::AVP' );
            $avp_length += $subavp->[AVP_LENGTH] + $subavp->[AVP_DATA_PAD_LENGTH];
        }
    }
    else {
        # AVPs must be extended by null padding to 32-bit word alignment, but the length does not include the padding
        my $data_len = CORE::length( $encoded_data );

        my $pm = CORE::length( $encoded_data ) % 4;
        $data_pad_bytes = ($pm == 0 ? 0 : 4 - $pm);

        $avp_length += $data_len;
    }

    my $self = bless [
        $code,
        $packed_flags,
        $avp_length,
        (defined $vendorid ? 1 : 0),
        $vendorid,
        $encoded_data,
        undef,
        $data_pad_bytes,
        undef,
    ], $class;

    return $self;
}


sub code            { return shift->[AVP_CODE] }
sub flags           { return (shift->[AVP_FLAGS] >> 5) & 0x07 }
sub length          { return shift->[AVP_LENGTH] }
sub padded_length   { my $s = shift; return $s->[AVP_LENGTH] + $s->[AVP_DATA_PAD_LENGTH] }
sub has_vendor_id   { return shift->[AVP_VENDOR_ID_PRESENT] }
sub vendor_id       { return shift->[AVP_VENDOR_ID] }
sub raw_data        { return shift->[AVP_DATA] }

sub data {
    my $self = shift;

    if (!defined $self->[AVP_DATA_DECODED]) {
        if (exists $AVP_DEFINITION_BY_CODE{$self->[AVP_CODE]}) {
            my $data_type = $AVP_DEFINITION_BY_CODE{$self->[AVP_CODE]}->[2];
            $self->[AVP_DATA_DECODED] = $AVP_DATA_TYPE_DECODERS{$data_type}->( $self->[AVP_DATA] );
        }
    }

    return $self->[AVP_DATA_DECODED];
}


sub clean_encode {
    my $self = shift;
    $self->[AVP_ENCODED] = undef;
    return $self->encode();
}


sub encode {
    my $self = shift;

    if (! defined $self->[AVP_ENCODED]) {
        if ($self->[AVP_VENDOR_ID_PRESENT]) {
            $self->[AVP_ENCODED] = pack( "NNN", $self->[AVP_CODE],
                                                (($self->[AVP_FLAGS] & 0xff) << 24) | ($self->[AVP_LENGTH] & 0x00ffffff),
                                                $self->[AVP_VENDOR_ID] );
        }
        else {
            $self->[AVP_ENCODED] = pack( "NN", $self->[AVP_CODE],
                                               (($self->[AVP_FLAGS] & 0xff) << 24) | ($self->[AVP_LENGTH] & 0x00ffffff) );
                                            
        }

        if (ref $self->[AVP_DATA] eq "ARRAY") {
            foreach my $subavp (@{ $self->[AVP_DATA] }) {
                $self->[AVP_ENCODED] .= $subavp->encode;
            }
        }
        else {
            $self->[AVP_ENCODED] .= $self->[AVP_DATA] . ($self->[AVP_DATA_PAD_LENGTH] ? (chr(0) x $self->[AVP_DATA_PAD_LENGTH]) : '');
        }
    }

    return $self->[AVP_ENCODED];
}


sub decode {
    my $class  = shift;
    my $stream = shift;

    die "Malformed AVP Exception\n" unless CORE::length $stream >= 8;

    my ($code, $hdr2) = unpack( "NN", $stream );

    my $flags = ($hdr2 >> 24) & 0xff;
    my $length = $hdr2 & 0x00ffffff;

    my $pm = CORE::length( $stream ) % 4;
    my $data_pad_bytes = ($pm == 0 ? 0 : 4 - $pm);

    die "Malformed AVP Exception\n" unless CORE::length( $stream ) == $length || CORE::length( $stream ) == $length + $data_pad_bytes;

    my $encoded = $stream;  # copy because we substr bits out of $stream, but want to keep $encoded

    substr $stream, 0, 8, '';

    my $vendor_id;
    if ($flags & 0x80) {
        $vendor_id = unpack( "N", $stream );
        substr $stream, 0, 4, '';
    }

    my $data;

    my $key = (defined $vendor_id ? "$code:$vendor_id" : $code);

    if (defined $AVP_DEFINITION_BY_CODE{$key} && $AVP_DEFINITION_BY_CODE{$key}->[2] eq 'Grouped') {
        while ($stream ne "") {
            die "Malformed AVP Exception\n"     unless CORE::length $stream >= 8;

            my ($next_avp_code, $next_hdr1) = unpack( "NN", $stream );

            my $next_avp_len = $next_hdr1 & 0x00ffffff;

            die "Malformed AVP Exception\n"     unless CORE::length $stream >= $next_avp_len;

            my $avp = Diameter::Message::AVP->decode( substr $stream, 0, $next_avp_len, '' );
            push @{ $data }, $avp;

            substr $stream, 0, $avp->padded_length - $avp->length, '';
        }
    }
    else {
        $data = $stream;
    }

    $class = (exists $AVP_DEFINITION_BY_CODE{$key} ? 'Diameter::Message::AVP::' . $AVP_DEFINITION_BY_CODE{$key}->[1] : 'Diameter::Message::AVP');

    $encoded .= (chr(0) x $data_pad_bytes);

    return bless [
        $code,                  # AVP_CODE
        $flags,                 # AVP_FLAGS
        $length,                # AVP_LENGTH
        defined $vendor_id,     # AVP_VENDOR_ID_PRESENT
        $vendor_id,             # AVP_VENDOR_ID
        $data,                  # AVP_DATA
        $encoded,               # AVP_ENCODED
        $data_pad_bytes,        # AVP_DATA_PAD_LENGTH
        undef,                  # AVP_DATA_DECODED
    ], $class;
}


package Diameter::Message::AVP::AccountingRealtimeRequired;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AccountingRecordNumber;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AccountingRecordType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AccountingSessionId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AccountingSubSessionId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AcctApplicationId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AcctInterimInterval;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AcctMultiSessionId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AuthApplicationId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AuthGracePeriod;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AuthRequestType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AuthSessionState;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::AuthorizationLifetime;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::BearerUsage;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCCorrelationId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCInputOctets;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCMoney;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCOutputOctets;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCRequestNumber;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCRequestType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCServiceSpecificUnits;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCSessionFailover;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCSubSessionId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCTime;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCTotalOctets;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CCUnitType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ChargingRuleBaseName;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ChargingRuleDefinition;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ChargingRuleInstall;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ChargingRuleName;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ChargingRuleRemove;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CheckBalanceResult;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::Class;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CostInformation;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CostUnit;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CreditControl;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CreditControlFailureHandling;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::CurrencyCode;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::DestinationHost;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::DestinationRealm;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::DirectDebitingFailureHandling;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::DisconnectCause;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::E2ESequence;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ErrorMessage;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ErrorReportingHost;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::EventTimestamp;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::EventTrigger;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ExperimentalResult;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ExperimentalResultCode;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::Exponent;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::FailedAVP;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::FinalUnitAction;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::FinalUnitIndication;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::FirmwareRevision;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::GSUPoolIdentifier;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::GSUPoolReference;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::GrantedServiceUnit;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::HostIPAddress;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::InbandSecurityId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::MeteringMethod;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::MultiRoundTimeOut;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::MultipleServicesCreditControl;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::MultipleServicesIndicator;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::Offline;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::Online;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::OriginHost;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::OriginRealm;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::OriginStateId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::Precedence;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::PrimaryCCFAddress;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::PrimaryOCSAddress;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ProductName;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ProxyHost;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ProxyInfo;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ProxyState;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RATType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RatingGroup;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ReAuthRequestType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RedirectAddressType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RedirectHost;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RedirectHostUsage;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RedirectMaxCacheTime;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RedirectServer;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RedirectServerAddress;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ReportingLevel;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RequestedAction;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RequestedServiceUnit;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RestrictionFilterRule;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ResultCode;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::RouteRecord;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SecondaryCCFAddress;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SecondaryOCSAddress;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ServiceContextId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ServiceIdentifier;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ServiceParameterInfo;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ServiceParameterType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ServiceParameterValue;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SessionBinding;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SessionId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SessionServerFailover;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SessionTimeout;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SubscriptionId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SubscriptionIdData;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SubscriptionIdType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SupportedVendorId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::TFTFilter;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::TFTPacketFilterInformation;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::TariffChangeUsage;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::TariffTimeChange;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::TerminationCause;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ToSTrafficClass;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::UnitValue;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::UsedServiceUnit;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::UserEquipmentInfo;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::UserEquipmentInfoType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::UserEquipmentInfoValue;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::UserName;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ValidityTime;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::ValueDigits;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::VendorId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::VendorSpecificApplicationId;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::Protocol;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::Port;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::UserIdentity;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::DataReference;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::SLRequestType;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::PolicyCounterIdentifier;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::PolicyCounterStatus;
use parent -norequire, qw/Diameter::Message::AVP/;

package Diameter::Message::AVP::PolicyCounterStatusReport;
use parent -norequire, qw/Diameter::Message::AVP/;


1;
