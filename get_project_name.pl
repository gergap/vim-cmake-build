#! /usr/bin/perl
use strict;
use warnings;

my $filename = $ARGV[0];
open(my $fh, "<", $filename)
    or die "Can't open < '$filename' $!";

while (<$fh>) {
    if (/project\((\w+)(?:\s+(\w+))?\)/i) {
        print "$1";
        last;
    }
}

close($fh);

