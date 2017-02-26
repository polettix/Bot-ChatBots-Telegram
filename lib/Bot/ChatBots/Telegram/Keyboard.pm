package Bot::ChatBots::Telegram::Keyboard;
use strict;
use warnings;
{ our $VERSION = '0.004'; }

use Ouch;
use Log::Any qw< $log >;
use Data::Dumper;

use Moo;
use namespace::clean;

use Exporter qw< import >;
our @EXPORT_OK = qw< keyboard >;

has displayable => (
   is => 'ro',
   required => 1,
);

has _value_for => (
   is => 'ro',
   required => 1,
);

{
   my ($ONE, $ZERO, $BOUNDARY);
   BEGIN {
      $ONE = "\x{200B}";
      $ZERO = "\x{200C}";
      $BOUNDARY = "\x{200D}";
   }

   sub __encode {
      my ($label, $code) = @_;
      (my $b = unpack 'B*', pack 'N', $code) =~ s/^0+//mxs;
      $b = '0' unless length $b;
      return join '', $label, $BOUNDARY, map(
         { $_ ? $ONE : $ZERO } split //, $b
      ), $BOUNDARY;
   }

   sub __decode {
      return unless defined $_[0];
      my ($label, $ec) = $_[0] =~ m{\A(.*)$BOUNDARY((?:$ZERO|$ONE)+)$BOUNDARY\z}mxs;
      return unless defined $ec;
      my $binary = join '', map { $_ eq $ONE ? '1' : '0' } split //, $ec;
      $binary = substr(('0' x 32) . $binary, -32, 32);
      my $code = unpack 'N', pack 'B*', $binary;
      return ($label, $code);
   }

}

sub BUILDARGS {
   my ($class, %args) = @_;
   ouch 500, 'no input keyboard' unless exists $args{keyboard};
   @args{qw<displayable _value_for>} = __keyboard($args{keyboard});
   return \%args;
}

sub get_value {
   my ($self, $x) = @_;
   if (ref($x) eq 'HASH') {
      $x = $x->{payload} if exists $x->{payload};
      $x = $x->{text} // undef;
   }
   elsif (ref($x)) {
      ouch 500, 'get_value(): pass either hash references or plain scalars';
   }

   my ($label, $code) = __decode($x);
   return undef unless defined $code;

   my $vf = $self->_value_for;
   if (! exists($vf->{$code})) {
      $log->warn("get_value(): received code $code is unknown");
      return undef;
   }
   return $vf->{$code};
}

sub __keyboard {
   my $input = shift;
   ouch 500, 'invalid input keyboard, not an ARRAY'
     unless ref($input) eq 'ARRAY';
   ouch 500, 'invalid empty keyboard' unless @$input;

   my $code = 0;
   my @display_keyboard;
   my (%value_for, %code_for);
   for my $row (@$input) {
      ouch 500, 'invalid input keyboard, not an AoA'
         unless ref($row) eq 'ARRAY';

      my @display_row;
      push @display_keyboard, \@display_row;
      for my $item (@$row) {
         ouch 500, 'invalid input keyboard, not an AoAoH'
           unless ref($item) eq 'HASH';

         my %display_item = %$item;
         push @display_row, \%display_item;

         my $command = delete $display_item{_value};
         next unless defined $command;
         my $cc = $code_for{$command} //= $code++;
         $value_for{$cc} //= $command;
         $display_item{text} = __encode($display_item{text}, $cc);
      }
   }
   return (\@display_keyboard, \%value_for);
}

sub keyboard {
   my @input;
   if (@_ > 1) {
      @input = @_;
   }
   elsif (@_ == 1) {
      my $x = shift;
      if (@$x > 0) {
         if (ref($x->[0]) eq 'ARRAY') {
            @input = @$x;
         }
         else {
            @input = $x; # one row only
         }
      }
   }
   return Bot::ChatBots::Telegram::Keyboard->new(keyboard => \@input);
}


1;
