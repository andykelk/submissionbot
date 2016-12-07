use strict;
use warnings;

use lib './lib';

use Slack;
use Submissions;
use SubmissionSite;

use YAML;
use Log::Log4perl;

my $config = YAML::LoadFile('config.yaml');
Log::Log4perl->easy_init({
  level => Log::Log4perl::Level::to_priority($config->{logLevel} || 'WARN'),
  file  => ">>submissionbot.log"
});

Log::Log4perl->get_logger()->info('Starting poll...');
my $submissionSite = SubmissionSite->new($config->{submissionsBase});
$submissionSite->login($config->{signInPath}, $config->{email}, $config->{password});
Log::Log4perl->get_logger()->debug('Logged in.');
my $slack = Slack->new();
foreach my $streamId (keys %{$config->{channelMapping}}) {
  Log::Log4perl->get_logger()->info('Getting list for ' . $streamId . '.');
  my $submissions = $submissionSite->getList($config->{itemPath}, $streamId);
  $submissions->removeAlreadySeen();
  my $sender = sub {$slack->sendMessage(shift, $config->{channelMapping}->{$streamId})};
  $submissions->foreach($sender);
}
Log::Log4perl->get_logger()->info('Finished poll.');
