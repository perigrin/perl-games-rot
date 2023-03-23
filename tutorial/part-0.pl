#!/usr/bin/env perl
use strict;
use lib qw(lib);
use Feature::Compat::Class; # or 5.38.0 + feature "class"

use Games::ROT;

class Engine {
    my $WIDTH = 80;
    my $HEIGHT = 50;

    field $app = Games::ROT->new(
        screen_width  => $WIDTH,
        screen_height => $HEIGHT,
    );

    ADJUST {
        $app->add_show_handler( sub { $self->render() } );
        $app->run();
    }

    method render() {
        my $x = $WIDTH / 2;
        my $y = $HEIGHT / 2;

        $app->draw($x, $y, 'Hello World', '#fff', '#000');
    }
}

my $engine = Engine->new();
