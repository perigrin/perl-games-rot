#!/usr/bin/env perl
use 5.38.0;

use lib qw(lib);
use experimental 'class';

use Games::ROT;

class QuitAction { }

class MovementAction {
    field $dx :param //= 0;
    field $dy :param //= 0;

    method dx { $dx }
    method dy { $dy }
}

class Engine {
    my $WIDTH = 80;
    my $HEIGHT = 50;

    field $playerX = $WIDTH / 2;
    field $playerY = $WIDTH / 2;

    field $app = Games::ROT->new(
        screen_width  => $WIDTH,
        screen_height => $HEIGHT,
    );

    ADJUST {
        $app->add_event_handler(
            'keydown' => sub ($event) { $self->listen($event) }
        );
        $app->run( sub { $self->render() } );
    }

    my sub handle_input($event) {
        my %MOVE_KEYS = (
            h => MovementAction->new( dx => -1 ),
            j => MovementAction->new( dy => 1 ),
            k => MovementAction->new( dy => -1 ),
            l => MovementAction->new( dx => 1 ),
            q => QuitAction->new(),
        );
        return $MOVE_KEYS{$event->key};
    }

    method listen($event) {
        my $action = handle_input($event);

        if ($action isa 'QuitAction') {
            $app->quit;
        }

        if ($action isa 'MovementAction') {
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
