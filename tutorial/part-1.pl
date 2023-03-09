#!/usr/bin/env perl
use 5.34.0; # bump to 5.36.0 to remove the next two lines … and 5.38.0 to get `feature 'class'`
use feature 'signatures';
no warnings 'experimental::signatures';

use Feature::Compat::Class;
use lib qw(lib);

use Games::ROT;

class MovementAction {
    field $dx :param //= 0;
    field $dy :param //= 0;

    method dx { $dx }
    method dy { $dy }
}

sub handle_input($event) {
    my %MOVE_KEYS = (
        up    => MovementAction->new( dy => -10 ),
        down  => MovementAction->new( dy => 10 ),
        left  => MovementAction->new( dx => -10 ),
        right => MovementAction->new( dx => 10 ),
    );
    return $MOVE_KEYS{$event->key};
}

class Engine {
    my $WIDTH = 800;
    my $HEIGHT = 500;

    field $playerX = $WIDTH / 2;
    field $playerY = $WIDTH / 2;

    field $app = Games::ROT->new(
        width  => $WIDTH,
        height => $HEIGHT,
    );

    ADJUST {
        $app->add_event_handler(
            'keydown' => sub ($event) { $self->listen($event) }
        );
        $app->add_show_handler( sub { $self->render() } );
        $app->run();
    }

    method listen($event) {
        my $action = main::handle_input($event);
        if ( $action && $action->isa('MovementAction') ) {
            $playerX += $action->dx;
            $playerY += $action->dy;
        }
    }

    method render() {
        $app->clear();
        $app->draw($playerX, $playerY, '@', '#fff', '#000');
    }
}

my $engine = Engine->new();
