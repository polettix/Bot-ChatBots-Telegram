package Bot::ChatBots::Telegram;
use strict;
{ our $VERSION = '0.001'; }

use Bot::ChatBots::Utils qw< load_module >;

use Mojo::Base 'Mojolicious::Plugin';

has [qw< app sources >];

sub register {
   my ($self, $app, $conf) = @_;
   $conf //= {};

   # initialize object
   $self->app($app);
   $self->sources([]);

   # add helper to be usable
   $app->helper(telegram => sub { return $self });

   # set logger for Log::Any, if needed
   my $spec = exists($conf->{logger}) ? $conf->{logger} : 'auto';
   if (defined $spec) {
      $spec = [MojoLog => logger => $app->log] if $spec eq 'auto';

      require Log::Any::Adapter;
      Log::Any::Adapter->set(ref($spec) ? @$spec : $spec);
   } ## end if ((!exists($conf->{logger...})))

   # initialize with sources passed on the fly
   $self->add_source(@$_) for @{$conf->{sources} // []};

   $app->log()->debug('telegram helper registered');

   return $self;
} ## end sub register

sub add_source {
   my $self   = shift;
   my $module = load_module(shift, 'Bot::ChatBots::Telegram');
   my @args   = (@_ && ref($_[0])) ? %{$_[0]} : @_;
   my $source = $module->new(@args, app => $self->app);
   push @{$self->sources}, $source;
   return $source;
} ## end sub add_source

42;
