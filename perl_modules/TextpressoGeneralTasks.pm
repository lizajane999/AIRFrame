package TextpressoGeneralTasks;

# Package provide class and methods for
# tasks related to processing and maintaining
# the Textpresso system.
#
# (c) 2005-8 Hans-Michael Muller, Caltech, Pasadena.

use strict;
use TextpressoGeneralGlobals;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(PrepareSearchString ReplaceSpecChar InverseReplaceSpecChar ReplaceDashAndWhitespace InverseReplaceDashAndWhitespace ReadLexica WriteLexica FindRelevantEntries GetLines GetStopWords ascending descending);

sub PrepareSearchString {

    my $line = shift;

    # keep order of following lines; it's important.
    # special treatment for double quote
    $line =~ s/([^\\]|^)\"/$1\_SSDQ\_/g;
    $line =~ s/\\\"/\"/g;

    # special treatment for all characters relevant to boolean algebra
    $line =~ s/\\\(/\_SSRBO\_/g;
    $line =~ s/\\\)/\_SSRBC\_/g;
    $line =~ s/\\\,/\_SSCMM\_/g;
    $line =~ s/\\\-/\_SSDSH\_/g;

    # put quotes around words with special characters {
    my %lclrepl = ();
    while ($line =~ /([^\ \_]+)/g) {
	my $aux = $1;
	my $replaux = ReplaceSpecChar($aux);
	$lclrepl{$aux} = $replaux if ($aux ne $replaux);
    }

    foreach my $k (keys % lclrepl) {
	(my $l = $k) =~ s/([\\\|\(\)\{\}\[\]\^\$\*\+\?\.])/\\$1/g;
	$line =~ s/$l/\_SSDQ\_$lclrepl{$k}\_SSDQ\_/g;
    }
    # unescape double quote
    $line =~ s/(_SSDQ_)+/\"/g;
    # undo all characters relevant to boolean algebra
    $line =~ s/_SSRBO_/\(/g;
    $line =~ s/_SSRBC_/\)/g;
    $line =~ s/_SSCMM_/\,/g;
    $line =~ s/_SSDSH_/\-/g;

    return $line;
}

sub ReplaceSpecChar {

    my $line = shift;
    foreach (keys %{(GE_SPECIALCHARS)}) {
	my $r = (GE_SPECIALCHARS)->{$_};
	# special characters are also tokenized here...
	$line =~ s/\ *$_\ */ $r /g;
    }
    $line =~ s/ +/ /g;
    return $line;
}

sub InverseReplaceSpecChar {

    my $line = shift;
    foreach (keys %{(GE_SPECIALCHARS)}) {
	my $r = (GE_SPECIALCHARS)->{$_};
	$line =~ s/$r/$_/g;
    }
    return $line;
}

sub ReplaceDashAndWhitespace {

    my $line = shift;
    $line =~ s/\-/\_DSH\_/g;
    $line =~ s/ /\_SPC\_/g;
    return $line;
}

sub InverseReplaceDashAndWhitespace {

    my $line = shift;
    $line =~ s/\_DSH\_/\-/g;
    $line =~ s/\_SPC\_/ /g;
    return $line;
}

sub GetLines {
    
    my $plainfile = shift;
    my @lines = ();
    
    undef $/;
    open (PLAIN, "$plainfile") || return @lines;
    my $file = <PLAIN>;
    close (PLAIN);
    $/ = "\n";
    @lines = split /\n/, $file;
    return @lines;
}

sub GetStopWords {
    
    my $stopwordfile = shift;
    my %stopwords = ();
    open (IN, "<$stopwordfile") || return %stopwords;
    while (my $line = <IN>) {
	chomp ($line);
	$line =~ s/\s+//g;
	$stopwords{$line} = 1;
    }
    close (IN);
    return %stopwords;
    
}

sub ReadLexica {
    
    use File::Basename;
    
    my $dirin = shift;
    my $del = shift;
    my %lexicon = ();
    
    my @lexfiles = <$dirin/*>;
    
    foreach my $file (@lexfiles) {
	(my $fname, my $fdir, my $fsuf) = fileparse($file, qr{\.\d+-gram});
	$fsuf =~ s/^\.(\d+)-gram/$1/;
	open (IN, "<$file");
	my $inline = '';
	while (my $line = <IN>) {
	    $inline .= $line;
	}
	my @entries = split (/$del\n/, $inline);
	foreach my $entry (@entries) {
	    my @items = split (/\n/, $entry);
	    my $ukey = shift(@items);
	    @{$lexicon{$ukey}{$fname}} = @items;
	}
	close (IN);
    }
    return %lexicon;
}

sub WriteLexica {

    my $dirout = shift;
    my $del = shift;
    my $p_lex = shift;

    foreach my $key (sort keys % $p_lex) {
	foreach my $cat (keys % { $$p_lex{$key} }) {
	    open (OUT, ">>$dirout/$cat.0-gram"); # can consolidate everything
	                                 # into 0-gram, as this is an
	                                 # legacy extension.
	    print OUT $key, "\n";
	    print OUT join ("\n", @{$$p_lex{$key}{$cat}}), "\n" if (@{$$p_lex{$key}{$cat}});
	    print OUT $del, "\n";
	    close (OUT);
	}
    }
}

sub FindRelevantEntries {
    
    my $line = shift;
    my $pLexicon = shift;
    my %list = ();
    
    foreach my $phrase (keys % { $pLexicon }) {
	foreach my $category (keys % { $$pLexicon{$phrase} }) {
	    if ($line =~ m/$phrase/) {
		$list{$phrase}{$category} = 1;
	    }
	}
    }
    
    return %list;
}

sub ascending {  $a <=> $b }
sub descending {  $b <=> $a }

1;
