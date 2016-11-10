package Bot::ChatBots::Telegram::LongPoll;
use strict;
{ our $VERSION = '0.001001'; }

use Ouch;
use Log::Any qw< $log >;
use Mojo::IOLoop ();
use IO::Socket::SSL ();    # just to be sure to complain loudly in case

use Moo;
use namespace::clean;

with 'Bot::ChatBots::Telegram::Role::Source'; # normalize_record, token
with 'Bot::ChatBots::Role::Source'; # processor, typename

has connect_timeout => (
   is => 'ro',
   default => sub { return 20 },
);

has interval => (
   is => 'ro',
   default => sub { return 0.1 },
);

has sender => (
   is => 'ro',
   lazy => 1,
   default => sub { # prefer has-a in this case
      my $self = shift;
      require Bot::ChatBots::Telegram::Sender;
      return Bot::ChatBots::Telegram::Sender->new(token => $self->token);
   },
);

has _start => (
   is => 'ro',
   default => sub { return 1 },
   init_arg => 'start',
);

has update_timeout => (
   is => 'ro',
   default => sub { return 300 },
);

sub BUILD {
   my $self = shift;
   $self->start if $self->_start;
}

sub class_custom_pairs {
   my $self = shift;
   return (token => $self->token);
}

sub start {
   my $self     = shift;
   my $args     = (@_ && ref($_[0])) ? $_[0] : {@_};

   my $update_timeout = $self->update_timeout;
   my %query = (timeout => $update_timeout, offset => 0);

   my $sender = $self->sender;
   $sender->telegram->agent->connect_timeout($self->connect_timeout)
     ->inactivity_timeout($update_timeout + 5)->max_redirects(5);

   my $source = $self->pack_source($args);

   my $is_busy;
   my $callback = sub {
      return if $is_busy;
      $is_busy = 1;

      $sender->send_message(
         {
            %query, telegram_method => 'getUpdates',
         },
         callback => sub {
            my (undef, $tx) = @_;
            my $data = $tx->res()->json();

            if (!$data->{ok}) {    # boolean flag
               my $description = $data->{description} // 'unknown error ';
               $log->error("getUpdates error: $description");
            }
            elsif (@{$data->{result} // []}) {
               my $id;
               my @updates = grep {$_->{update_id} >= $query{offset}} @{$data->{result}};
               my $n_updates = $#updates;
               for my $i (0 .. $n_updates) {
                  my $update = $updates[$i];
                  my $exception;
                  try {
                     my $record = $self->normalize_record(
                        {
                           batch => {
                              count => ($i + 1),
                              total => ($n_updates + 1),
                           },
                           source => $source,
                           update => $update,
                        }
                     );
                     my $outcome = $self->process($record);

                     $sender->send($outcome->{response})
                        if (ref($outcome) eq 'HASH') && exists($outcome->{response});

                     1;
                  } ## end try
                  catch {
                     $exception = $_;
                     $log->error(bleep $exception);
                  };
                  die $exception if defined($exception) && $args->{throw};
               } ## end for my $update (@{$data...})
               $query{offset} = $id + 1;    # prepare for next iteration
            } ## end elsif ($data->{result})

            # reset "is busy?" flag for next iteration
            $is_busy = 0;
         },
      );

   };
   Mojo::IOLoop->recurring($self->interval, $callback);

   Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

   return $self;
} ## end sub start
1;
