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

  use Timer::Simple ();
  my $t = Timer::Simple->new();
  do_something;
  print "something took: $t\n";

  # or take more control

  my $timer = Timer::Simple->new(start => 0);
    do_something_before;
  $timer->start;
    do_something_else;
  print "time so far: ", $t->elapsed, " seconds\n";
    do_a_little_more;
  print "time so far: ", $t->elapsed, " seconds\n";
    do_still_more;
  $timer->stop;
    do_something_after;
  printf "whole process lasted %d hours %d minutes %f seconds\n", $t->hms;

  $timer->restart; # use the same object to time something else

=head1 DESCRIPTION

This is a simple object to make timing an operation as easy as possible.

It uses L<Time::HiRes> if available (unless you tell it not to).

It stringifies to the elapsed time in an hours/minutes/seconds format
(default is C<00:00:00.000000> with L<Time::HiRes> or C<00:00:00> without).

This module aims to be small and efficient
and do what is useful in most cases,
while still offering some configurability to handle edge cases.

=head1 SEE ALSO

=for :list
* L<Time::Elapse> - eccentric API to a tied scalar
* L<Time::Progress> - Doesn't support L<Time::HiRes>
* L<Time::StopWatch> - tied scalar
* L<Dancer::Timer> - inside Dancer framework

=cut
