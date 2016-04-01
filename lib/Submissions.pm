use strict;
use warnings;

package Submissions;

use Storable;

sub createFromArrayRef {
  my ($class, $arrayRef, $itemPath, $streamId) = @_;

  my @submissions;
  foreach my $sub (@$arrayRef) {
    my @cols = $sub->look_down(_tag => 'td');
    my $id = $cols[0]->as_text;

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
    $closure->($sub);
  }
}

sub removeAlreadySeen {
  my ($self) = @_;

  $self->loadState();

  my @newSubmissions;
  foreach my $sub (@{$self->{subs}}) {
    next if exists $self->{alreadySeen}->{$sub->{id}};
    push @newSubmissions, $sub;
    $self->{alreadySeen}->{$sub->{id}} = 1;
  }
  $self->{subs} = \@newSubmissions;
  $self->saveState();
}

sub loadState {
  my ($self) = @_;

  $self->{alreadySeen} = {};
  if (-e $self->{stateFile}) {
    $self->{alreadySeen} = Storable::retrieve($self->{stateFile});
  }
}

sub saveState {
  my ($self) = @_;

  Storable::store($self->{alreadySeen}, $self->{stateFile});
}
1;
