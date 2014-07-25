use strict;
use warnings;
use utf8;
use File::Basename;
use lib dirname(__FILE__).'/lib';

use Resque;

my $config = do 'config.pl';

my $cmd = $config->{cmd};
die "Not Found $cmd" unless -e $cmd;

my $worker = Resque->new(%{$config->{Resque}})->worker;
$worker->add_queue('say');
$worker->work;
