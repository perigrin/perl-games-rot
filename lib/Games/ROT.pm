use strict;
use Feature::Compat::Class;
use SDL;
use SDLx::App;

class Games::ROT {
	field $title :param = 'My Game';
	field $height :param;
	field $width :param;
	field $depth :param = 32;

	field $app;

    ADJUST {
		$app = SDLx::App->new(
			title  => $title,
			height => $height,
			width  => $width,
			depth  => $depth,
			exit_on_quit => 1,
		);
    }

	method draw($x, $y, $text, $fg, $bg) {
		#TODO figure out colors
		$app->draw_gfx_text([$x, $y], [255, 255, 255, 255], $text);
		$app->update();
		$app->run();
	}
}

