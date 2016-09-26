package Bot::ChatBots::Telegram::WebHook;
use strict;
use warnings;
use Ouch;
{ our $VERSION = '0.001'; }

use Mojo::Base 'Bot::ChatBots::Telegram::Base';
use Mojo::URL;
use Mojo::Path;
use Log::Any qw< $log >;
use Try::Tiny;

use Bot::ChatBots::Utils ();

has [qw< app guard path url >];

sub new {
   my $package = shift;
   my $self    = $package->SUPER::new(@_);

   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};

   my $path = $self->path;
   if (!defined($path)) {
      my $url = $self->url
        or ouch 500, 'undefined path and url for WebHook';
      $path = Mojo::URL->new($url)->path->to_string;
      $self->path($path);
   } ## end if (!defined($path))

   my $r = $args->{routes} // $self->app->routes;
   my $route = $r->post($path => $self->handler);

   $self->register() if $args->{register};

   if ($args->{unregister}) {
      my $token = $self->token;
      $self->guard(Bot::ChatBots::Utils::guard(sub { _register($token) }));
   }

   return $self;
} ## end sub new

sub handler {
   my ($self, $args) = @_;

   my $source = {
      app          => $self->app,
      args         => $args,
      object_token => $self->token,
      processor    => $self->processor,
      ref          => $self,
      type         => ref($self),
   };

   return sub {
      my $c = shift;

      # whatever happens, the bot "cannot" fail or Telegram will hammer
      # us with the same update over and over
      my $outcome;
      try {
         local $source->{controller} = $c;
         $outcome = $self->process(
            {
               source => $source,
               stash  => $c->stash,
               update => $c->req->json,
            }
         );
         1;
      } ## end try
      catch {
         $log->error("caught bot exception: $_");
      };

      if ($outcome) {    # give the outcome a try, please know what you do

         # this is WebHook and Mojolicious specific, somehow
         return if $outcome->{rendered};

         # this is more generic, interpret as sendMessage by default
         if (my $response = $outcome->{response}) {
            local $response->{method} = $response->{method}
              // 'sendMessage';
            return $c->render(json => $response);
         }

      } ## end if ($outcome)

      # this is the safe approach - everything went fine, nothing to say
      return $c->rendered(204);
   };
} ## end sub handler

sub register {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};
   my $app  = $self->app;

   my $token = $args->{token} // $self->token // ouch 500,
     'Cannot register WebHook without a token';

   my $wh_url;
   if (my $url = $args->{url} // $self->url) {
      $wh_url = Mojo::URL->new($url);
   }
   else {
      my $path = $args->{path} // $self->path // ouch 500,
        'Cannot register WebHook without a url or a path';
      $path = Mojo::Path->new($path);

      my $c = $args->{controller} // $app->build_controller;
      $wh_url = $c->url_for($path);
   } ## end else [ if (my $url = $args->{...})]

   my $form = {url => $wh_url->to_abs->to_string};
   if ($self->{certificate}) {
      my $certificate = $args->{certificate};
      $certificate = {content => $certificate} unless ref $certificate;
      $form->{certificate} = $certificate;
   }

   _register($args->{token} // $self->token, $form);

   return $self;
} ## end sub register

sub unregister {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};
   _register($args->{token} // $self->token);
   return $self;
} ## end sub unregister

sub _register {
   my ($token, $form) = @_;
   require WWW::Telegram::BotAPI;
   my $outcome = WWW::Telegram::BotAPI->new(token => $token)
     ->setWebhook($form || {url => ''});
   $log->info($outcome->{description} // 'unknown result');
   return;
} ## end sub _register

1;
