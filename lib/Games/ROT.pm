use strict;
use feature 'signatures';
no warnings 'experimental::signatures';

use Feature::Compat::Class;
use SDL;
use SDL::Event;
use SDLx::App;

class Games::ROT::Event {
    field $event :param;
    field $controller :param;

    method controller { $controller }

    method key { SDL::Events::get_key_name($event->key_sym) }

    method type {
        for ( $event->type ) {
            return 'quit '   if $_ == SDL::Event::SDL_QUIT;
            return 'keydown' if $_ == SDL::Event::SDL_KEYDOWN;
        }
    }
}

class Games::ROT {
	field $title :param = 'My Game';
	field $height :param;
	field $width :param;
	field $depth :param = 32;

	field $app;
    field %event_handlers = {
        quit => sub($e) { $e->controller->stop() },
    };


    ADJUST {
        $app = SDLx::App->new(
            title        => $title,
            height       => $height,
            width        => $width,
            depth        => $depth,
            exit_on_quit => 1,
        );

        $app->add_event_handler(sub ( $event, $controller ) {
            my $e = Games::ROT::Event->new( event => $event, controller => $controller );
            if (my $handler = $event_handlers{ $e->type } ) {
                return $handler->($e);
            }
        });
    }

    method clear() {
        $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000FF);
    }

	method draw($x, $y, $text, $fg, $bg) {
		#TODO figure out colors
		$app->draw_gfx_text([$x, $y], [255, 255, 255, 255], $text);
		$app->update();
	}

    method add_move_handler($handler) {
        $app->add_move_handler(
            sub ( $step, $app, $t ) { $handler->( $step, $t ) }
        );
    }

    method add_show_handler($handler) {
        $app->add_show_handler(
            sub ( $delta, $app ) {
                $handler->();
                $app->update;
            }
        );
    }

    method add_event_handler($type, $handler) {
        $event_handlers{$type} = $handler;
    }

    method run { $app->run() }
}

