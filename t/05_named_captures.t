use strict;
use warnings;
use Module::Runtime qw(use_module);
use Test::More import => ['!pass'];

plan skip_all => "JSON is needed for this test"
    unless use_module('JSON');
plan skip_all => "YAML is needed for this test"
    unless use_module('YAML');

my $data = { foo => 42 };
my $json = JSON::encode_json($data);
my $yaml = YAML::Dump($data);

{
    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::REST;

    setting environment => 'testing';

    prepare_serializer_for_format;

    get '/' => sub { "root" };
    get qr{ ^ / (?<something> \w+) \. (?<format> \w+) }x => sub {
        $data;
    };
}
use Dancer2::Test apps => [ 'Webservice' ];

my @tests = (
    {
        request => [GET => '/'],
        content_type => qr'text/html',
        response => 'root',
    },
    { 
        request => [GET => '/foo.json'],
        content_type => qr'application/json',
        response => $json
    },
    { 
        request => [GET => '/foo.yml'],
        content_type => qr'text/x-yaml',
        response => $yaml,
    },
    {
        request => [GET => '/'],
        content_type => qr'text/html',
        response => 'root',
    },
);

plan tests => scalar(@tests) * 2;

for my $test ( @tests ) {
    my $response = dancer_response(@{ $test->{request} });
    like($response->header('Content-Type'), 
       $test->{content_type},
       "headers have content_type set to ".$test->{content_type});

    is( $response->{content}, $test->{response},
        "\$data has been encoded" );
}
