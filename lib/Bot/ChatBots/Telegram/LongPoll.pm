package Bot::ChatBots::Telegram::LongPoll;
use strict;
use Ouch;
{ our $VERSION = '0.001'; }

use Mojo::Base 'Bot::ChatBots::Telegram::Base';
use Mojo::UserAgent ();
use IO::Socket::SSL ();    # just to be sure to complain loudly in case
use Mojo::URL       ();
use Mojo::IOLoop    ();

has callback => sub {    # default callback allows for unblocking operation
   my $logger = shift->logger;
   return sub {
      my ($ua, $tx) = @_;
      $logger->debug('stuff completed');    # FIXME
   };
};
has connect_timeout => 20;
has interval        => 0.1;
has sender => sub {                         # prefer has-a in this case
   require Bot::ChatBots::Telegram::Sender;
   return Bot::ChatBots::Telegram::Sender->new(token => shift->token);
};
has update_timeout => 300;

sub new {
   my $package = shift;
   my $self    = $package->SUPER::new(@_);
   my $args    = (@_ && ref($_[0])) ? $_[0] : {@_};
   $self->start($args) if (!exists($args->{start})) || $args->{start};
   return $self;
} ## end sub new

sub start {
   my $self     = shift;
   my $args     = (@_ && ref($_[0])) ? $_[0] : {@_};
   my $typename = $self->typename;
   my $name     = $self->name;
   my $logger   = $self->logger;

   my $update_timeout = $self->update_timeout();
   my %query = (timeout => $update_timeout, offset => 0);

   my $sender    = $self->sender;
   $sender->telegram->agent->connect_timeout($self->connect_timeout)
     ->inactivity_timeout($update_timeout + 5)->max_redirects(5);

   my $token = $self->token;

   my $is_busy;
   my $callback = sub {
      return if $is_busy;
      $is_busy = 1;

      $sender->send(
         {
            %query, telegram_method => 'getUpdates',
         },
         sub {
            my (undef, $tx) = @_;
            my $data = $tx->res()->json();

            if (!$data->{ok}) {    # boolean flag
               my $description = $data->{description} // 'unknown error ';
               $logger->error("$name: getUpdates error: $description");
            }
            elsif (@{$data->{result} // []}) {
               my $id;
               for my $update (@{$data->{result}}) {
                  $id = $update->{update_id};
                  next if ($id < $query{offset});
                  my $outcome = $self->process(
                     {
                        source => {
                           type         => $typename,
                           ref          => $self,
                           args         => $args,
                           token        => $token,
                           object_token => $token,
                        },
                        update => $update,
                     }
                  );

                  if (my $response = $outcome->{response}) {
                     $sender->send($response);
                  }
               } ## end for my $update (@{$data...})
               $query{offset} = $id + 1;    # prepare for next iteration
            } ## end elsif ($data->{result})

            # reset "is busy?" flag for next iteration
            $is_busy = 0;
         },
      );

   };
   Mojo::IOLoop->recurring(0.1, $callback);

   Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

   return $self;
} ## end sub start

sub send {
   my $self    = shift;
   my $message = shift;
   return $self->sender->send($message, (@_ ? shift : $self->callback));
}

1;
