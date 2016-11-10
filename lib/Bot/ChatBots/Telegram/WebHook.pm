package Bot::ChatBots::Telegram::WebHook;
use strict;
use warnings;
{ our $VERSION = '0.001001'; }

use Ouch;
use Log::Any qw< $log >;
use Data::Dumper;
use Mojo::URL;
use Mojo::Path;

use Moo;
use namespace::clean;

with 'Bot::ChatBots::Telegram::Role::Source';    # has normalize_record
with 'Bot::ChatBots::Role::Source';
with 'Bot::ChatBots::Role::WebHook';

sub BUILD {
   my $self = shift;
   $self->install_route;
}

sub parse_request {
   my ($self, $req) = @_;
   return $req->json;
}

sub register {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};

   my $app   = $args->{app}   // $self->app;
   my $token = $args->{token} // $self->token;

   my $wh_url;
   if (my $url = $args->{url} // $self->url) {
      $wh_url = Mojo::URL->new($url);
   }
   else {
      my $path = $args->{path} // $self->path;
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

   $self->_register($args->{token} // $self->token, $form);

   return $self;
} ## end sub register

sub unregister {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};
   $self->_register($args->{token} // $self->token);
   return $self;
} ## end sub unregister

sub _register {
   my ($self, $token, $form) = @_;
   require WWW::Telegram::BotAPI;
   my $outcome = WWW::Telegram::BotAPI->new(token => $token)
     ->setWebhook($form // {url => ''});
   $log->info($outcome->{description} // 'unknown result');
   return;
} ## end sub _register

1;
