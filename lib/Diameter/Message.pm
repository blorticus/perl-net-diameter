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
        Diameter::Message::AVP->new( Code => 260, IsMandatory => 1, Type => 'Grouped', Data => [
            Diameter::Message::AVP->new( Code => 276, IsMandatory => 1, Data => 16777217, Type => 'Unsigned32' ),
        ],
        [ 0, 277, 1, 'Unsigned', 1 ],   # an alternate form; must be [ $vendor_id, $code, $is_mandatory, data_type, $typed_data ]
        { Code => 264, IsMandatory => 1, Data => 'test.example.com', Type => 'UTF8String' }, # yet another alternate form; passed directly to Diameter::Message::AVP->new
        ...
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

    LAST_ELEMENT        => 8,
};


#
# $p = Diameter::Message->new( IsRequest => 1|0, IsError => 1|0, IsProxiable => 1|0, CommandCode => $cc,
#                              ApplicationId => $aid, HopByHopId => $hhid, EndToEndId => $eeid,
#                              Avps => \@avps, Flags => $flags );
#
# where @avps is listrefs of Diameter::Message::AVP objects
#

sub new {
    my $class = shift;
    my %params = @_;

    $params{HopByHopId}    = 0   unless exists $params{HopByHopId}    && defined $params{HopByHopId} && $params{HopByHopId} ne '';
    $params{EndToEndId}    = 0   unless exists $params{EndToEndId}    && defined $params{EndToEndId} && $params{EndToEndId} ne '';
    $params{Avps}          = []  unless exists $params{Avps}          && defined $params{Avps}       && ref $params{Avps} eq 'ARRAY';
    $params{ApplicationId} = 0   unless exists $params{ApplicationId} && defined $params{ApplicationId}; 

    # defaults are IsProxiable => true, all others => false, but get value from Flags if that is defined, instead of setting default
    $params{IsPotentialRetransmit}  = (exists $params{IsPotentialRetransmit} ? ($params{IsPotentialRetransmit}   ? 1 : 0) : (exists $params{Flags} ? $params{Flags} & 0x10 : 0));
    $params{IsError}      = (exists $params{IsError}     ? ($params{IsError}     ? 1 : 0) : (exists $params{Flags} ? $params{Flags} & 0x20 : 0));
    $params{IsProxiable}  = (exists $params{IsProxiable} ? ($params{IsProxiable} ? 1 : 0) : (exists $params{Flags} ? $params{Flags} & 0x40 : 1));
    $params{IsRequest}    = (exists $params{IsRequest}   ? ($params{IsRequest}   ? 1 : 0) : (exists $params{Flags} ? $params{Flags} & 0x80 : 0));

    unless (exists $params{CommandCode}) {
        $@ = "Missing Parameter Exception: Commandcode";
        return undef;
    }

    my ($code, $appid) = ($params{CommandCode}, $params{ApplicationId});

    unless (defined $code && $code =~ /^\d+$/  && $code <= 0xffffffff) {
        $@ = "Invalid Parameter Exception: Code";
        return undef;
    }

    unless ($appid =~ /^\d+$/ && $appid <= 0xffffffff) {
        $@ = "Invalid Parameter Exception: ApplicationId";
        return undef;
    }

    my $flags;

    if (exists $params{Flags} && defined $params{Flags} && $params{Flags} ne '') {
        $flags = $params{Flags};
    }
    else {
        $flags = 0x00;
        $flags |= 0x80   if $params{IsRequest};
        $flags |= 0x40   if $params{IsProxiable};
        $flags |= 0x20   if $params{IsError};
    }


    my @avps = (exists $params{Avps} && defined $params{Avps} && ref $params{Avps} eq "ARRAY" ? @{ $params{Avps} } : ());

    # Convert %params shorthand for AVP values into AVP objects
    #
    foreach my $avp (@avps) {
        if (ref $avp eq "HASH") {
            $avp = Diameter::Message::AVP->new( %{ $avp } );
        }
        elsif (ref $avp eq "ARRAY") {
            # [ $vendor_id, $code, $is_mandatory, $data_type, $typed_data ]
            unless (@{ $avp } == 5) {
                $@ = "Invalid Parameter Exception: AVP";
                return undef;
            }
            $avp = Diameter::Message::AVP->new( VendorId => $avp->[0], Code => $avp->[1], IsMandatory => $avp->[2], DataType => $avp->[3], Data => $avp->[4] );
        }
        elsif (!$avp->isa( 'Diameter::Message::AVP' )) {
            $@ = "Invalid Parameter Exception: AVP";
            return undef;
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
sub application_id  { return shift->[APPLICATION_ID] }
sub hop_by_hop_id   { return shift->[HOP_BY_HOP_ID] }
sub end_to_end_id   { return shift->[END_TO_END_ID] }
sub avps            { return @{ shift->[AVP_LIST] } }

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

    return $class->new( Version => $version, ApplicationId => $app_id, Length => $msg_length, CommandCode => $code, Flags => $flags,
                        HopByHopId => $hbh_id, EndToEndId => $ete_id, Avps => \@avps );
}



1;
