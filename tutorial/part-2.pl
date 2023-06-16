#!/usr/bin/env perl
use 5.38.0;

use lib qw(lib);
use experimental 'class';

use Games::ROT;

class QuitAction {
    method perform($engine, $) { $engine->exit }
}

class MovementAction {
    field $dx :param //= 0;
    field $dy :param //= 0;

    method dx { $dx }
    method dy { $dy }

    method perform($engine, $entity) {
        my $x = $entity->x + $dx;
        my $y = $entity->y + $dy;
        my $map = $engine->game_map;

        return unless $map->is_in_bounds($x, $y);
        return unless $map->tile_at($x, $y)->is_walkable;

        $entity->move($dx, $dy);
    }
}

class Entity {
    field $x :param;
    field $y :param;
    field $char: param;
    field $fg :param //= '#fff';
    field $bg :param //= '#000';

    method x { $x }
    method y { $y }
    method char { $char }
    method fg { $fg }
    method bg { $bg }

    method move($dx, $dy) {
        $x += $dx;
        $y += $dy;
    }
}

class Tile {
    field $walkable :param;
    field $transparent :param;
    field $char :param //= '';
    field $fg :param //= '#fff';
    field $bg :param //= '#000';

    method is_walkable() { $walkable }
    method is_transparent { $transparent }
    method char() { $char }
    method fg() { $fg }
    method bg() { $bg }

    method clone() {
        Tile->new(
            walkable    => $walkable,
            transparent => $transparent,
            char        => $char,
            fg          => $fg,
            bg          => $bg
        );
    }
}

class GameMap {
    my $FLOOR_TILE = Tile->new(
        walkable    => 1,
        transparent => 1,
        bg          => '#323296',
    );
    my $WALL_TILE = Tile->new(
        walkable    => 0,
        transparent => 0,
        char        => '#',
        bg          => '#000064',
    );

    field $width   :param;
    field $height  :param;
    field $display :param;

    field @tiles = ([]);

    ADJUST {
        # initialize the map
        for my $y (0..$height) {
            my @row = ();
            for my $x (0..$width) {
                if ($y == 22 && 30 <= $x <= 32) {
                    $row[$x] = $WALL_TILE->clone();
                } else {
                    $row[$x] = $FLOOR_TILE->clone();
                }
            }
            $tiles[$y] = \@row;
        }
    }

    method is_in_bounds($x, $y) {
        return 0 <= $x < $width && 0 <= $y < $height;
    }

    method render() {
        for my $y (0..$#tiles) {
            my @row = $tiles[$y]->@*;
            for my $x (0..$#row) {
                my $tile = $row[$x];
                $display->draw($x, $y, $tile->char, $tile->fg, $tile->bg);
            }
        }
    }

    method tile_at($x, $y) {
        return $tiles[$y][$x];
    }
}

class Engine {
    our $WIDTH = 80;
    our $HEIGHT = 50;
    my $MAP_WIDTH = 80;
    my $MAP_HEIGHT = 45;

    field $app = Games::ROT->new(
        screen_width  => $WIDTH,
        screen_height => $HEIGHT,
    );

    field $game_map = GameMap->new(
        width   => $MAP_WIDTH,
        height  => $MAP_HEIGHT,
        display => $app->display(),
    );

    method game_map { $game_map }

    field $player :param;
    field $entities :param;

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
        $app->clear();

        if (my $action = handle_input($event)) {
            $action->perform($self, $player);
        }
    }

    method render() {
        $game_map->render();
        for my $e ($entities->@*) {
            $app->draw($e->x, $e->y, $e->char, $e->fg, $e->bg);
        }
    }
}


my $npc = Entity->new(
    x    => $Engine::WIDTH / 2 - 50,
    y    => $Engine::WIDTH / 2,
    char => '@',
    fg => '#ffff00',
);

my $player = Entity->new(
    x    => $Engine::WIDTH / 2,
    y    => $Engine::WIDHT / 2,
    char => '@',
);

my $engine = Engine->new( entities => [ $npc, $player ], player => $player );
