# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
package Timer::Simple;
# ABSTRACT: Small, simple timer (stopwatch) object

use strict;
use warnings;
use overload '""' => \&string, fallback => 1; # core

{
  # only perform the check once, but don't perform the check until required
  my $HIRES;
  sub HIRES () {
    $HIRES = (do { local $@; eval { require Time::HiRes; 1; } } || '')
      if !defined($HIRES);
    return $HIRES;
  }
}

sub new {
  my $class = shift;
  my $self = {
    start => 1,
    hires => HIRES,
    @_ == 1 ? %{$_[0]} : @_,
  };

  # float: 9 (width) - 6 (precision) - 1 (dot) == 2 digits (before decimal point)
  $self->{format} ||= '%02d:%02d:'
    . ($self->{hires} ? '%09.6f' : '%02d');

  bless $self, $class;

  $self->start
    if $self->{start};

  return $self;
}

sub hms {
  my ($self, $format) = @_;

  my $s  = $self->seconds;
  # find the number of whole hours/minutes, then subtract them
  my $h  = int($s / 3600);
     $s -=     $h * 3600;
  my $m  = int($s / 60);
     $s -=     $m * 60;

  return wantarray
    ? ($h, $m, $s)
    : sprintf(($format || $self->{format}), $h, $m, $s);
}

sub seconds {
  my ($self) = @_;

  if( !defined($self->{started}) ){
    # lazy load Carp since this is the only place we use it
    require Carp; # core
    Carp::croak("Timer never started!");
  }

  # if stop() was called use that time, otherwise "now"
  my $seconds = defined($self->{stopped})
    ? $self->{stopped}
    : $self->time;

  return $self->{hires}
    ? Time::HiRes::tv_interval($self->{started}, $seconds)
    : $seconds - $self->{started};
}

sub start {
  my ($self) = @_;

  # don't use an old stopped time if we're restarting
  delete $self->{stopped};

  $self->{started} = $self->time;
}

sub stop {
  my ($self) = @_;
  $self->{stopped} = $self->time;
}

sub string {
  scalar $_[0]->hms;
}

sub time {
  return $_[0]->{hires}
    ? [ Time::HiRes::gettimeofday() ]
    : time;
}

{
  # aliases
  no warnings 'once';
  *restart = \&start;
  *elapsed = \&seconds;
}

1;

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
