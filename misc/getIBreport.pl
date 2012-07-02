#!/usr/bin/perl -w

use LWP 5.64;
use HTML::TokeParser;
use Date::Format;

### secret is the token, report is the report. both given by the
# flexstatement creation process on the IB website
my $secret = 'XXXXXXXXXXXXXXXXXXXXXXXX';
my $report = 'XXXXX';
###
my $url_req =
'https://www.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest?t='
  . $secret . '&q='
  . $report;
my $browser  = LWP::UserAgent->new;
my $response = $browser->get($url_req);
die "Couldn't get $url_req -- ", $response->status_line
  unless $response->is_success;
die "Hey, I was expecting xml, not ", $response->content_type
  unless $response->content_type eq 'text/xml';

##print $response->content;

$p = HTML::TokeParser->new( \$response->content );
if ( $p->get_tag("code") ) {
    my $mycode = $p->get_trimmed_text;
##print $mycode;
    $p->get_tag("url");
##my $url_getstmt = 'https://www.interactivebrokers.com/Universal/servlet/FlexStatementService.GetStatement?q='.$mycode.'&t='.$secret.'&v=2';
    my $url_getstmt =
      $p->get_trimmed_text . '?q=' . $mycode . '&t=' . $secret . '&v=2';

##print $url_getstmt;
    my $response;
    do {
        if ( defined $response ) { sleep 10; print "sleeping"; }
        $response = $browser->get($url_getstmt);
        die "Couldn't get $url_getstmt -- ", $response->status_line
          unless $response->is_success;
        $p = HTML::TokeParser->new( \$response->content );
        $p->get_tag("code");
        $mycode = $p->get_trimmed_text;
      } while ( $mycode eq
        'Statement generation in progress. Please try again shortly.' );
    open MYFILE,
      '>IB-' . $report . "-" . time2str( "%Y-%m-%dT%T", time ) . '.xml'
      or die $!;
    print MYFILE $response->content;
    close(MYFILE);
}
