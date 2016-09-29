package Bot::ChatBots::Telegram::Sender;
use strict;
use Ouch;
{ our $VERSION = '0.001'; }

use Mojo::Base 'Bot::ChatBots::Telegram::Base';
use WWW::Telegram::BotAPI ();

has async => 1;
has 'callback';
has telegram => sub {
   my $self = shift;
   my $tg   = WWW::Telegram::BotAPI->new(
      token => $self->token,
      async => $self->async
   );
   Mojo::IOLoop->start unless Mojo::IOLoop->is_running;    # safe side!
   return $tg;
};

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

sub send {
   my ($self, $message, $callback) = @_;

   defined($message)
     or ouch 500, $self->name . ': no output to send';

   $message = {text => $message, telegram_method => 'sendMessage'}
     unless ref $message;

   my $method = delete(local $message->{telegram_method}) // do {
      state $method_for = {
         send        => 'sendMessage',
         sendMessage => 'sendMessage',
      };

      my $name = delete(local $message->{method}) // 'send';
      $method_for->{$name}
        or ouch 500, $self->name . ": unsupported method $name";
   };

   $callback //= $self->callback;
   $callback = undef unless $self->async;
   return $self->telegram->api_request(
      $method => $message,
      ($callback ? $callback : ())
   );
} ## end sub send

1;
