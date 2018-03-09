package Diameter::Message;

use strict;
use warnings;

use Diameter::Message::AVP;
use Exporter 'import';

=head1 NAME

Diameter::Message - Interface describing a Diameter Message, with encoders and decoders

=head1 SYNOPSIS

 $m = Diameter::Message->decode( $byte_stream );

 $is_req = $m->is_request;
 $code   = $m->command_code;

 foreach my $avp ($m->avps) {
    ...
 }

 $m = Diameter::Message->new( 
    IsRequest   => 1,
    CommandCode => 306,
    HopByHopId  => 1234,
    EndToEndId  => 987654,
    Avps        => [
        Diameter::Message::AVP->new( Code => 260, IsMandatory => 1, Data => [
            Diameter::Message::AVP->new( Code => 276, IsMandatory => 1, Data => 16777217 ),
        ],
        Diameter::Message::AVP->new( Code => 277, IsMandatory => 1, Data => 1 ),
        Diameter::Message::AVP->new( Code => 264, IsMandatory => 1, Data => 'test.example.com' ),
        Diameter::Message::AVP->new( Code => 296, IsMandatory => 1, Data => 'example.com' ),
        Diameter::Message::AVP->new( Code => 283, IsMandatory => 1, Data => 'remote.com' ),
        Diameter::Message::AVP->new( Code => 703, VendorId => 10415, IsMandatory => 1, Data => 22 ),
        Diameter::Message::AVP->new( Code => 700, VendorId => 10415, IsMandatory => 1, Data => [
            Diameter::Message::AVP->new( Code => 601, VendorId => 10415, "sip:joe@example.com" ),
        ],
    ]
 );

 $socket->send( $m->encode );

=cut

our @EXPORT_OK = qw(length_of_next_complete_diameter_message_in);

sub length_of_next_complete_diameter_message_in {
    my $buffer_sr = shift;

    if (length $$buffer_sr >= 4) {
        my $length = substr( $$buffer_sr, 0, 4 ) & 0x00ffffff;
        return $length if length $$buffer_sr >= $length;
    }

    return 0;
}


# Diameter::Message is a blessed list ref.  These are the fields for that list ref
#
use constant {
    VERSION             => 0,
    MSG_LENGTH          => 1,
    FLAGS               => 2,
    COMMAND_CODE        => 3,
    APPLICATION_ID      => 4,
    HOP_BY_HOP_ID       => 5,
    END_TO_END_ID       => 6,
    AVP_LIST            => 7,
    ENCODED             => 8,
};


# Configuration for message subtypes.  These correspond to Diameter::Message::$name where $name is the
# key in this table.  The value is a hashref of ("Code", "ApplicationId", "IsRequest", "RequiredAVPs", "OptionalAVPs").
# The AVPs are listref by AVP class basename.  If ApplicationId is set to undef, then no value is set and a value must be provided
# in the constructor parameters.
#
# Possible count values are '1' or '1*' meaning exactly one or one or more, respectively
#
my %TYPE_DEFS_BY_CLASS;


# Indexed by Code, hashref indexed by IsRequest (that is, a 0 or a 1), value is the corresponding class
# Autopopulated on load to avoid necessity to duplicate configuration
my %CODE_TO_CLASS;


BEGIN {
%TYPE_DEFS_BY_CLASS = (
    'Diameter::Message::CER'     => {
        Code            => 257,
        ApplicationId   => 0,
        IsRequest       => 1,
        RequiredAVPs    => [
            [ OriginHost                    => '1'  ],
            [ OriginRealm                   => '1'  ],
            [ HostIPAddress                 => '1*' ],
            [ VendorId                      => '1', ],
            [ ProductName                   => '1', ],
        ],
        OptionalAVPs    => [
            [ OriginStateId                 => '1'  ],
            [ SupportedVendorId             => '1*' ],
            [ AuthApplicationId             => '1*' ],
            [ InbandSecurityId              => '1*' ],
            [ AcctApplicationId             => '1*' ],
            [ VendorSpecificApplicationId   => '1*' ],
            [ FirmwareRevision              => '1'  ],
        ],
    },
    'Diameter::Message::CEA'     => {
        Code            => 257,
        ApplicationId   => 0,
        IsRequest       => 0,
        RequiredAVPs    => [
            [ ResultCode                    => '1'  ],
            [ OriginHost                    => '1'  ],
            [ OriginRealm                   => '1'  ],
            [ HostIPAddress                 => '1*' ],
            [ VendorId                      => '1'  ],
            [ ProductName                   => '1'  ],
        ],
        OptionalAVPs    => [
            [ OriginStateId                 => '1'  ],
            [ ErrorMessage                  => '1'  ],
            [ FailedAVP                     => '1'  ],
            [ SupportedVendorId             => '1*' ],
            [ AuthApplicationId             => '1*' ],
            [ InbandSecurityId              => '1*' ],
            [ AcctApplicationId             => '1*' ],
            [ VendorSpecificApplicationId   => '1*' ],
            [ FirmwareRevision              => '1'  ],
        ],
    },

    'Diameter::Message::DWR'     => {
        Code            => 280,
        ApplicationId   => 0,
        IsRequest       => 1,
        RequiredAVPs    => [
            [ OriginHost                    => '1'  ],
            [ OriginRealm                   => '1'  ],
        ],
        OptionalAVPs    => [
            [ OriginStateId                 => '1'  ],
        ],
    },
    'Diameter::Message::DWA'     => {
        Code            => 280,
        ApplicationId   => 0,
        IsRequest       => 0,
        RequiredAVPs    => [
            [ ResultCode                    => '1'  ],
            [ OriginHost                    => '1'  ],
            [ OriginRealm                   => '1'  ],
        ],
        OptionalAVPs    => [
            [ ErrorMessage                  => '1'  ],
            [ FailedAVP                     => '1'  ],
            [ OriginStateId                 => '1'  ],
        ],
    },

    'Diameter::Message::SLR'    => {
        Code            => 8388635,
        ApplicationId   => 16777302,
        IsRequest       => 1,
        RequiredAVPs    => [
            [ SessionId                     => '1'  ],
            [ AuthApplicationId             => '1'  ],
            [ OriginHost                    => '1'  ], 
            [ OriginRealm                   => '1'  ],
            [ DestinationRealm              => '1'  ],
            [ SLRequestType                 => '1'  ],
        ],
    },

    'Diameter::Message::SLA'    => {
        Code            => 8388635,
        ApplicationId   => 16777302,
        IsRequest       => 0,
        RequiredAVPs    => [
            [ SessionId                     => '1'  ],
            [ AuthApplicationId             => '1'  ],
            [ OriginHost                    => '1'  ], 
            [ OriginRealm                   => '1'  ],
        ],
        OptionalAVPs    => [
            [ ResultCode                    => '1'  ],
        ],
    },

    'Diameter::Message::SSNR'    => {
        Code            => 8388636,
        ApplicationId   => 16777302,
        IsRequest       => 1,
        RequiredAVPs    => [
            [ SessionId                     => '1'  ],
            [ OriginHost                    => '1'  ], 
            [ OriginRealm                   => '1'  ],
            [ DestinationHost               => '1'  ],
            [ DestinationRealm              => '1'  ],
            [ AuthApplicationId             => '1'  ],
        ],
    },

    'Diameter::Message::SSNA'    => {
        Code            => 8388636,
        ApplicationId   => 16777302,
        IsRequest       => 0,
        RequiredAVPs    => [
            [ SessionId                     => '1'  ],
            [ OriginHost                    => '1'  ], 
            [ OriginRealm                   => '1'  ],
        ],
        OptionalAVPs    => [
            [ ResultCode                    => '1'  ],
        ],
    },

);


foreach my $class (keys %TYPE_DEFS_BY_CLASS) {
    my $hr = $TYPE_DEFS_BY_CLASS{$class};
    $CODE_TO_CLASS{$hr->{Code}}{$hr->{IsRequest}} = $class;
}

};


my %MESSAGE_TYPE_TO_CLASS = (
    CER     => 'Diameter::Message::CER',
    CEA     => 'Diameter::Message::CEA',
    DWR     => 'Diameter::Message::DWR',
    DWA     => 'Diameter::Message::DWA',
    SLR     => 'Diameter::Message::SLR',
    SLA     => 'Diameter::Message::SLA',
    SSNR    => 'Diameter::Message::SSNR',
    SSNA    => 'Diameter::Message::SSNA',
);


#
# $p = Diameter::Message->new( IsRequest => 1|0, IsError => 1|0, IsProxyable => 1|0, CommandCode => $cc,
#                              AppId => $aid, HopByHopId => $hhid, EndToEndId => $eeid,
#                              Avps => \@avps, Flags => $flags );
#
# where @avps is listrefs of Diameter::Message::AVP objects
#

sub new {
    my $class = shift;
    my %params = @_;

    $params{IsError}    = 0         unless exists $params{IsError}    && defined $params{IsError}    && $params{IsError} ne '';
    $params{HopByHopId} = 0         unless exists $params{HopByHopId} && defined $params{HopByHopId} && $params{HopByHopId} ne '';
    $params{EndToEndId} = 0         unless exists $params{EndToEndId} && defined $params{EndToEndId} && $params{EndToEndId} ne '';
    $params{Avps}       = []        unless exists $params{Avps}       && defined $params{Avps}       && ref $params{Avps} eq 'ARRAY';

    # Proxyable by default, but if Flags set, get value from there if IsProxyable not defined;
    # !Request by default, but if Flags set, get value from there if IsRequest not defined
    $params{IsProxyable} = (exists $params{IsProxyable} ? ($params{IsProxyable} ? 1 : 0) : (exists $params{Flags} ? $params{Flags} & 0x40 : 1));
    $params{IsRequest}   = (exists $params{IsRequest}   ? ($params{IsRequest}   ? 1 : 0) : (exists $params{Flags} ? $params{Flags} & 0x80 : 0));

    my ($code, $appid);
    if ($class eq 'Diameter::Message') {
        die "Missing parameter\n" unless exists $params{CommandCode} && defined $params{CommandCode} && 
                                         exists $params{AppId}       && defined $params{AppId};

        ($code, $appid) = ($params{CommandCode}, $params{AppId});

        die "Invalid parameter\n" unless $code =~ /^\d+$/ && $code <= 0xffffffff && $appid =~ /^\d+$/ && $appid <= 0xffffffff;

        if (exists $CODE_TO_CLASS{$code} && exists $CODE_TO_CLASS{$code}{$params{IsRequest}}) {
            my $new_class = $CODE_TO_CLASS{$code}{$params{IsRequest}};
            return $new_class->new( %params );
        }
    }
    else {
        my $config_params_hr = $TYPE_DEFS_BY_CLASS{$class};

        $params{IsRequest} = $config_params_hr->{IsRequest};
        $code              = $config_params_hr->{Code};
        $appid             = $config_params_hr->{ApplicationId}    if defined $config_params_hr->{ApplicationId};
    }

    die "Invalid Message Definition Exception: missing ApplicationId"   unless defined $appid && $appid =~ /^\d+$/ && $appid >= 0 && $appid <= 0xffffffff;

    my $flags;

    if (exists $params{Flags} && defined $params{Flags} && $params{Flags} ne '') {
        $flags = $params{Flags};
    }
    else {
        $flags = 0x00;
        $flags |= 0x80   if $params{IsRequest};
        $flags |= 0x40   if $params{IsProxyable};
        $flags |= 0x20   if $params{IsError};
    }


    my @avps = (exists $params{Avps} && defined $params{Avps} && ref $params{Avps} eq "ARRAY" ? @{ $params{Avps} } : ());

    # Convert %params shorthand for AVP values into AVP objects
    #
    if (exists $TYPE_DEFS_BY_CLASS{$class}) {
        foreach my $avpname (map { $_->[0] } @{ $TYPE_DEFS_BY_CLASS{$class}->{RequiredAVPs} }) {
            if (exists $params{$avpname}) {
                if (ref $params{$avpname}) {
                    unless (ref $params{$avpname} eq "ARRAY") { die "Invalid Message Definition: avp ($avpname)" }
                }
                else {
                    $params{$avpname} = [$params{$avpname}];
                }

                my $avpclass = 'Diameter::Message::AVP::' . $avpname;
                foreach my $avp_value (@{ $params{$avpname} }) {
                    push @avps, $avpclass->new( IsMandatory => 1, Data => $avp_value );
                }
            }
        }

        foreach my $avpname (map { $_->[0] } @{ $TYPE_DEFS_BY_CLASS{$class}->{OptionalAVPs} }) {
            if (exists $params{$avpname}) {
                if (ref $params{$avpname}) {
                    die "Inavlid Message Definition: avp ($avpname)"    unless ref $params{$avpname} eq "ARRAY";
                }
                else {
                    $params{$avpname} = [$params{$avpname}];
                }

                my $avpclass = 'Diameter::Message::AVP::' . $avpname;
                foreach my $avp_value (@{ $params{$avpname} }) {
                    push @avps, $avpclass->new( IsMandatory => 0, Data => $avp_value );
                }
            }
        }


        # Validate requisite AVPs are present and that mandatory and optional AVPs are in correct numbers
        my %avp_count_by_class;
        foreach my $avp (@avps) {
            my $ref = ref $avp;
            my $basename = $ref;
               $basename =~ s/^.+:://;

            $avp_count_by_class{$basename}++;
        }

        foreach my $avprow (@{ $TYPE_DEFS_BY_CLASS{$class}->{RequiredAVPs} }) {
            my ($avp_class, $count) = @{ $avprow };
            if (!exists $avp_count_by_class{$avp_class}) {
                die "Missing Required AVP Exception: $avp_class";
            }
            else {
                if ($avp_count_by_class{$avp_class} > 1 && $count eq '1') {
                    die "Invalid AVP Count Exception: $avp_class";
                }
            }
        }

        foreach my $avprow (@{ $TYPE_DEFS_BY_CLASS{$class}->{OptionalAVPs} }) {
            my ($avp_class, $count) = @{ $avprow };
            if (exists $avp_count_by_class{$avp_class} && $avp_count_by_class{$avp_class} > 1 && $count eq '1') {
                die "Invalid AVP Count Exception: $avp_class";
            }
        }
    }


    my $msg_length;
    if (!exists $params{Length}) {
        $msg_length = 20;    # header length
        foreach my $avp (@avps) { $msg_length += $avp->padded_length }
    }
    else {
        $msg_length = $params{Length};
    }

    my $self = bless [
        1,
        $msg_length,
        $flags,
        $code,
        $appid,
        $params{HopByHopId},
        $params{EndToEndId},
        \@avps,
        undef,
    ], $class;

    return $self;
}

sub version         { return shift->[VERSION] }
sub msg_length      { return shift->[MSG_LENGTH] }
sub flags           { return (shift->[FLAGS] >> 4) & 0xff }
sub is_request      { return shift->[FLAGS] & 0x80 }
sub command_code    { return shift->[COMMAND_CODE] }
sub app_id          { return shift->[APPLICATION_ID] }
sub hop_by_hop_id   { return shift->[HOP_BY_HOP_ID] }
sub end_to_end_id   { return shift->[END_TO_END_ID] }
sub avps            { return @{ shift->[AVP_LIST] } }


sub is {
    my $self = shift;
    my $type = shift;

    if (exists $MESSAGE_TYPE_TO_CLASS{$type}) {
        return $MESSAGE_TYPE_TO_CLASS{$type} eq ref $self;
    }
    else {
        return 0;
    }
}


sub encode {
    my $self = shift;

    if (! defined $self->[ENCODED]) {
        my $length = 20;

        my @avps_encoded;

        foreach my $avp (@{$self->[AVP_LIST]}) {
            my $ae = $avp->encode;
            $length = $length + length( $ae );
            push @avps_encoded, $ae;
        }

        $self->[ENCODED] = pack( "NNNNN", (($self->[VERSION] & 0xff) << 24) | ($self->[MSG_LENGTH] & 0x00ffffff),
                                          (($self->[FLAGS] & 0xff) << 24) | ($self->[COMMAND_CODE] & 0x00ffffff),
                                          $self->[APPLICATION_ID],
                                          $self->[HOP_BY_HOP_ID],
                                          $self->[END_TO_END_ID] )
                                . join( "", @avps_encoded );
    }

    return $self->[ENCODED];
}


sub decode {
    my $class  = shift;
    my $stream = shift;

    die "Invalid Diameter Message Exception"  unless length $stream >= 20;    # Diameter header length == 20

    my ($hdr1, $hdr2, $app_id, $hbh_id, $ete_id) = unpack( "NNNNN", $stream );

    my $version = ($hdr1 >> 24) & 0xff;

    die "Invalid Diameter Version Exception\n"  unless $version == 1;

    my $msg_length = $hdr1 & 0x00ffffff;

    die "Invalid Diameter Message Exception: Length Mismatch\n"  unless $msg_length == length $stream;

    my $flags = ($hdr2 >> 24) & 0xff;
    my $code  = $hdr2 & 0x00ffffff;

    my $stream_length = length $stream;
    my $stream_offset = 20;

    my @avps;
    while ($stream_length - $stream_offset >= 8) {
        my ($hdr1, $hdr2) = unpack( "NN", substr $stream, $stream_offset, 8 );
        my $avp_len = $hdr2 & 0x00ffffff;

        if ($stream_length - $stream_offset < $avp_len) {
            die "Invalid Diameter Message Exception\n";
        }

        my $avp = Diameter::Message::AVP->decode( substr $stream, $stream_offset, $avp_len );
        push @avps, $avp;

        $stream_offset += $avp->padded_length;
    }

    die "Invalid Diameter Message Exception\n"  if $stream_offset != $stream_length;

    return $class->new( Version => $version, ApplicationId => $app_id, Length => $msg_length, CommandCode => $code, Flags => $flags, AppId => $app_id,
                        HopByHopId => $hbh_id, EndToEndId => $ete_id, Avps => \@avps );
}


package Diameter::Message::CER;
use parent -norequire, 'Diameter::Message';

package Diameter::Message::CEA;
use parent -norequire, 'Diameter::Message';

package Diameter::Message::DWR;
use parent -norequire, 'Diameter::Message';

package Diameter::Message::DWA;
use parent -norequire, 'Diameter::Message';

package Diameter::Message::SLR;
use parent -norequire, 'Diameter::Message';

package Diameter::Message::SLA;
use parent -norequire, 'Diameter::Message';

package Diameter::Message::SSNR;
use parent -norequire, 'Diameter::Message';

package Diameter::Message::SSNA;
use parent -norequire, 'Diameter::Message';



1;
