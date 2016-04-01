use strict;
use warnings;

package Slack;

use JSON;

sub new {
  my ($class) = @_;
  my $self = {};
  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->cookie_jar({});
  push @{ $self->{ua}->requests_redirectable }, 'POST';

  bless $self, $class; 
}

sub sendMessage {
  my ($self, $submission,$webhook) = @_;

  my $payload = {
    text => "New submission received!\nTitle: $submission->{name}\n<$submission->{url}>"
  };

  my $request = HTTP::Request->new('POST', $webhook);
  $request->header( 'Content-Type' => 'application/json' );
  $request->content( JSON::encode_json($payload) );

  my $response = $self->{ua}->request($request);
  
  unless ($response->is_success) {
    die $response->status_line;
  } 
}

1;
