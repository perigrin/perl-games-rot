use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Feature::Compat::Class;
use Term::Screen;
use Term::ANSIColor;

package Games::ROT::Color {
    my sub htoi($hex) { unpack('l', pack( 'L', hex($hex))) }

    sub css_to_ansi ($css) {
        if (length($css) == 4) {
            my ($h, $r, $g, $b) = map { htoi("$_"x2) if !m/#/  } split //, $css;
            return "r${r}g${g}b${b}";
        }
        if (length($css) == 7) {
            my $r = htoi(substr($css, 1,2));
            my $g = htoi(substr($css, 3,2));
            my $b = htoi(substr($css, 5,2));
            return "r${r}g${g}b${b}";
        }
    }
}

class Games::ROT::Event {
    field $key :param;
    field $type = 'keydown'; # we only handle keydown events currently

    method key { $key }
    method type { $type }
}

class Games::ROT {
    field $title :param = 'My Game';
    field $screen_height :param //= 80;
    field $screen_width  :param //= 50;
    field $tile_height   :param //= 1;
    field $tile_width    :param //= 1;
    field $depth :param = 32;

    field $term = Term::Screen->new();
    # TODO this _should_ be a default assignment, but that doesn't work pre 5.38.0
    ADJUST {
        $term->rows($screen_height);
        $term->cols($screen_width);
        $term->noecho();
        $term->curinvis();
        $term->clrscr();
    }

    field %event_handlers = ();

    ADJUST { }

    method clear() {
        $term->clrscr();
    }

    method draw($x, $y, $text, $fg, $bg) {
        my $fgc = Games::ROT::Color::css_to_ansi($fg);
        my $bgc = Games::ROT::Color::css_to_ansi($bg);
        $x *= $tile_width;
        $y *= $tile_height;
        $term->at($y, $x)->puts(main::colored($text, $fgc, "on_$bgc"));
    }

    method add_event_handler($type, $handler) {
        $event_handlers{$type} = $handler;
    }

    method run($step) {
        while(1) {
            if ($term->key_pressed(1)) {
                my $c = $term->getch;
                my $e = Games::ROT::Event->new(key => $c);
                $event_handlers{'keydown'}->($e);
            }
            $step->();
        }
    }

    method display { $self }

    method DESTROY { exec('stty sane') }
}

1;
__END__
