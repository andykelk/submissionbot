use strict;
use warnings;

package SubmissionSite;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use HTML::TreeBuilder 5 -weak;

sub new {
  my ($class, $basePath) = @_;
  my $self = {basePath => $basePath};
  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->cookie_jar({});
  push @{ $self->{ua}->requests_redirectable }, 'POST';

  bless $self, $class;
}

sub login {
  my ($self, $path, $email, $password) = @_;

  my $url = $self->{basePath} . $path;
  my $response = $self->{ua}->get($url);

  unless ($response->is_success) {
    Log::Log4perl->get_logger()->fatal('Login page GET failed: ' . $response->status_line);
    die $response->status_line;
  }

  my $loginPage = HTML::TreeBuilder->new;
  $loginPage->parse($response->content);
  $loginPage->eof;

  my $token = $loginPage->look_down(_tag => 'input', name => 'authenticity_token')->attr('value');

  my $form = ['user[email]' => $email, 'user[password]' => $password, authenticity_token => $token, utf8 => '&#x2713;', 'user[remember_me]' => 1, commit => 'Sign In'];

  $response = $self->{ua}->post($url, $form);

  unless ($response->is_success) {
    Log::Log4perl->get_logger()->fatal('Login POST failed: ' . $response->status_line);
    die $response->status_line;
  }
}

sub getList {
  my ($self, $listPath, $itemPath, $streamId) = @_;

  my $response = $self->{ua}->get($self->{basePath} . $listPath . $streamId);

  unless ($response->is_success) {
    Log::Log4perl->get_logger()->fatal('Submission list GET failed: ' . $response->status_line);
    die $response->status_line;
  }

  my $submissionsPage = HTML::TreeBuilder->new;
  $submissionsPage->parse($response->content);
  $submissionsPage->eof;

  my @subs = $submissionsPage->find_by_tag_name('tr');

  shift @subs;
  
  return Submissions->createFromArrayRef(\@subs, ($self->{basePath} . $itemPath), $streamId);
}

1;
