package Bot::ChatBots::Telegram::Base;
use strict;
use Ouch;
{ our $VERSION = '0.001001'; }

use Mojo::Base '-base';
use Log::Any ();

has logger => sub { Log::Any->get_logger };
has name   => sub { shift->typename };
has normalizer => \&_default_normalizer;
has processor  => sub { ouch 500, shift->name . ': no processor defined' };
has token      => sub { ouch 500, shift->name . ': no token defined' };
has typename   => sub { return ref($_[0]) || $_[0] };

sub process {
   my ($self, $record) = @_;
   if (my $normalizer = $self->normalizer) {
      $record = $normalizer->($record);
   }
   return $self->processor->($record);
} ## end sub process

sub _default_normalizer {
   require Bot::ChatBots::Telegram::Normalize;
   return Bot::ChatBots::Telegram::Normalize->new->processor;
}

1;
