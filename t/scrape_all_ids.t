#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 3;
use Test::Warnings;

use HTML::Scrape;

SIMPLE: {
    my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> simple </title>
    </head>
    <body>
        <p id="outer">
            This is a <span id="inner">inner tag</span>
            <input type="self-closing" />
            <br />
            and <span id="inner2">another inner</span>.
            <br>
        </p>
    </body>
</html>
HTML

    my $ids = HTML::Scrape::scrape_all_ids( $html );
    is_deeply( $ids, {
        'inner2' => 'another inner',
        'inner'  => 'inner tag',
        'outer'  => 'This is a inner tag and another inner.'
    } );
}


UNCLOSED_TAGS_THAT_ARE_OK: {
    my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> unclosed </title>
    </head>
    <body>
        <ul>
            <li id="one"> uno
            <li id="two"> dos
            <li id="three"> tres </li>
            <li id="four"> cuatro
        </ul>
        <p id="p1">
        stuff
        </p>
        <p id="p2">
        more stuff
        <p id="p3">
        still more stuff
    </body>
</html>
HTML

    my $ids = HTML::Scrape::scrape_all_ids( $html );
    is_deeply( $ids, {
        'one'   => 'uno',
        'two'   => 'dos',
        'three' => 'tres',
        'four'  => 'cuatro',
        'p1'    => 'stuff',
        'p2'    => 'more stuff',
        'p3'    => 'still more stuff',
    } );
}
exit 0;
