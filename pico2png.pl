#!/usr/bin/perl
use strict;
use warnings;
use Imager;
use File::Slurp;

use constant {
    SPRITE_WIDTH  => 128,
    SPRITE_HEIGHT => 128,
};

my %web2pico = (
    '#000000' => '0', '#1d2b53' => '1', '#7e2553' => '2', '#008751' => '3',
    '#ab5236' => '4', '#5f574f' => '5', '#c2c3c7' => '6', '#fff1e8' => '7',
    '#ff004d' => '8', '#ffa300' => '9', '#ffff27' => 'a', '#00e756' => 'b',
    '#29adff' => 'c', '#83769c' => 'd', '#ff77a8' => 'e', '#ffccaa' => 'f',
);

my %pico2web = (
    '0' => '#000000', '1' => '#1d2b53', '2' => '#7e2553', '3' => '#008751',
    '4' => '#ab5236', '5' => '#5f574f', '6' => '#c2c3c7', '7' => '#fff1e8',
    '8' => '#ff004d', '9' => '#ffa300', 'a' => '#ffff27', 'b' => '#00e756',
    'c' => '#29adff', 'd' => '#83769c', 'e' => '#ff77a8', 'f' => '#ffccaa'
);

my $input_file = $ARGV[0] or die <<"_USAGE_";
usage:
        $0 cart.p8
           - creates a 128x128 spritesheet named cart_sprites.png
        $0 cart_sprites.png
           - copy the content of the spritesheet into the gfx part of the cart
_USAGE_

if ( $input_file =~ /_sprites\.png$/ ) {
    print "Converting PNG sprites to GFX...\n";
    png2gfx($input_file);
}
elsif ( $input_file =~ /\.p8$/ ) {
    print "Converting GFX to PNG...\n";
    gfx2png($input_file);
}

# Creates a PNG from the __gfx__ part of a cart
sub gfx2png {
    my $p8_file = shift;

    my $p8 = read_file($p8_file) or die "Cannot read $p8_file: $!\n";

    $p8 =~ /__gfx__(.*)__gff__/s;
    my $gfx = $1;

    die "Cannot find gfx in $p8_file\n" unless $gfx;

    $gfx =~ s/^\s*|\s*$//g;

    my $sprites = Imager->new( xsize => SPRITE_WIDTH, ysize => SPRITE_HEIGHT );

    my @rows = split( /\n/, $gfx );
    my $y;
    foreach my $row (@rows) {
        my @pixels = split( //, $row );
        my $x;
        foreach my $pixel (@pixels) {
            $sprites->setpixel(
                x     => $x++,
                y     => $y,
                color => $pico2web{$pixel}
            );
        }

        $y++;
    }

    $p8_file =~ s/\.p8$/_sprites.png/;

    $sprites->write( file => $p8_file )
      or die $sprites->errstr;

    print "Spritesheet created: $p8_file\n";
}

# Updates a cart __gfx__ with a PNG
sub png2gfx {
    my $png_file = shift;

    ( my $p8_file = $png_file ) =~ s/_sprites\.png$/.p8/;
    if ( !-e $p8_file ) {
        die "No cart \"$p8_file found\n";
    }

    my @p8 = read_file($p8_file) or die "Cannot read $p8_file: $!\n";

    my $img = Imager->new;
    $img->read( file => $png_file ) or die $img->errstr;

    my $w = $img->getwidth();
    my $h = $img->getheight();

    if ( $w != SPRITE_WIDTH && $h != SPRITE_HEIGHT ) {
        die "PNG must be "
          . SPRITE_WIDTH . "x"
          . SPRITE_HEIGHT
          . " (not ${w}x${h}\n";
    }

    open( my $p8_cart, ">", $p8_file )
      or die "Cannot open $p8_file for writing: $!\n";

    foreach (@p8) {
        print $p8_cart $_;
        last if /__gfx__/;
    }

    for my $y ( 0 .. SPRITE_HEIGHT - 1 ) {
        for my $x ( 0 .. SPRITE_WIDTH - 1 ) {
            my $color = $img->getpixel( x => $x, y => $y );

            my $web = to_web($color);

            if ( exists $web2pico{$web} ) {
                print $p8_cart $web2pico{$web};
            }
            else {
                warn "Error pix: "
                  . ( $x + 1 ) . ","
                  . ( $y + 1 ) . ": "
                  . $web . "\n";
                print $p8_cart "0";
            }

        }
        print $p8_cart "\n";
    }

    my $ok = 0;
    foreach (@p8) {
        next unless $ok or /__gff__/;
        $ok = 1;
        print $p8_cart $_;
    }

    close $p8_cart;
}

sub to_web {
    my ($color) = @_;
    my ( $r, $g, $b ) = $color->rgba();
    sprintf( '#%02x%02x%02x', $r, $g, $b );
}

