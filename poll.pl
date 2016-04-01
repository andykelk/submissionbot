use strict;
use warnings;

use lib './lib';

use Slack;
use Submissions;
use SubmissionSite;

use YAML;

my $config = YAML::LoadFile('config.yaml');

my $submissionSite = SubmissionSite->new($config->{submissionsBase});
$submissionSite->login($config->{signInPath}, $config->{email}, $config->{password});
my $slack = Slack->new();
foreach my $streamId (keys %{$config->{channelMapping}}) {
  my $submissions = $submissionSite->getList($config->{listPath}, $config->{itemPath}, $streamId);
  $submissions->removeAlreadySeen();
  my $sender = sub {$slack->sendMessage(shift, $config->{channelMapping}->{$streamId})};
  $submissions->foreach($sender);
}
