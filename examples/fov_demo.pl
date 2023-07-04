use 5.38.0;
use warnings;

use lib qw(lib);
use Games::ROT::FOV;
use List::Util qw(any);

use Data::Dumper;

# 1s are obstructions, 0s are not
my @map = (
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
);

sub is_unobstructed($cell) {my ($x, $y) = @$cell;  $map[$x][$y] }

my $center_x = int($map[0]->$#* / 2);
my $center_y = int(@map/2);

my $radius = 10;

sub print_row($row, @cells) {
    my $out = '';

    for my $col (0..$map[0]->$#*) {
        if ("$col:$row" eq  "$center_x:$center_y") {
            $out .= '@';
        }
        elsif (grep {"$col:$row" eq join ':', @$_ } @cells ) {
            $out .= is_unobstructed([$col, $row]) ? 'X' : '.';
        }
        else {
            $out .= ' ';
        }
    }
    say $out;
}

sub print_map_vision(@cells) {
    for my $row(0..$#map) {
        print_row($row, @cells);
    }
}


my $fov = Games::ROT::FOV->new();

say "default settings:";
{
    my @cells = $fov->calc_visible_cells_from($center_x, $center_y, $radius, \&is_unobstructed);
    print_map_vision(@cells);
}

say "most restrictive settings:";
{
    local $FOV::NOT_VISIBLE_BLOCKS_VISION = 1;
    local $FOV::RESTRICTIVENESS = 2;
    local $FOV::VISIBLE_ON_EQUAL = 0;

    my @cells = $fov->calc_visible_cells_from($center_x, $center_y, $radius, \&is_unobstructed);
    print_map_vision(@cells);
}

say "least restrictive settings:";
{
    local $FOV::NOT_VISIBLE_BLOCKS_VISION = 0;
    local $FOV::RESTRICTIVENESS = 0;
    local $FOV::VISIBLE_ON_EQUAL = 1;

    my @cells = $fov->calc_visible_cells_from($center_x, $center_y, $radius, \&is_unobstructed);
    print_map_vision(@cells);
}

