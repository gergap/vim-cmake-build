#!/usr/bin/perl

use strict;
use warnings;
use JSON::PP;
use File::Glob qw(bsd_glob);
use File::Spec;

my $project;

sub load_json {
    my $filename = shift;
    open my $file, '<', $filename or die "Cannot open '$filename': $!\n";
    local $/;
    my $json = <$file>;
    close $file;
    return decode_json($json);
}

sub print_executables {
    my ($build_dir, $configuration) = @_;
    my $reply_dir = File::Spec->catdir($build_dir, '.cmake', 'api', 'v1', 'reply');
    my @indexes = bsd_glob(File::Spec->catfile($reply_dir, 'index-*.json'));
    @indexes = sort @indexes;
    die "No CMake File API reply found\n" unless @indexes;

    my $index_file = $indexes[-1];
    my $index = load_json($index_file);
    my $reference = $index->{'reply'}->{'client-vim-cmake-build'}->{'codemodel-v2'};
    $reference ||= (grep { $_->{'kind'} eq 'codemodel' } @{$index->{'objects'} || []})[0];
    die "CMake did not provide a codemodel reply\n" unless $reference && $reference->{'jsonFile'};

    my $codemodel = load_json(File::Spec->catfile($reply_dir, $reference->{'jsonFile'}));
    my %unique;
    foreach my $config (@{$codemodel->{'configurations'} || []}) {
        next if defined($configuration) && $configuration ne '' && $config->{'name'} ne $configuration;
        foreach my $target_ref (@{$config->{'targets'} || []}) {
            my $target_file = File::Spec->catfile($reply_dir, $target_ref->{'jsonFile'});
            my $target = load_json($target_file);
            next unless ($target->{'type'} || '') eq 'EXECUTABLE';
            foreach my $artifact (@{$target->{'artifacts'} || []}) {
                my $path = $artifact->{'path'};
                next unless defined $path && $path ne '';
                $path = File::Spec->catfile($codemodel->{'paths'}->{'build'}, $path)
                    unless File::Spec->file_name_is_absolute($path);
                $unique{$path} = 1;
            }
        }
    }
    print "$_\n" for sort keys %unique;
}

if ($#ARGV < 0 || $#ARGV > 1) {
    print STDERR "Usage: $0 <build-dir> [configuration]\n";
    exit 1;
}

print_executables($ARGV[0], $ARGV[1]);

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
