package HTML::Scrape;

use 5.10.1;
use strict;
use warnings;

=head1 NAME

HTML::Scrape - The great new HTML::Scrape!

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

use HTML::Parser;
use HTML::TokeParser;
use HTML::Tagset;


=head1 SYNOPSIS

Handy helpers for common HTML scraping tasks.

    use HTML::Scrape;

    my $ids = HTML::Scrape::scrape_all_ids( $html );

=head1 FUNCTIONS

=head2 scrape_id( $id, $html )

Scrapes the text of the single ID C<$id> from C<$html>.

=cut

sub scrape_id {
    my $id = shift;
    my $html = shift;

    my $all_ids = scrape_all_ids( $html, $id );

    return $all_ids->{$id};
}


=head2 scrape_all_ids( $html [, $specific_id ] )

Parses the entire web page and returns all the text in a hashref keyed on ID.

If you pass in C<$specific_id>, then only that ID will be scraped,
and parsing will stop once it is found. The better way to do this is by
calling C<scrape_id>.

=cut

sub scrape_all_ids {
    my $html      = shift;
    my $wanted_id = shift;

    my $p = HTML::Parser->new(
        start_h => [ \&_parser_handle_start, 'self, tagname, attr, line, column' ],
        end_h   => [ \&_parser_handle_end,   'self, tagname, line, column' ],
        text_h  => [ \&_parser_handle_text,  'self, dtext' ],
    );
    $p->{stack} = [];
    $p->{ids} = {};
    if ( defined $wanted_id ) {
        $p->{wanted_id} = $wanted_id;
    }

    $p->empty_element_tags(1);
    $p->parse($html);
    $p->eof;

    if ( !defined $wanted_id ) {
        # With a wanted_id, we would have stopped parsing early and left tags on the stack, so don't check.
        if ( my $n = scalar @{$p->{stack}} ) {
            warn "$n tag(s) unclosed at end of document.\n";
        }
    }

    return $p->{ids};
}


sub _parser_handle_start {
    my $parser  = shift;
    my $tagname = shift;
    my $attr    = shift;
    my $line    = shift;
    my $column  = shift;

    return if $HTML::Tagset::emptyElement{$tagname};

    my $id = $attr->{id};

    # If it's a dupe ID, warn and ignore the ID.
    if ( defined($id) && exists $parser->{ids}{$id} ) {
        warn "Duplicate ID $id found in <$tagname> at $line:$column\n";
        $id = undef;
    }

    my $stack = $parser->{stack};

    # Tags like <p> and <li> that don't have to close themselves get closed another of them comes along.
    # For example:
    # <ul>
    #     <li id="x">whatever
    #     <li id="y">thingy
    # </ul>
    if ( $HTML::Tagset::optionalEndTag{$tagname} && @{$stack} && $stack->[-1][0] eq $tagname ) {
        my $item = pop @{$stack};
        _close_tag( $parser, $item );
    }

    push @{$stack}, [ $tagname, $id, '' ];

    return;
}


sub _parser_handle_end {
    my $parser  = shift;
    my $tagname = shift;
    my $line    = shift;
    my $column  = shift;

    return if $HTML::Tagset::emptyElement{$tagname};

    my $stack = $parser->{stack};

    # Deal with tags that close others.
    if ( @{$stack} ) {
        my $previous_item = $stack->[-1];
        my $previous_tagname = $previous_item->[0];

        #warn "tagname $tagname hprase markup = " , $HTML::Tagset::isPhraseMarkup{$tagname} // 'undef', ' previous = ' . $previous_tagname;
        my $this_tag_closes_previous_one =
            ( $tagname ne $previous_tagname ) 
            &&
            (
                ( ($tagname eq 'ul' || $tagname eq 'ol') && $previous_tagname eq 'li' )
                ||
                ( ($tagname eq 'dl') && ($previous_tagname eq 'dt' || $previous_tagname eq 'dd') )
                ||
                ( !$HTML::Tagset::isPhraseMarkup{$tagname} && $previous_tagname eq 'p' )
            )
        ;
        if ( $this_tag_closes_previous_one ) {
            _close_tag( $parser, pop @{$stack} );
        }
    }

    if ( !@{$stack} ) {
        warn "Unexpected closing </$tagname> at $line:$column\n";
        return;
    }
    if ( $tagname ne $stack->[-1][0] ) {
        warn "Unexpected closing </$tagname> at $line:$column: Expecting </$stack->[-1][0]>\n";
        return;
    }

    _close_tag( $parser, pop @{$stack} );

    return;
}


sub _parser_handle_text {
    my $parser = shift;
    my $text   = shift;

    for my $item ( @{$parser->{stack}} ) {
        if ( $item->[1] ) { # Only accumulate text for tags with IDs.
            $item->[2] .= $text;
        }
    }

    return;
}


sub _close_tag {
    my $parser = shift;
    my $item   = shift;

    my (undef, $id, $text) = @{$item};
    if ( defined $id ) {
        my $keepit;

        if ( defined $parser->{wanted_id} ) {
            # We're searching for a specific ID.
            if ( $id eq $parser->{wanted_id} ) {
                $keepit = 1;
                $parser->eof;
            }
            else {
                # No need to keep the text of an ID we don't care about.
            }
        }
        else {
            $keepit = 1;
        }

        if ( $keepit ) {
            $text =~ s/^\s+//;
            $text =~ s/\s+$//;
            $text =~ s/\s+/ /g;
            $parser->{ids}{$id} = $text;
        }
    }

    return;
}


=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/petdance/html-scrape/issues>..

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Scrape

You can also look for information at:

=over 4

=item * Search CPAN

L<https://metacpan.org/release/HTML-Scrape>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Andy Lester.

This is free software, licensed under: The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of HTML::Scrape
