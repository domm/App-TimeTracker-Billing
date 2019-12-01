package App::TimeTracker::Command::Billing;
use strict;
use warnings;
use 5.010;

# ABSTRACT: add a billing point to each task

our $VERSION = "1.002";

use Moose::Role;

sub munge_start_attribs {
    my ( $class, $meta, $config ) = @_;
    my $cfg = $config->{billing};
    return unless $cfg && $cfg->{billing};

    $meta->add_attribute(
        'category' => {
            isa           => 'String',
            is            => 'ro',
            required      => $cfg->{required} || 0,
            documentation => 'Billing',
        }
    );
}
after '_load_attribs_start'    => \&munge_start_attribs;
after '_load_attribs_append'   => \&munge_start_attribs;
after '_load_attribs_continue' => \&munge_start_attribs;

before [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
    my $self = shift;

    if (my $bconf = $self->config->{billing}) {
        my $billing = $self->billing if $self->billing;
        warn "BILLING 1 $billing";
        if (!$billing && $bconf->{default}) {
            if ($bconf->{default} eq 'strftime') {
                warn "START ".$self->at;
                my $now = DateTime->now;
                my $format = $bconf->{strftime};
                $billing = $now->format($format);
            }
        }
        warn "BILLING 2 $billing";
        $self->add_tag( $billing ) if $billing;
    }
};

no Moose::Role;
1;

__END__

=head1 DESCRIPTION

Add a billing point to each task. Could be based on the current date (eg '2019/Q4' or '2019/11') or on some project name.

=head1 CONFIGURATION

=head2 plugins

Add C<Category> to the list of plugins.

=head2 category

add a hash named C<category>, containing the following keys:

=head3 required

Set to a true value if 'category' should be a required command line option

=head3 categories

A list (ARRAYREF) of category names.

=head1 NEW COMMANDS

=head2 statistic

Print stats on time worked per category

    domm@t430:~/validad$ tracker statistic --last day
    From 2016-01-29T00:00:00 to 2016-01-29T23:59:59 you worked on:
                                   07:39:03
       9.9%  bug                   00:45:23
      33.2%  feature               02:32:21
      28.3%  maint                 02:09:52
      12.9%  meeting               00:59:21
      15.7%  support               01:12:06

You can use the same options as in C<report> to define which tasks you
want stats on (C<--from, --until, --this, --last, --ftag, --fproject, ..>)

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue, append

=head3 --category

    ~/perl/Your-Project$ tracker start --category feature

Make sure that 'feature' is a valid category and store it as a tag.

