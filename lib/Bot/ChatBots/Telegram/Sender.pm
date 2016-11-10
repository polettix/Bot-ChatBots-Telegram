package Bot::ChatBots::Telegram::Sender;
use strict;
use Ouch;
use 5.010;
{ our $VERSION = '0.001001'; }

use WWW::Telegram::BotAPI ();

use Moo;
use namespace::clean;
with 'Bot::ChatBots::Role::Sender';

has telegram => (
   is      => 'rw',
   lazy    => 1,
   default => sub {
      my $self = shift;
      my $tg   = WWW::Telegram::BotAPI->new(
         token => $self->token,
         async => 1,
      );
      return $tg;
   }
);

has token => (
   is       => 'ro',
   required => 1,
);

sub send_message {
   my ($self, $message, %args) = @_;
   ouch 500, 'no output to send' unless defined $message;

   # message normalization
   $message =
     ref($message)
     ? {%$message}
     : {text => $message, telegram_method => 'sendMessage'};
   my $method = delete($message->{telegram_method}) // do {
      state $method_for = {
         send        => 'sendMessage',
         sendMessage => 'sendMessage',
      };

      my $name = delete(local $message->{method}) // 'send';
      $method_for->{$name}
        or ouch 500, $self->name . ": unsupported method $name";
   };

   if (($method eq 'sendMessage') && (!exists $message->{chat_id})) {
      if (defined $args{record}) {    # take from $record
         $message->{chat_id} = $args{record}{channel}{id};
      }
      elsif ($self->has_recipient) {
         $message->{chat_id} = $self->recipient;
      }
      else {                          # no more ways to figure it out
         ouch 500, 'no chat identifier for message';
      }
   } ## end if (!exists $message->...)

   my @callback =
       $args{callback}     ? $args{callback}
     : $self->has_callback ? ($self->callback)
     :                       ();

   my $res = $self->telegram->api_request($method => $message, @callback);

   $self->may_start_loop(%args) if @callback;

   return $res;
} ## end sub send_message

1;
