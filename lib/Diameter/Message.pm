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

=head1 DESCRIPTION

This package allows one to create objects representing Diameter Messages (see RFC 6733).  There is a package
method (B<decode>) for reading a data stream, and translating it into a B<Diameter::Message> object.  Another
function (B<encode>) reverses this, creating a network byte-order stream from a B<Diameter::Message> object.

The following methods are defined:

=over 4

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


=item I<$m> = Diameter::Message-E<gt>B<new>( I<%params> );

Constructor.  I<%params> include:

=over 8

=item B<CommandCode> => I<$code>

The message command code.  Must be a 32-bit unsigned integer.  Required.  No default.

=item B<ApplicationId> => I<$appid>

The message application-id.  Must be a 32-bit unsigned integer.  Default is 0.

=item B<IsRequest> => I<1|0>

Set the request flag?  Default is 0.

=item B<IsError> => I<1|0>

Set the error flag?  Default is 0.

=item B<IsProxiable> => I<1|0>

Set the proxiable flag?  Default is 0.

=item B<Flags> => I<$flags>

The flags value.  This is the unshifted octet for the message flags.  Thus, if you
wish to set the request and proxiable flags, I<$flags> would be 0xc0.  If this is
provided, the values for B<IsRequest>, B<IsError> and B<IsProxiable> are all ignored.

=item B<HopByHopId> => I<$hbh_id>

The message hop-by-hop-id.  Must be a 32-bit unsigned integer.  Default is 0.

=item B<EndToEndId> => I<$ete_id>

The message end-to-end-id.  Must be a 32-bit unsigned integer.  Default is 0.

=item B<Avps> => I<\@avps>

A list of AVPs.  Each entry may be either a B<Diameter::Message::AVP> object,
a listref or a hashref.  If it's a hashref, B<Diameter::Message::AVP>-E<gt>B<new>
is invoked, and the hashref is expanded and passed.  If it is a listref, it must
have 5 elements: [ I<$vendor_id>, I<$avp_code>, I<$is_mandatory>, I<$data_type>, I<$typed_data> ].
I<$data_type> must be a valid B<DataType> value for the B<Diameter::Message::AVP>
constructor.

=back

For any parameter, if an invalid value is provided, I<undef> is returned and I<$@> is set.

=cut

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
        $@ = "Missing Parameter Exception: CommandCode";
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
        elsif (!UNIVERSAL::isa( $avp, 'Diameter::Message::AVP' )) {
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

=item I<$v> = I<$m>-E<gt>B<version>

Return the message Diameter version.

=item I<$l> = I<$m>-E<gt>B<msg_length>

Return the length of the Diameter message as it will be encoded.

=item I<$f> = I<$m>-E<gt>B<flags>

Return the message Diameter flags, unshifted.

=item I<$b> = I<$m>-E<gt>B<is_request>

Boolean.  True if the message request flag is set; false otherwise.

=item I<$c> = I<$m>-E<gt>B<command_code>

Return the message command code.

=item I<$i> = I<$m>-E<gt>B<application_id>

Return the message application id.

=item I<$h> = I<$m>-E<gt>B<hop_by_hop_id>

Return the message hop-by-hop id.

=item I<$h> = I<$m>-E<gt>B<end_to_end_id>

Return the message end-to-end id.

=item I<\@avps> = I<$m>-E<gt>B<avps>

Return the message AVPs as B<Diameter::Message::AVP> objects.  This
is *not* a deep copy, so any changes to this listref will alter the
underlying AVP set.  You probably don't want to to this.

=cut

sub version         { return shift->[VERSION] }
sub msg_length      { return shift->[MSG_LENGTH] }
sub flags           { return shift->[FLAGS] }
sub is_request      { return shift->[FLAGS] & 0x80 }
sub command_code    { return shift->[COMMAND_CODE] }
sub application_id  { return shift->[APPLICATION_ID] }
sub hop_by_hop_id   { return shift->[HOP_BY_HOP_ID] }
sub end_to_end_id   { return shift->[END_TO_END_ID] }
sub avps            { return @{ shift->[AVP_LIST] } }


=item I<$stream> = I<$m>-E<gt>B<encode>

Encode the message to a network byte-order stream.  The
encoding is cached, so if this is run repeatedly, the message
will only pass through the encoder once.

=cut

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


=item I<$m> = Diameter::Message-E<gt>B<decode>( I<$stream> )

Given a stream of bytes in network byte-order, attempt to create a B<Diameter::Message>
object.  If a failure occurs, return I<undef> and set I<$@>.  I<$stream> must be exactly
one Diameter message.

=cut

sub decode {
    my $class  = shift;
    my $stream = shift;

    unless (length $stream >= 20) {
        $@ = "Invalid Diameter Message Exception: length < 20";    # Diameter header length == 20
        return undef;
    }

    my ($hdr1, $hdr2, $app_id, $hbh_id, $ete_id) = unpack( "NNNNN", $stream );

    my $version = ($hdr1 >> 24) & 0xff;

    unless ($version == 1) {
        $@ = "Invalid Diameter Message Exception: version is not 1";
        return undef;
    };

    my $msg_length = $hdr1 & 0x00ffffff;

    unless ($msg_length == length $stream) {
        $@ = "Invalid Diameter Message Exception: length mismatch";
        return undef;
    }

    my $flags = ($hdr2 >> 24) & 0xff;
    my $code  = $hdr2 & 0x00ffffff;

    my $stream_length = length $stream;
    my $stream_offset = 20;

    my @avps;
    while ($stream_length - $stream_offset >= 8) {
        my ($hdr1, $hdr2) = unpack( "NN", substr $stream, $stream_offset, 8 );
        my $avp_len = $hdr2 & 0x00ffffff;

        if ($stream_length - $stream_offset < $avp_len) {
            $@ = "Invalid Diameter Message Exception: insufficient data for decoding";
            return undef;
        }

        my $avp = Diameter::Message::AVP->decode( substr $stream, $stream_offset, $avp_len );
        push @avps, $avp;

        $stream_offset += $avp->padded_length;
    }

    if ($stream_offset != $stream_length) {
        $@ = "Invalid Diameter Message Exception: incorrect octet count";
        return undef;
    }

    return $class->new( Version => $version, ApplicationId => $app_id, Length => $msg_length, CommandCode => $code, Flags => $flags,
                        HopByHopId => $hbh_id, EndToEndId => $ete_id, Avps => \@avps );
}


=back

=head1 BLAME

 Vernon Wells (boguese@hotmail.com) 27 Mar 2018

=cut

1;
