use strict;
use warnings;

use Plack::Test;
use HTTP::Request::Common qw(GET POST PUT DELETE);

use Test::More tests => 3;

{ package Webservice;  

    use Dancer2;
    use Dancer2::Plugin::REST;

    prepare_serializer_for_format;

    get '/:something.:format' => sub {
        { hello => 'world' };
    };

    get '/serializer' => sub {
        ref(app->setting('serializer'))||'none';
    }
}

my $app = Dancer2->runner->psgi_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res;

    $res = $cb->( GET "/serializer", 'Content-Type' => 'text/plain' );
    is $res->content => 'none';

    $res = $cb->( GET "/foo.json", 'Content-Type' => 'application/json' );
    is $res->content => '{"hello":"world"}';

    $res = $cb->( GET "/serializer", 'Content-Type' => 'text/plain' );
    is $res->content => 'none';
};


