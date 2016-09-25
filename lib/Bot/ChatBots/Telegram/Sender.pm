package Bot::ChatBots::Telegram::Sender;
use strict;
use Ouch;
{ our $VERSION = '0.001'; }

use Mojo::Base 'Bot::ChatBots::Telegram::Base';
use WWW::Telegram::BotAPI ();

has 'callback';
has telegram => sub {
   return WWW::Telegram::BotAPI->new(token => shift->token, async => 1);
};

sub send {
   my ($self, $message, $callback) = @_;

   defined($message)
     or ouch 500, $self->name . ': no output to send';

   my $method = delete(local $message->{telegram_method}) // do {
      state $method_for = {
         send        => 'sendMessage',
         sendMessage => 'sendMessage',
      };

      my $name = delete(local $message->{method}) // 'send';
      $method_for->{$name}
        or ouch 500, $self->name . ": unsupported method $name";
   };

   return $self->telegram->api_request(
      $method => $message,
      ($callback ? $callback : ())
   );
} ## end sub send

sub processor {
   my $self   = shift;
   my $logger = $self->logger;
   return sub {
      my $record = shift;
      $logger->debug($self->name);
      $record->{telegram_res} =
        $self->send($record->{output}, $self->callback);
      return $record;
   };
} ## end sub processor

1;
