#!/usr/bin/perl

use strict;
use File::Basename;

my $dirin = $ARGV[0];
my $dirout = $ARGV[1];


my @files = <$dirin/*>;

foreach my $file (@files) {
    (my $fname, my $fdir, my $fsuf) = fileparse($file, qr{\.\d+-gram});
    print $fdir, " \t ", $fname, " \t ", $fsuf, " \n ";
    open (IN, "<$file");
    open (OUT, ">$dirout/$fname$fsuf");
    while (my $line = <IN>) {
	chomp ($line);
	my @lines = split(/\t*\#/, $line);
	print OUT shift(@lines), "\n";
	shift(@lines);
	(my $aux = shift(@lines)) =~ s/\s//g;
	print OUT "grammar=\'$aux\'\n";
	foreach my $item (@lines) {
	    (my $aux = $item) =~ s/\s//g;
	    print OUT "$aux\n";
	}
	print OUT "#####\n"
    }
    close (IN);
    close (OUT);
}
