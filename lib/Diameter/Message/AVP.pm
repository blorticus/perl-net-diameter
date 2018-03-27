package Diameter::Message::AVP;

use strict;
use warnings;

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
 'DiameterIdentity'    => sub {
    return pack "A*", shift;
 },

 'DiameterURI'      => sub {
    return pack "A*", shift;
  },

 # encoded as uint32
 'Enumerated'   => sub {
    return pack "N", shift;
  },

 'Float32'     => sub {
    return pack "f", shift;
  },

 'Float64'     => sub {
    return pack "d", shift;
  },

 'Grouped'      => sub {
    my $g = shift;
    die "Invalid AVP Value Exception"   unless ref $g eq "ARRAY" && (grep { $_->isa( 'Diameter::Message::AVP' ) } @{$g}) == @{$g};
    return $g;
  },

 'IPFilterRule' => sub {
    return shift;
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
 'DiameterIdentity'    => sub {
    return unpack "A*", shift;
 },

 'DiameterURI'      => sub {
    return unpack "A*", shift;
  },

 # encoded as uint32
 'Enumerated'   => sub {
    return unpack "N", shift;
  },

 Float32       => sub {
    return unpack "f", shift;
  },

 Float64       => sub {
    return unpack "d", shift;
  },

 'Grouped'      => sub {
    return shift;
  },

 'IPFilterRule' => sub {
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
# NOTE: this type is extended in Diameter::Dictionary.  If changes are made here, they
# must be reflected in that class definition, too.  That subclass extends this by adding
# to the blessed listref, so it depends on AVP__LAST_ELEMENT being equal to the index
# of the last AVP_* element.
#
use constant {
    AVP_CODE                => 0,
    AVP_FLAGS               => 1,
    AVP_LENGTH              => 2,   # excludes AVP_DATA_PAD_LENGTH
    AVP_VENDOR_ID           => 3,
    AVP_TYPED_DATA          => 4,
    AVP_RAW_DATA            => 5,
    AVP_ENCODED             => 6,
    AVP_DATA_PAD_LENGTH     => 7,
    AVP_DATA_TYPE           => 8,

    AVP__LAST_ELEMENT       => 8,
};




# $avp = Diameter::Message::AVP->new( Code => $code, VendorId => $vendorid, IsMandatory => 1|0, Flags => $flags,
#                                     EncodedData => $encoded_data, Data => $data, Type => $type );
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
#
# $type must be one of: Address DiameterIdentity DiameterURI Enumerated Float32 Float64 Grouped Integer32 Integer64
#   OctetString Time Unsigned32 Unsigned64 UTF8String
# If unspecified, it will be OctetString
#

sub new {
    my $class = shift;
    my %params = @_;

    my $code = $params{Code};
    my $vendorid = (exists $params{VendorId} && defined $params{VendorId} && $params{VendorId} ne "" ? $params{VendorId} : 0);
    my $data_type = (exists $params{DataType} && defined $params{DataType} && $params{DataType} ne "" ? $params{DataType} : "OctetString");

    if (!exists $params{IsMandatory} && defined $params{IsMandatory})    { $params{IsMandatory} = 0 }

    if (!exists $AVP_DATA_TYPE_ENCODERS{$data_type}) {
        die "Invalid AVP Data Type Exception: $data_type\n";
    }

    unless (defined $code && $code =~ /^\d+$/ && $code >= 0 && $code <= 0xffffffff) {
        die "Invalid AVP Code Exception: ($code)";
    }

    unless (defined $vendorid && $vendorid =~ /^\d+$/ && $vendorid >= 0 && $vendorid <= 0xffffffff) {
        die "Invalid AVP VendorId Exception: ($vendorid)";
    }

    my $packed_flags;
    if (exists $params{Flags} && defined $params{Flags}) {
        $packed_flags = pack "C", unpack( "C", $params{Flags} );
    }
    else {
        $packed_flags = ($params{IsMandatory} ? 0x40 : 0x00);
    }

    if ($vendorid != 0) {
        $packed_flags |= 0x80;
    }

    my $avp_length = 8 + ($vendorid ? 4 : 0);

    # If (typed) Data and EncodedData are provided, ignore Data, and create it from EncodedData and Type.
    # If only Data exists, create EncodedData, the decode it to replace Data.  We do this because it is possible
    # that the encoding truncates or alters data (e.g., if a number > 2**32-1 is provided for an Unsigned32).
    #
    my ($encoded_data, $typed_data);

    if (exists $params{EncodedData}) {
        die "Invalid AVP Data Exception"    unless defined $params{EncodedData};
        $encoded_data = $params{EncodedData};
        $typed_data   = $AVP_DATA_TYPE_DECODERS{$data_type}->( $encoded_data );
    }
    elsif (exists $params{Data}) {
        $encoded_data = $AVP_DATA_TYPE_ENCODERS{$data_type}->( $params{Data} );
        $typed_data   = $AVP_DATA_TYPE_DECODERS{$data_type}->( $encoded_data );
    }
    else {
        die "Invalid AVP Data Exception: no data value provided";
    }

    my $data_pad_bytes = 0;

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
        $code,                          # AVP_CODE
        $packed_flags,                  # AVP_FLAGS
        $avp_length,                    # AVP_LENGTH
        $vendorid,                      # AVP_VENDOR_ID
        $typed_data,                    # AVP_TYPED_DATA
        $encoded_data,                  # AVP_RAW_DATA
        undef,                          # AVP_ENCODED
        $data_pad_bytes,                # AVP_DATA_PAD_LENGTH
        $data_type,                     # AVP_DATA_TYPE
    ], $class;

    return $self;
}


sub code            { return shift->[AVP_CODE] }
sub flags           { return (shift->[AVP_FLAGS] >> 5) & 0x07 }
sub length          { return shift->[AVP_LENGTH] }
sub padded_length   { my $s = shift; return $s->[AVP_LENGTH] + $s->[AVP_DATA_PAD_LENGTH] }
sub has_vendor_id   { my $s = shift; return ($s->[AVP_VENDOR_ID] ? 1 : 0); }
sub vendor_id       { return shift->[AVP_VENDOR_ID] }
sub raw_data        { return shift->[AVP_RAW_DATA] }

sub data {
    my $self = shift;
    return (defined $self->[AVP_TYPED_DATA] ? $self->[AVP_TYPED_DATA] : $self->[AVP_RAW_DATA]);
}


sub clean_encode {
    my $self = shift;
    $self->[AVP_ENCODED] = undef;
    return $self->encode();
}


sub encode {
    my $self = shift;

    if (! defined $self->[AVP_ENCODED]) {
        if ($self->[AVP_VENDOR_ID] != 0) {
            $self->[AVP_ENCODED] = pack( "NNN", $self->[AVP_CODE],
                                                (($self->[AVP_FLAGS] & 0xff) << 24) | ($self->[AVP_LENGTH] & 0x00ffffff),
                                                $self->[AVP_VENDOR_ID] );
        }
        else {
            $self->[AVP_ENCODED] = pack( "NN", $self->[AVP_CODE],
                                               (($self->[AVP_FLAGS] & 0xff) << 24) | ($self->[AVP_LENGTH] & 0x00ffffff) );
        }

        if (ref $self->[AVP_TYPED_DATA] eq "ARRAY") {
            foreach my $subavp (@{ $self->[AVP_TYPED_DATA] }) {
                $self->[AVP_ENCODED] .= $subavp->encode;
            }
        }
        else {
            $self->[AVP_ENCODED] .= $self->[AVP_RAW_DATA] . ($self->[AVP_DATA_PAD_LENGTH] ? (chr(0) x $self->[AVP_DATA_PAD_LENGTH]) : '');
        }
    }

    return $self->[AVP_ENCODED];
}


sub decode {
    my $class  = shift;
    my $stream = shift;
    my %params = @_;

    die "Malformed AVP Exception\n" unless CORE::length $stream >= 8;

    my ($code, $hdr2) = unpack( "NN", $stream );

    my $flags = ($hdr2 >> 24) & 0xff;
    my $length = $hdr2 & 0x00ffffff;

    my $pm = CORE::length( $stream ) % 4;
    my $data_pad_bytes = ($pm == 0 ? 0 : 4 - $pm);

    die "Malformed AVP Exception\n" unless CORE::length( $stream ) == $length || CORE::length( $stream ) == $length + $data_pad_bytes;

    my $encoded = $stream;  # copy because we substr bits out of $stream, but want to keep $encoded

    substr $stream, 0, 8, '';

    my $vendor_id = 0;
    if ($flags & 0x80) {
        $vendor_id = unpack( "N", $stream );
        substr $stream, 0, 4, '';
    }

    my $raw_data = substr $stream, 0, $length, '';

    my $typed_data;
    if (exists $params{InfoMap} && defined $params{InfoMap} && ref $params{InfoMap} eq "HASH") {
        if (exists $params{InfoMap}->{"$vendor_id:$code"}) {
            $typed_data = $AVP_DATA_TYPE_DECODERS{$params{InfoMap}->{"$vendor_id:$code"}->{Type}}->( $raw_data );
        }
    }

    $encoded .= (chr(0) x $data_pad_bytes);

    return bless [
        $code,                  # AVP_CODE
        $flags,                 # AVP_FLAGS
        $length,                # AVP_LENGTH
        $vendor_id,             # AVP_VENDOR_ID
        $typed_data,            # AVP_TYPED_DATA
        $raw_data,              # AVP_RAW_DATA
        $encoded,               # AVP_ENCODED
        $data_pad_bytes,        # AVP_DATA_PAD_LENGTH
        'OctetString',          # AVP_DATA_TYPE
    ], $class;
}


1;
