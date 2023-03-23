use strict;
use feature 'signatures';
no warnings 'experimental::signatures';

use Feature::Compat::Class;
use SDL;
use SDL::Event;
use SDLx::App;

package Games::ROT::Color {
    sub css_to_hex ($css) {
        my %map = (
            '#fff'    => 0xFFFFFFFF,
            '#000'    => 0x000000FF,
            '#323296' => 0x323296FF,
            '#000064' => 0x000064FF,
            '#ffff00' => 0xFFFF00FF,
        );
        return $map{$css};
    }
}


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
	field $screen_height :param //= 80;
	field $screen_width  :param //= 50;
    field $tile_height   :param //= 10;
    field $tile_width    :param //= 10;
	field $depth :param = 32;

    field $app;
    # TODO this _should_ be a default assignment, but that doesn't work pre 5.38.0
    ADJUST {
        $app = SDLx::App->new(
            title        => $title,
            height       => $screen_height * $tile_height,
            width        => $screen_width * $tile_width,
            depth        => $depth,
            exit_on_quit => 1,
        );
    }

    field %event_handlers = {
        quit => sub($e) { $e->controller->stop() },
    };

    ADJUST {
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
        my $fgc = Games::ROT::Color::css_to_hex($fg);
        my $bgc = Games::ROT::Color::css_to_hex($bg);
        $x *= $tile_width;
        $y *= $tile_height;
        $app->draw_rect([$x, $y, $tile_width, $tile_height], $bgc);
		$app->draw_gfx_text([$x, $y], $fgc, $text);
	}

    method update() {
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

    method run() { $app->run() }

    method display() { $self }
}

