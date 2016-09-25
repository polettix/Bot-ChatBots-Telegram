package Bot::ChatBots::Telegram::Normalize;
use strict;
use Ouch;
{ our $VERSION = '0.001'; }

use Mo;
extends 'Bot::ChatBots::Base';    # use a different technology here!

sub process {
   my ($self, $record) = @_;

   my $update = $record->{update} or ouch 500, 'no update found!';
   $record->{technology} = 'telegram';

   my ($type) = grep { $_ ne 'update_id' } keys %$update;
   $record->{type} = $type;

   my $payload = $record->{payload} = $update->{$type};

   $record->{sender} = $payload->{from};

   my $chan = $record->{channel} = {%{$payload->{chat}}};
   $chan->{fqid} = "$chan->{type}/$chan->{id}";

   return $record;
} ## end sub process

42;
