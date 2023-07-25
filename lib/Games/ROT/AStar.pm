package Games::ROT::AStar;
use strict;
use warnings;

use feature 'signatures';

use List::Util qw(any);

my sub manhattan_distance ( $h, $t ) {
    return abs( $h->[0] - $t->[0]  + $h->[1] - $t->[1] );
}

my sub equal_positions ( $n, $o ) {
    return $n->[0] == $o->[0] && $n->[1] == $o->[1];
}

my sub get_tiles_near ( $x, $y ) {
    map { [ $x + $_->[0], $y + $_->[1] ] }
      (
        [1,0],
        [0,1],
        [1,1],
        [-1,0],
        [0,-1],
        [-1,-1],
      );
}

sub get_path ( $map, $s, $e ) {
    my $start = { position => $s, f => 0, g => 0, h => 0 };
    my $enp   = { position => $e, f => 0, g => 0, h => 0 };

    my @fringe = ($start);
    my %closed = ();
    my sub id ($n) { join ':', $n->{position}->@* }

    while (@fringe) {
        my $current = shift @fringe;
        $closed{ id($current) } = $current;

        if ( equal_positions( $current->{position}, $enp->{position} ) ) {
            my @path;
            my $c = $current;
            do { unshift @path, $c->{position} } while ( $c = $c->{parent} );
            return @path;
        }

        my @edge = map {
            {
                parent   => $current,
                position => $_,
                f        => 0,
                g        => 0,
                h        => 0,
            }
          }
          grep { $map->tile_at(@$_)->is_walkable() }
          get_tiles_near( $current->{position}->@* );


        for my $e (@edge) {
            next if exists $closed{ id($e) };

            $e->{g} = $current->{g} + 1;
            $e->{h} = manhattan_distance( $e->{position}, $enp->{position} );
            $e->{f} = $e->{g} + $e->{h};

            next if any { $e->{g} < $_->{g} } @fringe;
            push @fringe, $e;
        }
        # keep fringe sorted by f
        @fringe = sort { $a->{f} > $b->{f} } @fringe;
    }
    return;
}

1;
__END__
