# pico2png

This script converts Pico8 graphics from/to PNG.

Usage is :

        pico2png.pl cart.p8
           - creates a 128x128 spritesheet named cart_sprites.png

        pico2png.pl cart_sprites.png
           - copy the content of the spritesheet into the gfx part of the cart


This script requires the [Imager](http://search.cpan.org/perldoc?Imager) and [File::Slurp](http://search.cpan.org/perldoc?File::Slurp) perl modules. You can install them with the following command :

    $ sudo cpan Imager File::Slurp

