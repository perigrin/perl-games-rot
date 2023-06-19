# Games::ROT

A Perl library inspired by [ROT.js](https://ondras.github.io/rot.js/hp/) the ROuglelike Toolkit for JavaScript/TypeScript.

## Synopsis

```perl
#!/usr/bin/env perl
use strict;
use lib qw(lib);
use Feature::Compat::Class;

use Games::ROT;

class Engine {
    my $WIDTH = 800;
    my $HEIGHT = 500;

    field $display = Games::ROT->new(
        width  => $WIDTH,
        height => $HEIGHT,
    );

    method render() {
        my $x = $WIDTH / 2;
        my $y = $HEIGHT / 2;

        $display->draw($x, $y, 'Hello World', '#fff', '#000');
    }
}

my $engine = Engine->new();
$engine->render();
```
