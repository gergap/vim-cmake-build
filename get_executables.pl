#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use XML::Twig;

my $project;

sub load_cbp {
    my $filename = shift;
    my $twig = XML::Twig->new();

#    print STDERR "Parsing XML file...\n";
    $twig->parsefile($filename);
#    print STDERR "Converting to tree structure...\n";
    $project = $twig->simplify(
        keyattr => {
#            'Target'        => '+title',
        },
        forcearray => [
            'Target',
            'Option',
        ]);
}

sub print_executables {
    my $build = $project->{'Project'}->{'Build'};
    my $exe;
    my %unique;

#    print Dumper($build);

    foreach my $target (@{$build->{'Target'}}) {
#                print "title=$target->{'title'}\n";
        foreach my $option (@{$target->{'Option'}}) {
            if ($option->{'output'}) {
                $exe = $option->{'output'};
#                print "exe=$exe\n";
            }
            if ($option->{'type'}) {
#                print "type=$option->{'type'}\n";
            }
            # Possible types:
            # 0 .. GUI Application
            # 1 .. Console Application
            # 2 .. Static Library
            # 3 .. Dynamic Library
            # 4 .. Commands only
            # 5 .. Native excutable (Windows .sys file)
            if ($option->{'type'} && ($option->{'type'} eq 0 || $option->{'type'} eq 1)) {
                $unique{$exe}++;
                last;
            }
        }
    }

    foreach $exe (sort keys %unique) {
        print "$exe\n";
    }
}

load_cbp($ARGV[0]);
print_executables();

__END__

=head1 NAME

get_executables.pl - [description here]

=head1 VERSION

This documentation refers to get_executables.pl version 0.0.1

=head1 USAGE

    get_executables.pl [options]

=head1 REQUIRED ARGUMENTS

=over

None

=back

=head1 OPTIONS

=over

None

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 BUGS

None reported.
Bug reports and other feedback are most welcome.


=head1 AUTHOR

Gerhard Gappmeier C<< gergap@cpan.org >>


=head1 COPYRIGHT

Copyright (c) 2018, Gerhard Gappmeier C<< <gergap@cpan.org> >>. All rights reserved.

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


