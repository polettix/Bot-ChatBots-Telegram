requires 'perl',                       '5.010';
requires 'Mojolicious',                '7.08';
requires 'Log::Any',                   '1.042';
requires 'Log::Any::Adapter::MojoLog', '0.02';
requires 'IO::Socket::SSL',            '2.038';
requires 'WWW::Telegram::BotAPI',      '0.07';
requires 'Module::Runtime',            '0.014';

on test => sub {
   requires 'Test::More', '0.88';
   requires 'Path::Tiny', '0.096';
};

on develop => sub {
   requires 'Path::Tiny',        '0.096';
   requires 'Template::Perlish', '1.52';
};
