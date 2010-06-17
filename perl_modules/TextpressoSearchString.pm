package TextpressoSearchString;

use TextpressoDatabaseGlobals;
use TextpressoStringBool;

use strict;
use Carp;

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{inputString} = undef;
    $self->{tempString} = undef;
    $self->{phrases} = [];
    $self->{brackets} = [];
    $self->{words} = [];
    bless($self, $class);

    return($self);
}

sub extractAndReplacePhrases { #tested

    my $self = shift;
    my $stopwordstring = shift;
    my $tempString = $self->getTempString();
    
    my $phraseOpen = "\"";
    my $phraseClose = "\"";
    
    # extract
    my @phrases = $tempString =~ /($phraseOpen.+?$phraseClose)/g;
    # replace
    my $phraseCount = 0;
    foreach (@phrases) {
	my $temp = $self->getTempString;
	$temp =~ s/$_/#phrase$phraseCount#/;
	$self->setTempString($temp);
	$phraseCount++;
    }
    
    # stopwords
    my $foundstopwords = "";
    for my $phrase (@phrases) {
	$phrase =~ s/^\"//;
	$phrase =~ s/\"$//;
	my @words = split (/\s/, $phrase);
	my $clean_phrase = "";
	for my $word (@words) {
	    if ($stopwordstring =~ /\s$word\s/) {
		$foundstopwords .= $word . " ";
	    } else {
		$clean_phrase .= $word . " ";
	    }
	}
	$clean_phrase =~ s/\s$//;
	my $temp = "\"$clean_phrase\"";
	push @{$self->{phrases}}, $temp;
    }
    
    return $foundstopwords;
}

sub extractAndReplaceBrackets { #tested

    my $self = shift;
    my $tempString = $self->getTempString();
    
    my $bracketOpen = '\(';
    my $bracketClose = '\)';
    
    # extract
    @{$self->{brackets}} = $tempString =~ /$bracketOpen(.+?)$bracketClose/g;
    
    # replace
    my $bracketCount = 0;
    foreach (@{$self->{brackets}}) {
	my $temp = $self->getTempString;
	$temp =~ s/$bracketOpen$_$bracketClose/#bracket$bracketCount#/;
	$self->setTempString($temp);
	$bracketCount++;
    }
}

sub extractAndReplaceWords { #tested

    my $self = shift;
    my $stopwordstring = shift;
    my $debug = 0;
    
    print "\n---\nIn extractAndReplaceWords\n\n" if ($debug);
    my $tempString = $self->getTempString();
    print "Incoming tempString = $tempString\n" if ($debug);
    
    my $booleanOperators = '(^| -| |,)';
    $tempString =~ s/$booleanOperators#phrase\d+#//g;
    $tempString =~ s/$booleanOperators\(#phrase\d+#//g;
    $tempString =~ s/\(//g;
    $tempString =~ s/\)//g;
    print "Phrase-eliminated tempString = \'$tempString\'\n" if ($debug);
    
    # remove any Boolean operator from the beginning, so split below does not produce empty word
    $tempString =~ s/^( -|,| )//;
    # extract
    my @words = split(/ -|,| /, $tempString);
    
    # replace
    my $wordCount = 0;
    my $foundstopwords = "";
    for my $word (@words) {
	# handle stopwords
	if ($stopwordstring =~ /\s$word\s/) {
	    $foundstopwords .= $word . " ";
	    my $temp = $self->getTempString;
	    # if stopword occurs in the beginning
	    $temp =~ s/^$word(\s-|\s|,)//;
	    # stopword first term in bracket
	    $temp =~ s/(\()$word(\s-|\s|,)/$1/;
	    # stopword in the middle in bracket
	    $temp =~ s/(\s-|\s|,)$word(\s-|\s|,)/$2/;
	    # stopword in the end in bracket
	    $temp =~ s/(\s-|\s|,)$word(\))/$2/;
	    # stopword in the end
	    $temp =~ s/(\s-|\s|,)$word//;
	    
	    $self->setTempString($temp);
	    next;
	}
	push @{$self->{words}}, $word;
	my $temp = $self->getTempString;
	$temp =~ s/$word/#word$wordCount#/;
	$self->setTempString($temp);
	$wordCount++;
    }
    
    print "\n---\n\n" if ($debug);
    return $foundstopwords;
}

sub setInputString {

    my $self = shift;
    if (@_) {
	$self->{inputString} = shift;
    } else {
	confess ("Input string is empty.\n");
    }
    $self->setTempString($self->{inputString});
}

sub setTempString {

    my $self = shift;
    if (@_) {
	$self->{tempString} = shift;
    } else {
	confess ("Temp string is empty.\n");
    }
}

sub getInputString {

    my $self = shift;
    return $self->{inputString};
}

sub getTempString {

    my $self = shift;
    return $self->{tempString};
}

sub getPhrases {

    my $self = shift;
    return @{$self->{phrases}};
}

sub getWords {

    my $self = shift;
    return @{$self->{words}};
}

sub getBrackets {

    my $self = shift;
    return @{$self->{brackets}};
}

sub getElementsOfBracket {

    my $self = shift;
    my $bracket = shift;
    
    my $booleanOperator = '( -| |,)';
    my @elements = split(/$booleanOperator/, $bracket);
    
    return @elements;
}

sub getFinalElements { # these are #bracket\d+#, #phrase\d+#, #word\d+#

    my $self = shift;
    my $tempString = $self->getTempString();
    my $booleanOperator = '( -| |,)';
    my @elements = split(/$booleanOperator/, $tempString);
    
    return @elements;
}


sub doBooleanOperation {

    my $self = shift;
    my $query = shift;
    my $element1 = shift;
    my $operator = shift;
    my $element2 = shift;
    my $presults = shift;
    
    if ($operator eq ' ') {
	$self->doBooleanAnd($query, $element1, $element2, $presults);
    } elsif ($operator eq ',') {
	$self->doBooleanOr($query, $element1, $element2, $presults);
    } elsif ($operator eq ' -') {
	$self->doBooleanAndNot($query, $element1, $element2, $presults);
    } 
}

sub doBooleanAnd {

    my $self = shift;
    my $query = shift;
    my $element1 = shift;
    my $element2 = shift;
    my $presults = shift;
    my $range = $query->param('sentencerange');

    for my $lit (keys %{$$presults{$element1}}) {
	for my $id (keys %{$$presults{$element1}{$lit}}) {
	    if ((DB_SEARCH_RANGES)->{$range} eq 'sentence') {
		for my $field (keys %{$$presults{$element1}{$lit}{$id}}) {
		    my $aux = stringand($$presults{$element1}{$lit}{$id}{$field},
					$$presults{$element2}{$lit}{$id}{$field});
		    if ($aux ne "") {
			$$presults{$element1}{$lit}{$id}{$field} = $aux;
		    } else {
			delete $$presults{$element1}{$lit}{$id}{$field};
		    }
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'target') {
		for my $field (keys %{$$presults{$element1}{$lit}{$id}}) {
		    my $aux = stringor($$presults{$element1}{$lit}{$id}{$field}, 
				       $$presults{$element2}{$lit}{$id}{$field});
		    if (($aux ne "") && 
			($$presults{$element1}{$lit}{$id}{$field} =~ /\d+-\d+ /) && 
			($$presults{$element2}{$lit}{$id}{$field} =~ /\d+-\d+ /)) {
			$$presults{$element1}{$lit}{$id}{$field} = $aux;
		    } else {
			delete $$presults{$element1}{$lit}{$id}{$field};
		    }
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'document') {
		my $a = 0;
		foreach my $field (keys % {$$presults{$element1}{$lit}{$id}}) {
		    $a = length($$presults{$element1}{$lit}{$id}{$field});
		    last if ($a);
		}
		my $b = 0;
		foreach my $field (keys % {$$presults{$element2}{$lit}{$id}}) {
		    $b = length($$presults{$element2}{$lit}{$id}{$field});
		    last if ($b);
		}
		if ($a && $b) {
		    foreach my $field (keys % {$$presults{$element2}{$lit}{$id}}) {
			my $aux = stringor($$presults{$element1}{$lit}{$id}{$field},
					   $$presults{$element2}{$lit}{$id}{$field});
			if ($aux ne "") {
			    $$presults{$element1}{$lit}{$id}{$field} = $aux;
			} else {
			    delete $$presults{$element1}{$lit}{$id}{$field};
			}
		    }
		} else {
		    delete $$presults{$element1}{$lit}{$id};
		}		    
	    }
	}
    }

    return;
}

sub doBooleanOr {

    my $self = shift;
    my $query = shift;
    my $element1 = shift;
    my $element2 = shift;
    my $presults = shift;
    
    for my $lit (keys %{$$presults{$element2}}) {
	for my $id (keys %{$$presults{$element2}{$lit}}) {
	    for my $field (keys %{$$presults{$element2}{$lit}{$id}}) {
		my $aux = stringor($$presults{$element1}{$lit}{$id}{$field},
				   $$presults{$element2}{$lit}{$id}{$field});
		if ($aux ne "") {
		    $$presults{$element1}{$lit}{$id}{$field} = $aux;
		} else {
		    delete $$presults{$element1}{$lit}{$id}{$field};
		}
	    }
	}
    }

    return;
}

sub doBooleanAndNot {

    my $self = shift;
    my $query = shift;
    my $element1 = shift;
    my $element2 = shift;
    my $presults = shift;
    my $range = $query->param('sentencerange');
    
    for my $lit (keys %{$$presults{$element1}}) {
	for my $id (keys %{$$presults{$element1}{$lit}}) {
	    if ((DB_SEARCH_RANGES)->{$range} eq 'sentence') {
		for my $field (keys %{$$presults{$element1}{$lit}{$id}}) {
		    my $aux = stringnot($$presults{$element1}{$lit}{$id}{$field},
					$$presults{$element2}{$lit}{$id}{$field});
		    if ($aux ne "") {
			$$presults{$element1}{$lit}{$id}{$field} = $aux;
		    } else {
			delete $$presults{$element1}{$lit}{$id}{$field};
		    }
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'target') {
		for my $field (keys %{$$presults{$element1}{$lit}{$id}}) {
		    delete $$presults{$element1}{$lit}{$id}{$field}
		    if ($$presults{$element2}{$lit}{$id}{$field} =~ /\d+-\d+ /);
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'document') {
		my $b = 0;
		foreach my $field (keys %{$$presults{$element2}{$lit}{$id}}) {
		    $b = length($$presults{$element2}{$lit}{$id}{$field});
		    last if ($b);
		}
		if ($b) {
		    foreach my $field (keys %{$$presults{$element1}{$lit}{$id}}) {
			delete $$presults{$element1}{$lit}{$id}{$field};
		    }
		}
	    }
	}
    }

    return;
}

1;
