#!/usr/bin/perl -w

use JSON;
use Switch;
use Data::Dumper;
require HTTP::Request;
require LWP::UserAgent;

$zeus_api = "http://zeus.a.ajkdns.com:20080/api/service/get_list";

&usage() && exit 2 if (@ARGV < 2);
$app_list = &get_app_list($zeus_api);
&gen_config($ARGV[0], $ARGV[1]);


sub usage {
    print "$0 <template> <conf_file>\n"
}

sub get_app_list {
    $api = $_[0];
    $request = HTTP::Request->new(GET => $api);

    $ua = LWP::UserAgent->new();
    $response = $ua->request($request);

    if($response->{"_rc"} != 200) {
        return 0;
    }

    #print Dumper($response);

    if($list = decode_json $response->{"_content"}) {
        return $list;
    } else {
        return 0;
    }
}

sub gen_config {
    $template = $_[0];
    $conf_file = $_[1];

    open(TFH, "<", $template) || die("Open $template failed!");
    open(CFH, ">", $conf_file) || die("Open $conf_file failed!");

    while($line = <TFH>) {
        $line =~ s/\n//g;
        if($line =~ m/^(.*)\{\%(\d+)\%\}/) {
            $server_group = $app_list->{"$2"};
            foreach (@$server_group) {
                next if $_->{'status'} != 1;
                printf CFH "%sserver %s:%d", $1, $_->{'ip'}, $_->{'service_port'};
                printf CFH " weight=%d", $_->{'weight'} if $_->{'weight'} != 0;
                printf CFH "; #%s\n", $_->{'hostname'};
            }
        } else {
            print CFH "$line\n";
        }
    }

    close(TFH);
    close(CFH);
}
