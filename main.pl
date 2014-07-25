use Mojolicious::Lite;
use Resque;
use Mojo::UserAgent;
use File::Basename;
use lib dirname(__FILE__).'/lib';

app->plugin(
    config => {
        file => app->home->rel_file('config.pl'),
        stash_key => 'config',
    },
);

app->plugin('charset'=> {charset => 'UTF-8'});

app->helper(resque => sub {
    my $self = shift;
    Resque->new(%{$self->config->{Resque}});
});

app->plugin('xslate_renderer', {
    template_options => {
        syntax => 'TTerse',
    },
});

app->helper(_base_url => sub {
    my $self = shift;
    my $url = $self->req->url->to_abs;
    return $url->scheme . '://' . $url->host . ':' . $url->port;
});

get '/' => sub {
    my $self = shift;
    $self->stash->{base_url} = $self->_base_url;
    $self->render();
} => 'index';

post '/api' => sub {
    my $self = shift;

    my $text = $self->param('text');
    if ( ! defined $text || defined $text && $text eq "" ) {
        return $self->render(text => 'ng');
    }

    if (length($text) > 200) {
        $text = substr($text, 0, 200);
    }

    my $cmd = $self->config->{cmd} || '/usr/local/bin/SayKana';

    my @opts;
    if (my $v = $self->param('v')) {
        push @opts, '-v', $v eq 'f1' ? 'f1' : 'm1';
    }

    if (my $s = $self->param('s')) {
        if ($s > 300) { $s = 300; }
        elsif ($s < 50) { $s = 50; }
        push @opts, '-s', $s;
    }

    my @cmds;
    push @cmds, $cmd;
    push @cmds, @opts;
    push @cmds, $text;

    $self->resque->push('say' => {
        class => 'KanaSan::Say',
        args  => \@cmds,
    });

    return $self->render(text => 'ok');
};

app->start;
