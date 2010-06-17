package TextpressoDatabaseSearch;

# Package provides class and methods for
# database searches in the Textpresso
# system.
#
# (c) 2004-8 Hans-Michael Muller, Caltech, Pasadena.

use TextpressoDatabaseGlobals;
use TextpressoGeneralTasks;
use TextpressoStringBool;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(textpressosearch readindexfile litkey getstopwords readresults saveresults booleanand booleanor booleannot);

sub textpressosearch {
    
    my $query = shift; # pointer to a TextpressDatabaseQuery object;
    my %subresults = ();
    my %final = ();
    # do actual search
    for (my $i = 0; $i < $query->numberofconditions; $i++) {
	foreach my $lit ($query->literatures($i)) {
	    foreach my $trgt ($query->targets($i)) {
		$trgt = "body" if ($trgt eq "non-sectioned");
		retrievesubresult($i, $lit, $query->type($i), 
				  $trgt, $query->data($i),
				  $query->exactmatch($i),
				  $query->casesensitive($i),
				  \%subresults);
	    }
	}
	makefinalmodification($i, $query->occurrence($i),
			      $query->comparison($i), \%subresults);
    }

    %final = processindexhashes($query, \%subresults) if (keys %subresults);	
    return %final;
}

sub retrievesubresult {

    my $i = shift;
    my $literature = shift;
    my $type = shift;
    my $target = shift;
    my $data = shift;
    my $exactmatch = shift;
    my $casesensitive = shift;
    my $p_result = shift;
    my $name = DB_ROOT . '/' . (DB_LITERATURE)->{$literature} . '/' . 
	DB_INDEX . '/' . (DB_SEARCH_TARGETS)->{$target} . (DB_SEARCH_FLAVOR)->{$type} . '/';
    my @dataitems = split (/\,/, $data);
    foreach my $item (@dataitems) {
	if (($type eq 'category') || ($type eq 'attribute')) {
	    my $nm = $name . $item;
	    readindexfile($literature, $target, $nm, $p_result, $i);
	} elsif ($type eq 'keyword') {
	    my @variations = ();
	    if ($casesensitive) {
		@variations = ($item);
	    } else {
		my %kvars = ();
		my @voIlist = (lc($item), uc($item));
                my $faux = substr(lc($item), 0, 1);
                my $subaux = uc($faux);
                (my $aux = lc($item)) =~ s/^$faux/$subaux/;
                push @voIlist, $aux;
                my $oflag = 0;
                foreach (@voIlist) {
                    if ($item eq $_) {
                        $oflag = 1;
                        last;
                    }
                }
                push @voIlist, $item if (!$oflag);
                foreach my $variantOfItem (@voIlist) {
                    my $f = substr($variantOfItem, 0, 1);
		    my $dir;
		    if (length($variantOfItem) > 1) {
			my $s = substr($variantOfItem, 1, 1);
			$dir = $name . $f . "/" . $s . "/";
		    } else {
			$dir = $name . $f . "/";
		    }
                    my $fileStarts = $dir . '/' . $variantOfItem;
                    my $dirlist = join (" ", glob("$fileStarts*"));
                    $dirlist =~ s/$dir\///g;
                    while ($dirlist =~ /(\s|^)($item)/gi) {
                        $kvars{$2} = 1;
                    }
                }
		@variations = keys % kvars;
	    }
	    foreach my $var (@variations) {
		my $sd1 = substr($var, 0, 1);
		my $nm;
		if (length($item) > 1) {
		    my $sd2 = substr($var, 1, 1);
		    $nm = $name . $sd1 . '/' . $sd2 . '/' . $var;
		    if (!$exactmatch) {
			$nm .= '*';
		    }
		} else {
		    $nm = $name . $sd1 . '/' . 'LITERAL';
		}
		readindexfile($literature, $target, $nm,
			      $p_result, $i);
	    }
	}
    }
}

sub makefinalmodification {

    my $i = shift;
    my $occ = shift;
    my $comp = shift;
    my $p_result = shift;
    
    if (($comp ne '>') || ($occ != 0)) {
	foreach my $lit (keys % {$$p_result{$i}}) {
	    foreach my $key (keys % { $$p_result{$i}{$lit} }) {
		foreach my $tgt (keys % { $$p_result{$i}{$lit}{$key} }) {
		    my %aux = $$p_result{$i}{$lit}{$key}{$tgt} =~ /(\d+)-(\d+)/g;
		    while ((my $k, my $v) = each(%aux)) {
			my @sen = $$p_result{$i}{$lit}{$key}{$tgt} =~ /( $k-\d+)/g;
			$$p_result{$i}{$lit}{$key}{$tgt} =~ s/( $k-\d+)//g
			    if (!testnumericalcondition(scalar(@sen), $comp, $occ));
		    }
		    if (length($$p_result{$i}{$lit}{$key}{$tgt}) < 1) {
			delete $$p_result{$i}{$lit}{$key}{$tgt};
		    }
		}
	    }
	}
    }
}

sub readindexfile {
    
    my $literature = shift;
    my $target = shift;
    my $name = shift;
    my $p_result = shift;
    my $i = shift;

    my @files = glob($name);
    foreach my $file (@files) {
	my @lines = GetLines($file);
	foreach my $line (@lines) {
	    (my $key, my $stringindex) = split(/\#/, $line);
	    $$p_result{$i}{$literature}{$key}{$target} .= $stringindex;
	}
    }

}

sub processindexhashes { # process booleans, numerical cond. and range

    my $query = shift;
    my $subref = shift;

    my %final = ();
    my $i = 0;
    while ($i < $query->numberofconditions) {
	if ($query->boolean($i) eq '&&') {
	    my %aux = ();
	    if (defined(%{$$subref{$i}})) {
		%aux = %{$$subref{$i}};
	    }
	    my $j = $i+1;
	    my %HofH = ();
	    $HofH{0} = \%aux;
	    while ($query->boolean($j) eq '++') {
		if (defined(%{$$subref{$j}})) {
		    $HofH{$j-$i} = \%{$$subref{$j}};
		}
		$j++;
	    }
	    if (scalar(keys % HofH) > 1) {
		%aux = booleanandnextneighbors(\%HofH);
	    }
	    if ($i > 0) {
		%final = booleanand(\%final, \%aux, $query->range($i));
	    } else {
		%final = %aux;
	    }
	} elsif ($query->boolean($i) eq '||') {
	    my %aux = ();
	    if (defined(%{$$subref{$i}})) {
		%aux = %{$$subref{$i}};
	    }
	    my $j = $i+1;
	    my %HofH = ();
	    $HofH{0} = \%aux;
	    while ($query->boolean($j) eq '++') {
		if (defined(%{$$subref{$j}})) {
		    $HofH{$j-$i} = \%{$$subref{$j}};
		}
		$j++;
	    }
	    if (scalar(keys % HofH) > 1) {
		%aux = booleanandnextneighbors(\%HofH);
	    }
	    if ($i > 0) {
		%final = booleanor(\%final, \%aux, $query->range($i));
	    } else {
		%final = %aux;
	    }
	} elsif ($query->boolean($i) eq '!!') {
	    my %aux = ();
	    if (defined(%{$$subref{$i}})) {
		%aux = %{$$subref{$i}};
	    }
	    my $j = $i+1;
	    my %HofH = ();
	    $HofH{0} = \%aux;
	    while ($query->boolean($j) eq '--') {
		if (defined(%{$$subref{$j}})) {
		    $HofH{$j-$i} = \%{$$subref{$j}};
		}
		$j++;
	    }
	    if (scalar(keys % HofH) > 1) {
		%aux = booleanandnextneighbors(\%HofH);
	    }
	    if ($i > 0) {
		%final = booleannot(\%final, \%aux, $query->range($i));
	    } else {
		%final = %aux;
	    }
	}
	$i++;
    }
    return %final;
}

sub booleanandnextneighbors {

    my $p_HofH = shift;
    
    my %final = ();
    my %aux0 = %{$$p_HofH{0}};
    foreach my $lit (keys %aux0 ) {
	foreach my $key (keys % { $aux0{$lit} }) {
	    foreach my $tgt (keys % { $aux0{$lit}{$key} }) {
		my @strings = ($aux0{$lit}{$key}{$tgt});
		my $emptystring = 0;
		for (my $i = 1; $i < scalar(keys % $p_HofH); $i++) {
		    my $s = $$p_HofH{$i}{$lit}{$key}{$tgt};
		    if ($s ne "") {
			push @strings, $s;
		    } else {
			$emptystring = 1;
		    }
		}
		if (!$emptystring) {
		    my $aux = stringnextneighbor(@strings);
		    $final{$lit}{$key}{$tgt} = $aux if ($aux ne "");

		}
	    }
	}
    }
    return %final;
    
}

sub booleannot {

    my $pA = shift;
    my $pB = shift;
    my $range = shift;
    
    my %final = ();
    foreach my $lit (keys % $pA) {
	foreach my $key (keys % { $$pA{$lit} }) {
	    if ((DB_SEARCH_RANGES)->{$range} eq 'sentence') {
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    my $aux = stringnot($$pA{$lit}{$key}{$tgt}, $$pB{$lit}{$key}{$tgt});
		    $final{$lit}{$key}{$tgt} = $aux if ($aux ne "");
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'target') {
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    $final{$lit}{$key}{$tgt} = $$pA{$lit}{$key}{$tgt}
		    if ($$pB{$lit}{$key}{$tgt} !~ /\d+-\d+ /);
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'document') {
		my $b = 0;
		foreach my $tgt (keys % { $$pB{$lit}{$key} }) {
		    $b = length($$pB{$lit}{$key}{$tgt});
		    last if ($b);
		}
		if (!$b) {
		    foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
			$final{$lit}{$key}{$tgt} = $$pA{$lit}{$key}{$tgt};
		    }
		}
	    }
	}
    }
    return %final;

}

sub booleanor {

    my $pA = shift;
    my $pB = shift;

    my %final = %$pA;
    foreach my $lit (keys % $pB) {
	foreach my $key (keys % { $$pB{$lit} }) {
	    foreach my $tgt (keys % { $$pB{$lit}{$key} }) {
		my $aux = stringor($final{$lit}{$key}{$tgt}, $$pB{$lit}{$key}{$tgt});
		$final{$lit}{$key}{$tgt} = $aux if ($aux ne "");
	    }
	}
    }
    return %final;

}

sub booleanand {

    my $pA = shift;
    my $pB = shift;
    my $range = shift;

    my %final = ();
    foreach my $lit (keys % $pA) {
	foreach my $key (keys % { $$pA{$lit} }) {
	    if ((DB_SEARCH_RANGES)->{$range} eq 'sentence') {
	        foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    my $aux = stringand($$pA{$lit}{$key}{$tgt}, $$pB{$lit}{$key}{$tgt});
		    $final{$lit}{$key}{$tgt} = $aux if ($aux ne "");
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'target') {
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    my $aux = stringor($$pA{$lit}{$key}{$tgt}, $$pB{$lit}{$key}{$tgt});
		    if ($aux ne "") {
			$final{$lit}{$key}{$tgt} = $aux
			    if (($$pA{$lit}{$key}{$tgt} =~ /\d+-\d+ /) 
				&& ($$pB{$lit}{$key}{$tgt} =~ /\d+-\d+ /));
		    }
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'document') {
		my $a = 0;
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    $a = length($$pA{$lit}{$key}{$tgt});
		    last if ($a);
		}
		my $b = 0;
		foreach my $tgt (keys % { $$pB{$lit}{$key} }) {
		    $b = length($$pB{$lit}{$key}{$tgt});
		    last if ($b);
		}
		if ($a && $b) {
		    foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
			my $aux = stringor($final{$lit}{$key}{$tgt}, $$pA{$lit}{$key}{$tgt});
			$final{$lit}{$key}{$tgt} = $aux if ($aux ne "");
		    }
		    foreach my $tgt (keys % { $$pB{$lit}{$key} }) {
			my $aux = stringor($final{$lit}{$key}{$tgt}, $$pB{$lit}{$key}{$tgt});
			$final{$lit}{$key}{$tgt} = $aux if ($aux ne "");
		    }
		}
	    }
	}
    }
    return %final;

}

sub testnumericalcondition {

    my $total = shift;
    my $comp = shift;
    my $occ = shift;

    if (($comp eq '>') && ($total > $occ)) {
	return 1;
    } elsif (($comp eq '==') && ($total == $occ)) {
	return 1;
    } elsif (($comp eq '<') && ($total < $occ)) {
	return 1;
    } else {
	return 0;
    }

}

sub litkey {

    my $input = shift;
    my %output = ();
    foreach my $lit (keys % $input) {
	foreach my $key (keys % { $$input{$lit} }) {
	    foreach my $tgt (keys % { $$input{$lit}{$key} }) {
		my $string = $$input{$lit}{$key}{$tgt};
		push @{$output{"$lit - $key"}}, "$tgt\#$string"
		    if (length($string) > 0);
	    }
	}
    }
    return %output;

}

sub getstopwords {

    my $fn = shift;

    my $endstring = "";
    open (IN, "<$fn");
    while (my $line = <IN>) {
	chomp ($line);
	$line =~ s/\s//g;
	$endstring .= " $line ";
    }
    close (IN);
    return $endstring;

}

sub saveresults {
    
    my $pResults = shift;
    my $fn = shift;
    open (OUT, ">$fn");
    foreach my $lit (keys % $pResults) {
	foreach my $key (keys % { $$pResults{$lit} }) {
	    foreach my $tgt (keys % { $$pResults{$lit}{$key} }) {
		print OUT $lit, "\t", $key, "\t", $tgt, "\t", $$pResults{$lit}{$key}{$tgt}, "\n";
	    }
	}
    }
    close (OUT);
}

sub readresults {

    my $fn = shift;
    my %results = ();
    open (IN, "<$fn");
    while (my $line = <IN>) {
	chomp ($line);
	my @elements = split (/\t/, $line);
	$results{$elements[0]}{$elements[1]}{$elements[2]} = $elements[3];
    }
    close (IN);
    return %results;

}

1;
