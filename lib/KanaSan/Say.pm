package KanaSan::Say;
use strict;
use warnings;
use utf8;

sub perform {
    my $job = shift;
    system(@{$job->args});
};

1;
