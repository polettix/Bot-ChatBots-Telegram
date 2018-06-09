# NAME

Bot::ChatBots::Telegram - Telegram adapter for Bot::ChatBots

# VERSION

This document describes Bot::ChatBots::Telegram version {{\[ version \]}}.

<div>
    <a href="https://travis-ci.org/polettix/Bot-ChatBots-Telegram">
    <img alt="Build Status" src="https://travis-ci.org/polettix/Bot-ChatBots-Telegram.svg?branch=master">
    </a>
    <a href="https://www.perl.org/">
    <img alt="Perl Version" src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg">
    </a>
    <a href="https://badge.fury.io/pl/Bot-ChatBots-Telegram">
    <img alt="Current CPAN version" src="https://badge.fury.io/pl/Bot-ChatBots-Telegram.svg">
    </a>
    <a href="http://cpants.cpanauthors.org/dist/Bot-ChatBots-Telegram">
    <img alt="Kwalitee" src="http://cpants.cpanauthors.org/dist/Bot-ChatBots-Telegram.png">
    </a>
    <a href="http://www.cpantesters.org/distro/B/Bot-ChatBots-Telegram.html?distmat=1">
    <img alt="CPAN Testers" src="https://img.shields.io/badge/cpan-testers-blue.svg">
    </a>
    <a href="http://matrix.cpantesters.org/?dist=Bot-ChatBots-Telegram">
    <img alt="CPAN Testers Matrix" src="https://img.shields.io/badge/matrix-@testers-blue.svg">
    </a>
</div>

# SYNOPSIS

    # A minimal Telegram Bot using WebHooks
    use Log::Any qw< $log >;
    use Log::Any::Adapter;
    use Mojolicious::Lite;
    Log::Any::Adapter->set(MojoLog => logger => app->log);
    plugin 'Bot::ChatBots::Telegram' => instances => [
       [
          'WebHook',
          processor  => \&processor,
          register   => 1,
          token      => $ENV{TOKEN},
          unregister => 1,
          url        => 'https://example.com:8443/mybot',
       ],
       # more can follow here...
    ];
    app->start;
    sub processor {
       my $record = shift;
       # do whatever you want with $record, e.g. set a quick response
       $record->{send_response} = 'your thoughs are important for us!';
       return $record;
    }

    # You can also add Bot::ChatBots::Telegram::LongPoll sources if you want

# DESCRIPTION

This module allows you to to define [Bot::ChatBots](https://metacpan.org/pod/Bot::ChatBots) for
[Telegram](https://telegram.org/), a messaging application. For an
introduction and tutorial, see
[Bot::ChatBots::Telegram::Guide::Tutorial](https://metacpan.org/pod/Bot::ChatBots::Telegram::Guide::Tutorial).

Strictly speaking, this _module_ is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin that allows
you to load and use [Bot::ChatBots::Telegram::WebHook](https://metacpan.org/pod/Bot::ChatBots::Telegram::WebHook) (see ["SYNOPSIS"](#synopsis)
for a quick example). On the other hand, the _distribution_ also contains
other modules that allow you to interact with Telegram, e.g.
[Bot::Chatbots::Telegram::LongPoll](https://metacpan.org/pod/Bot::Chatbots::Telegram::LongPoll).

These modules rely upon [Log::Any](https://metacpan.org/pod/Log::Any) for emitting logging information; you
are encouraged to read that module's documentation for further
information. For what we are concerned, you have to remember that all logs
will be lost unless you configure [Log::Any](https://metacpan.org/pod/Log::Any), e.g. to send messages on
standard output you can do this:

    use Log::Any::Adapter qw< Stderr >;

If using the web hook, then you will probably want to send the logs
together with [Mojolicious](https://metacpan.org/pod/Mojolicious)'s logs, like this:

    use Mojolicious::Lite;
    use Log::Any::Adapter;
    Log::Any::Adapter->set(MojoLog => logger => app->log);

The configuration above relies on the presence of
[Log::Any::Adapter::MojoLog](https://metacpan.org/pod/Log::Any::Adapter::MojoLog).

# METHODS

All the heavylifting is done by [Bot::ChatBots::MojoPlugin](https://metacpan.org/pod/Bot::ChatBots::MojoPlugin).

# BUGS AND LIMITATIONS

Report bugs through GitHub (patches welcome).

# SEE ALSO

[Bot::ChatBots](https://metacpan.org/pod/Bot::ChatBots), [Bot::ChatBots::Telegram::WebHook](https://metacpan.org/pod/Bot::ChatBots::Telegram::WebHook),
[Bot::ChatBots::Telegram::LongPoll](https://metacpan.org/pod/Bot::ChatBots::Telegram::LongPoll), [WWW::Telegram::BotAPI](https://metacpan.org/pod/WWW::Telegram::BotAPI).

# AUTHOR

Flavio Poletti <polettix@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2016, 2018 by Flavio Poletti <polettix@cpan.org>

This module is free software. You can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.
