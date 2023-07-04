use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Feature::Compat::Class;

# Restrictive Precise Angle Shadowcasting
# ported from https://github.com/MoyTW/roguebasin_rpas

# Holds the three angles for each cell. Near is closest to the
# horizontal/vertical line, and far is furthest.
#
# Also used for obstructions; for the purposes of obstructions, the center
# variable is ignored.
class CellAngles {
	field $near :param;
	field $center :param;
	field $far :param;

	method near($v=undef) { defined $v ? $near = $v : $near }
	method center($v=undef) { defined $v ? $center = $v : $center }
	method far($v=undef) { defined $v ?  $far = $v :  $far }

	method contains($point, $discrete) {
		$discrete ? $near < $point < $far : $near <= $point <= $far
	}
}

class Games::ROT::FOV {
	use List::Util qw(min max);
    # Changing the radius-fudge changes how smooth the edges of the vision bubble are.
    #
    # RADIUS_FUDGE should always be a value between 0 and 1.
    our $RADIUS_FUDGE = 1.0 / 3.0;

	# If this is False, some cells will unexpectedly be visible.
    #
    # For example, let's say you you have obstructions blocking (0.0 - 0.25) and (.33 - 1.0).
	# A far off cell with (near=0.25, center=0.3125, far=0.375) will have both
	# its near and center unblocked.
    #
	# On certain restrictiveness settings this will mean that it will be
	# visible, but the blocks in front of it will not, which is unexpected and
	# probably not desired.
    #
    # Setting it to True, however, makes the algorithm more restrictive.
    our $NOT_VISIBLE_BLOCKS_VISION = 1;

	# Determines how restrictive the algorithm is.
    #
    # 0 - if you have a line to the near, center, or far, it will return as visible
    # 1 - if you have a line to the center and at least one other corner it will return as visible
    # 2 - if you have a line to all the near, center, and far, it will return as visible
    #
    # If any other value is given, it will treat it as a 2.
    our $RESTRICTIVENESS = 1;

	# If VISIBLE_ON_EQUAL is False, an obstruction will obstruct its endpoints.
	# If True, it will not.
    #
	# For example, if there is an obstruction (0.0 - 0.25) and a square at
	# (0.25 - 0.5), the square's near angle will be unobstructed in True, and
	# obstructed on False.
    #
    # Setting this to False will make the algorithm more restrictive.
    our $VISIBLE_ON_EQUAL = 1;

	# Parameter func_transparent is a function with the sig: boolean func(x, y)
    # It should return True if the cell is transparent, and False otherwise.
    #
    # Returns a set with all (x, y) tuples visible from the centerpoint.
	method calc_visible_cells_from($x, $y, $r, $is_transparent) {
		my @cells = ();

		push @cells => $self->_visible_cells_in_quadrant_from(
			$x, $y, 1, 1, $r, $is_transparent);

		push @cells => $self->_visible_cells_in_quadrant_from(
			$x, $y, 1, -1, $r, $is_transparent);

		push @cells => $self->_visible_cells_in_quadrant_from(
			$x, $y, -1, -1, $r, $is_transparent);

		push @cells => $self->_visible_cells_in_quadrant_from(
			$x, $y, -1, 1, $r, $is_transparent);

		push @cells => [$x, $y];

		return @cells;
	}

	# Parameters quad_x, quad_y should only be 1 or -1. The combination of the
	# two determines the quadrant.
	#
    # Returns a set of (x, y) tuples.
	method _visible_cells_in_quadrant_from($x, $y, $dx, $dy, $r, $is_transparent) {
		my @cells = ();
		push @cells => $self->_visible_cells_in_octant_from($x, $y, $dx, $dy, $r, $is_transparent, 1);
		push @cells => $self->_visible_cells_in_octant_from($x, $y, $dx, $dy, $r, $is_transparent, 0);
		return @cells;
	}

	# Returns a set of (x, y) typles.
    # Utilizes the NOT_VISIBLE_BLOCKS_VISION variable.
	method _visible_cells_in_octant_from($x, $y, $dx, $dy, $radius, $is_transparent, $is_vertical) {
		my $iteration = 1;
		my @visible_cells = ();
		my @obstructions = ();

		# one object in the obstruction list covering the full angle from 0 to 1)
		my sub has_full_obstruction() {
			@obstructions == 1 && $obstructions[0]->near == 0.0 && $obstructions[0]->far == 1.0
		}

		while ($iteration < $radius && !has_full_obstruction()) {
			my $num_cells_in_row = $iteration + 1;
			my $angle_allocation = 1.0 / $num_cells_in_row;

            # Start at the center (vertical or horizontal line) and step outwards
			for my $step (0..$iteration + 1) {
				my $cell = $self->_cell_at($x, $y, $dx, $dy, $step, $iteration, $is_vertical);

				if ($self->_cell_in_radius($x, $y, $cell, $radius)) {
					my $cell_angles = CellAngles->new(
						near => $step * $angle_allocation,
						center => ($step + .5) * $angle_allocation,
						far => $step + 1 * $angle_allocation,
					);
					if ($self->_cell_is_visible($cell_angles, @obstructions)) {
						push @visible_cells => $cell;
						if ($is_transparent->($cell)) {
							@obstructions = $self->_add_obstruction($cell_angles, @obstructions);
						}
					}
					elsif ($NOT_VISIBLE_BLOCKS_VISION) {
						@obstructions = $self->_add_obstruction($cell_angles, @obstructions);
					}
				}
			}
			$iteration += 1;
		}
		return @visible_cells;
	}

    # Returns a (x, y) tuple.
	method _cell_at($x, $y, $dx, $dy, $step, $iteration, $is_vertical)  {
		return $is_vertical ?
			[$x + $step * $dx, $y + $iteration * $dy]:
			[$x + $iteration * $dx, $y + $step * $dy];
	}

    # Returns True/False.
	method _cell_in_radius($x, $y, $cell, $r) {
		my $cell_distance = sqrt (
								($x - $cell->[0]) * ($x - $cell->[0])
							  + ($y - $cell->[1]) * ($y - $cell->[1])
							);
		return $cell_distance <= $r + $RADIUS_FUDGE;
	}

	# Returns True/False.
    # Utilizes the VISIBLE_ON_EQUAL and RESTRICTIVENESS variables.
	method _cell_is_visible($cell_angles, @obstructions) {
		my $near_visible = 1;
		my $center_visible = 1;
		my $far_visible = 1;

		for my $o (@obstructions) {
			$near_visible   = 0 if $o->contains($cell_angles->near,   $VISIBLE_ON_EQUAL);
			$center_visible = 0 if $o->contains($cell_angles->center, $VISIBLE_ON_EQUAL);
			$far_visible    = 0 if $o->contains($cell_angles->far,    $VISIBLE_ON_EQUAL);
		}
		if ($RESTRICTIVENESS == 0) {
			return $center_visible || $near_visible || $far_visible;
		}
		elsif ($RESTRICTIVENESS == 1) {
			return ($center_visible && $near_visible) || ($center_visible && $far_visible)
		} else {
			return $center_visible && $near_visible && $far_visible;
		}
	}

	# Generates a new list by combining all old obstructions with the new one
	# (removing them if they are combined) and adding the resulting obstruction to
	# the list.
	# Returns the generated list.
	method _add_obstruction($cell, @list) {
		my $o = CellAngles->new(
			near   => $cell->near,
			center => $cell->center,
			far    => $cell->far,
		);

		my @new_list = grep { !$self->_combine_obstruction($_, $o) } @list;
		push @new_list, $o;
		return @new_list;
	}

    # Returns True if you combine, False otherwise
	method _combine_obstruction($old, $new) {
		my ($low, $high);

        # Pseudo-sort; if their near values are equal, they overlap
		if ($old->near < $new->near) {
			$low = $old;
			$high = $new;
		} elsif ($new->near < $old->near) {
			$low = $new;
			$high = $old;
		} else {
			$new->far(max($old->far, $new->far));
			return 1;
		}

		# if the overlap, combine and return true
		if ($low->far >= $high->near) {
			$new->near(min($low->near, $high->near));
			$new->far(max($low->far, $high->far));
			return 1;
		}

		return 0
	}
}
