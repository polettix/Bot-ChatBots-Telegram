# NAME

Bot::ChatBots::Telegram - Telegram adapter for Bot::ChatBots

# VERSION

This document describes Bot::ChatBots::Telegram version {{\[ version \]}}.

# SYNOPSIS

    # A minimal Telegram Bot using WebHooks
    use Log::Any qw< $log >;
    use Log::Any::Adapter;
    use Mojolicious::Lite;
    Log::Any::Adapter->set('Stderr');
    plugin 'Bot::ChatBots::Telegram' => sources => [
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
       $record->{response} = 'your thoughs are important for us!';
       return $record;
    }

    # You can also add Bot::ChatBots::Telegram::LongPoll sources if you want

# DESCRIPTION

This module allows you to to define [Bot::ChatBots](https://metacpan.org/pod/Bot::ChatBots) for
[Telegram Messenger](https://telegram.org/).

# METHODS

## **add\_source**

    $obj->add_source($module, %args); # OR
    $obj->add_source($module, \%args);

Add a new source.

The first argument `$module` is used (via ["load\_module" in Bot::ChatBots::Utils](https://metacpan.org/pod/Bot::ChatBots::Utils#load_module))
to load a class and call its `new` method with the provided `%args`. In the
invocation, the pair `app` and what is available in ["app"](#app) is also passed at
the end of the expansion of `%args` (overriding any previous key `app`). The
result of this instantiation is then appended to the ["sources"](#sources).

## **app**

    my $app = $obj->app;
    $self->app($new_app_object);

Accessor for the application object.

## **register**

    $obj->register($app, $conf);

[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) method for registering the plugin.

The registration process adds helper `chatbots.telegram`, that can be accessed
from the application like this:

    my $obj = app->chatbots->telegram;

This will allow you to call the other methods explained in this documentation.

Argument `$conf` is a hash reference supporting the following keys:

- `logger`

    either a logger object (supporting [Log::Any](https://metacpan.org/pod/Log::Any)'s interface, please) or the string
    `auto`, which automatically loads [Log::Any::Adapter::MojoLog](https://metacpan.org/pod/Log::Any::Adapter::MojoLog).

- `sources`

    an array reference containing definitions of sources, each represented as another
    array reference that is expanded to the arguments list for ["add\_source"](#add_source).

## **sources**

    my $aref = $obj->sources;
    $obj->sources($array_ref);

Accessor for defined sources, stored in an array reference.

# BUGS AND LIMITATIONS

Report bugs either through RT or GitHub (patches welcome).

# SEE ALSO

[Bot::ChatBots](https://metacpan.org/pod/Bot::ChatBots), [Bot::ChatBots::Telegram::WebHook](https://metacpan.org/pod/Bot::ChatBots::Telegram::WebHook),
[Bot::ChatBots::Telegram::LongPoll](https://metacpan.org/pod/Bot::ChatBots::Telegram::LongPoll), [WWW::Telegram::BotAPI](https://metacpan.org/pod/WWW::Telegram::BotAPI).

# AUTHOR

Flavio Poletti <polettix@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2016 by Flavio Poletti <polettix@cpan.org>

This module is free software. You can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.
