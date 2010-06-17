package TextpressoStringBool;

# Package provides simple (Boolean) operations on
# string indices
# (c) 2008 Hans-Michael Muller, Caltech, Pasadena.

use TextpressoDatabaseGlobals;
use TextpressoGeneralTasks;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(stringand stringor stringnot stringnextneighbor);

sub stringand {

    my $a = shift;
    my $b = shift;
    return "" unless ($a && $b);
    if (length($a) > length($b)) {
	my $aux = $b;
	$b = $a;
	$a = $aux;
    }
    my %ra = ParseSenAndPos($a);
    my %rb = ParseSenAndPos($b);
    my $result = "";
    my %done = ();
    foreach my $k (keys % ra) {
	if (!$done{$k}) {
	    if (exists($rb{$k})) {
		foreach (@{$ra{$k}}) {
		    $result .= " $k-$_";
		}
		foreach (@{$rb{$k}}) {
		    $result .= " $k-$_";
		}
		$done{$k} = 1;
	    }
	}
    }

    return $result;
}

sub stringor {

    my $a = shift;
    my $b = shift;

    return $a . $b; 
}

sub stringnot {

    my $a = shift;
    my $b = shift;
    return "" unless $a;
    my %ra = ParseSenAndPos($a);
    my %rb = ParseSenAndPos($b);
    my $result = "";
    my %done = ();
    foreach my $k (keys % ra) {
	if (!$done{$k}) {
	    unless (exists($rb{$k})) {
		foreach (@{$ra{$k}}) {
		    $result .= " $k-$_";
		}
		foreach (@{$rb{$k}}) {
		    $result .= " $k-$_";
		}
		$done{$k} = 1;
	    }
	}
    }

    return $result;
}

sub stringnextneighbor {

    my @allstrings = @_;
    my @AofH = ();
    foreach (@allstrings) {
	push @AofH, { ParseSenAndPos($_) };
    }
    my @relevantkeys = (keys % {$AofH[0]});
    for (my $i = 1; $i < @AofH; $i++) {
	if (@relevantkeys) {
	    my @aux = ();
	    foreach (@relevantkeys) {
		push @aux, $_ if exists($AofH[$i]{$_});
	    }
	    @relevantkeys = @aux;
	}
    }
    my $result = "";
    foreach my $k (@relevantkeys) {
	foreach my $v (@{$AofH[0]{$k}}) {
	    my $resaux = " $k-$v";
	    my $ct = 1;
	    for (my $i = 1; $i < @AofH; $i++) {
		my $nv = $v + $i;
		my $j = scalar(@{$AofH[$i]{$k}}); 
		$j-- until (($AofH[$i]{$k}[$j] == $nv) || ($j < 0));
		last if ($j < 0);
		$resaux .= " $k-$nv";
		$ct++;
	    }
	    $result .= $resaux if (scalar(@allstrings) == $ct);
	}
    }

    return $result;
}

sub ParseSenAndPos {

    my $s = shift;
    my %r = ();
    return %r unless $s;
    my $ls = length($s);
    my $i = (index($s, " ", 0)) ? - 1 : 0;
    while ($i < $ls) {
	my $mi = index($s, "-", $i); # pos of '-'
	last unless ($mi+1);
	my $k = substr($s, $i+1, $mi-$i-1); # sentence number
	my $nesp = index($s, " ", $mi); # next space
	my $p; # position within sentence
	if ($nesp+1) {
	    $p = substr($s, $mi+1, $nesp-$mi-1);
	    $i = $nesp;
	} else {
	    $p = substr($s, $mi+1, $ls-$mi-1);
	    $i = $ls;
	}
	push @{$r{$k}}, $p;
    }

    return %r;
}

1;
