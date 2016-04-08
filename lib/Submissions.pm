use strict;
use warnings;

package Submissions;

use Storable;
use Data::Dumper;

sub createFromArrayRef {
  my ($class, $arrayRef, $itemPath, $streamId) = @_;

  my @submissions;
  foreach my $sub (@$arrayRef) {
    my @cols = $sub->look_down(_tag => 'td');
    my $id = $cols[0]->as_text;

    Log::Log4perl->get_logger()->debug('Found submission ' . $id . ' (' . $cols[2]->as_text . ').');
    my $submission = {
      id => $id,
      name => $cols[2]->as_text,
      url => "$itemPath$id"
    };
    push @submissions, $submission;
  }
  my $self = {subs => \@submissions, stateFile => "alreadyseen-$streamId.storable"};

  bless $self, $class;
}

sub foreach {
  my ($self, $closure) = @_;
  foreach my $sub (@{$self->{subs}}) {
    Log::Log4perl->get_logger()->debug('Foreach loop reached with sub : ' . Data::Dumper->Dump($sub));
    $closure->($sub);
  }
}

sub removeAlreadySeen {
  my ($self) = @_;
  Log::Log4perl->get_logger()->info('Removing those already seen.');

  $self->loadState();

  my @newSubmissions;
  foreach my $sub (@{$self->{subs}}) {
    if (exists $self->{alreadySeen}->{$sub->{id}}) {
      Log::Log4perl->get_logger()->debug('Already seen ' . $sub->{id} . '. Removing.');
      next;
    }
    push @newSubmissions, $sub;
    $self->{alreadySeen}->{$sub->{id}} = 1;
  }
  $self->{subs} = \@newSubmissions;
  $self->saveState();
}

sub loadState {
  my ($self) = @_;

  Log::Log4perl->get_logger()->info('Loading state.');
  $self->{alreadySeen} = {};
  if (-e $self->{stateFile}) {
    Log::Log4perl->get_logger()->info('State file exists.');
    $self->{alreadySeen} = Storable::retrieve($self->{stateFile});
  }
}

sub saveState {
  my ($self) = @_;

  Log::Log4perl->get_logger()->info('Saving state.');
  Storable::store($self->{alreadySeen}, $self->{stateFile});
}
1;
