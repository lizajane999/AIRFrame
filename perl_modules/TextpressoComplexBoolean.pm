package TextpressoComplexBoolean;

# Package for parsing complex Boolean search strings 
# with one-level brackets
#
# (c) 2008 Arun Rangarajan, Caltech, Pasadena.
# Started July 22, 2008
# Ended 

use strict;
use POSIX;
use TextpressoSearchString;
use TextpressoDisplayTasks;
use TextpressoDatabaseSearch;
use TextpressoDatabaseQuery;
use TextpressoDatabaseCategories;
use TextpressoDatabaseGlobals;
use TextpressoSynonymTasks;
use TextpressoGeneralTasks;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ParseAndSearch);

sub ParseAndSearch {
    my $query = shift;
    my $stopwordstring = shift;
    my $newsearch = shift;
    my $searchfilename = shift;
    my $tqueryfilename = shift;
    my $pfoundstopwords = shift;
    ####added by RF, 1008 for synonyms search
    my $lastSynonymsSearch = shift;
    my $pSearchKeywordsSyn = shift;
    my $pSynDisplay = shift;
    my $synSearchStringInput;
    my $synonymsListFinal;
    my $searchsynonyms = $query->param('searchsynonyms');
    my $exactmatch = $query->param('exactmatch');
    ####end added by RF
    if (!$newsearch) {
	return(readresults($searchfilename));
    }
    
    my %literatures = ();
    foreach ($query->param('literature')) {
        $literatures{$_} = 1;
    }
    my %targets = ();
    foreach ($query->param('target')) {
	$targets{$_} = 1;
    }

    my %subresults = ();    
    my $foundstopwords = "";
    my $searchString = TextpressoSearchString->new();
    my $originalsearchstring = $query->param('searchstring');
    my $searchStringInput = PrepareSearchString($originalsearchstring);
    $searchString->setInputString($searchStringInput);
    
    ${$pfoundstopwords} = $searchString->extractAndReplacePhrases($stopwordstring);
    ${$pfoundstopwords} .= $searchString->extractAndReplaceWords($stopwordstring);
    $searchString->extractAndReplaceBrackets();
    
    ###########################################################################
    # words
    ###########################################################################
    my @words = $searchString->getWords();
    
    ####added by RF, 1008 for synonyms search##################################
    my $searchString_syn = TextpressoSearchString->new();
    if($lastSynonymsSearch eq 'on'){
	($synSearchStringInput, $synonymsListFinal) = getSearchStringInputSyn ($searchStringInput,\@words, $exactmatch);
	if ($synSearchStringInput ne $searchStringInput) {
	    $$pSearchKeywordsSyn = $synSearchStringInput;
	    $$pSearchKeywordsSyn =~ s/\(/\\\(/g;
	    $$pSearchKeywordsSyn =~ s/\)/\\\)/g;
	    $$pSearchKeywordsSyn =~ s/\,/\\\,/g;
	    $$pSearchKeywordsSyn =~ s/ \-/ \\\-/g;
	} else {
	    $$pSearchKeywordsSyn = $originalsearchstring;
	}
	$$pSynDisplay = $synonymsListFinal;
	$searchString_syn->setInputString($synSearchStringInput);	
	${$pfoundstopwords} = $searchString_syn->extractAndReplacePhrases($stopwordstring);
        ${$pfoundstopwords} .= $searchString_syn->extractAndReplaceWords($stopwordstring);
	$searchString_syn->extractAndReplaceBrackets($stopwordstring);
	@words = $searchString_syn->getWords(); 
	$searchString = $searchString_syn;
    }

    ####end added by RF########################################################
    for (my $i = 0; $i < @words; $i++) {
	my $tpquery = new TextpressoDatabaseQuery;
	$tpquery->init;
	
	# form tpquery
	####modified by RF, 1008
	my $foundstopwords = TextpressoDisplayTasks::ParseSearchString($words[$i], $tpquery, $stopwordstring, 
								       0, '>', $query->param('sentencerange'), 
								       $query->param('exactmatch') || 0, 
								       $query->param('casesensitive') || 0, \%literatures, \%targets);
	my %temp_results = ();
	# do the search
	%temp_results = TextpressoDatabaseSearch::textpressosearch($tpquery);
	$subresults{"#word".$i."#"} = \%temp_results;
    }
    
    ###########################################################################
    # phrases
    ###########################################################################
    my @phrases = $searchString->getPhrases();
    
    for (my $i = 0; $i < @phrases; $i++) {
	my $tpquery = new TextpressoDatabaseQuery;
	$tpquery->init;
	
	# form tpquery
	my $foundstopwords = TextpressoDisplayTasks::ParseSearchString($phrases[$i], $tpquery, $stopwordstring, 0, '>',
								       $query->param('sentencerange'), $query->param('exactmatch') || 0,
								       $query->param('casesensitive') || 0, \%literatures, \%targets);
	my %temp_results = ();
	# do the search
	%temp_results = TextpressoDatabaseSearch::textpressosearch($tpquery);
	$subresults{"#phrase".$i."#"} = \%temp_results;
    }
    
    ###########################################################################
    # brackets (which contain words and phrases)
    ###########################################################################
    my @brackets = $searchString->getBrackets();
    for (my $i = 0; $i < @brackets; $i++) {
	my @elements = $searchString->getElementsOfBracket($brackets[$i]);
	
	# copy the first phrase/word result into bracket result
	for my $lit (keys %{$subresults{$elements[0]}}) {
	    for my $id (keys %{$subresults{$elements[0]}{$lit}}) {
		for my $field (keys %{$subresults{$elements[0]}{$lit}{$id}}) {
		    $subresults{"#bracket".$i."#"}{$lit}{$id}{$field} = $subresults{$elements[0]}{$lit}{$id}{$field};
		}
	    }
	}
	for (my $j=1; $j<@elements; $j+=2) {
	    $searchString->doBooleanOperation($query, "#bracket$i#", $elements[$j], $elements[$j+1], \%subresults);
	}
    }
    
    ###########################################################################
    # final (which contains brackets, words and phrases)
    ###########################################################################
    my @final_elements = $searchString->getFinalElements();
    
    # copy the first bracket/phrase/word result into final result
    for my $lit (keys %{$subresults{$final_elements[0]}}) {
	for my $id (keys %{$subresults{$final_elements[0]}{$lit}}) {
	    for my $field (keys %{$subresults{$final_elements[0]}{$lit}{$id}}) {
		$subresults{"#final#"}{$lit}{$id}{$field} = $subresults{$final_elements[0]}{$lit}{$id}{$field};
	    }
	}
    }
    for (my $j=1; $j<@final_elements; $j+=2) {
	$searchString->doBooleanOperation($query, "#final#", $final_elements[$j], $final_elements[$j+1], \%subresults);
    }
    
    ###########################################################################
    # final (which combines the results above with categories)
    ###########################################################################
    my $startercat = 1;
    for (my $i = 1; $i < 6; $i++) {
	if ($query->param("cat$i") !~ /^Select/) {
	    my $tpquery = new TextpressoDatabaseQuery;
	    $tpquery->init;
	    my $aux = (DB_CATEGORIES)->{$query->param("cat$i")};
	    if (defined(@{(DB_CATEGORYCHILDREN)->{$query->param("cat$i")}})) {
		foreach my $child (@{(DB_CATEGORYCHILDREN)->{$query->param("cat$i")}}) {
		    $aux .= "," . (DB_CATEGORIES)->{$child};
		}
	    }
	    $tpquery->addsimple('category', $aux,
				$query->param('sentencerange'), $query->param('exactmatch') || 0,
				$query->param('casesensitive') || 0, \%literatures, \%targets);
	    
	    # do the search
	    my %temp_results = TextpressoDatabaseSearch::textpressosearch($tpquery);
	    my $element1 = "#final#";
	    if ($searchStringInput ne "") { # then AND the results with final
		%{$subresults{$element1}} = booleanand(\%{$subresults{$element1}},
						       \%temp_results,
						       $query->param('sentencerange'));
	    } elsif ($startercat) { # copy the results with final, because no keywords specified
                $startercat = 0;
		for my $lit (keys %temp_results) {
		    for my $id (keys %{$temp_results{$lit}}) {
			for my $field (keys %{$temp_results{$lit}{$id}}) {
			    $subresults{$element1}{$lit}{$id}{$field} = $temp_results{$lit}{$id}{$field};
			}
		    }
		}
            } else { # AND the results with final
                %{$subresults{$element1}} = booleanand(\%{$subresults{$element1}},
						       \%temp_results,
						       $query->param('sentencerange'));
	    }
	}
    }
    
    my %results;
    for my $word (keys %subresults) {
	    if ($word =~ /^#final/) {
		for my $lit (keys %{$subresults{$word}}) {
		    for my $id (keys %{$subresults{$word}{$lit}}) {
			for my $field (keys %{$subresults{$word}{$lit}{$id}}) {
			    $results{$lit}{$id}{$field} = $subresults{$word}{$lit}{$id}{$field};
			}
		    }
		}
	    }
	}
    
    # search uses tpquery to do highlighting, so just populate tpquery
    my $tpquery_highlight = new TextpressoDatabaseQuery;
    $tpquery_highlight->init;
    &populate_tpqueryForHighlighting($query, $tpquery_highlight, $searchString);
#     print "tpquery_highlight->{type}: ";
#     print @{$tpquery_highlight->{type}};
#     print "<br />";
#     print "saving highlighting to: ".$tqueryfilename."<br />";
    $tpquery_highlight->savetofile($tqueryfilename);
    saveresults(\%results, $searchfilename);
    return %results;
}

sub populate_tpqueryForHighlighting {
    # the following done just to populate tpquery with the keywords, 
    # so that keyword highlighting can be done in search CGI script
    my $query = shift;
    my $tpquery = shift;
    my $searchString = shift;
    
    my @words = $searchString->getWords();
    
#     print "Inside populate for highlighting <br />";
    
    foreach (@words) {
	$tpquery->addsimple('keyword', InverseReplaceSpecChar($_),
			    $query->param('sentencerange'), $query->param('exactmatch') || 0,
			    $query->param('casesensitive') || 0);
	
    }
    my @phrases = $searchString->getPhrases();
    foreach (@phrases) {
	s/^\"//;
	s/\"$//;
	$tpquery->addsimple('keyword', InverseReplaceSpecChar($_),
			    $query->param('sentencerange'), $query->param('exactmatch') || 0,
                            $query->param('casesensitive') || 0);
    }
    
    # add categories as well
    for (my $i = 1; $i < 6; $i++) {
	if ($query->param("cat$i") !~ /^Select/) {
	    my $aux = (DB_CATEGORIES)->{$query->param("cat$i")};
	    if (defined(@{(DB_CATEGORYCHILDREN)->{$query->param("cat$i")}})) {
		foreach my $child (@{(DB_CATEGORYCHILDREN)->{$query->param("cat$i")}}) {
		    $aux .= "," . (DB_CATEGORIES)->{$child};
		}
	    }
	    $tpquery->addsimple('category', $aux,
				$query->param('sentencerange'), $query->param('exactmatch') || 0,
				$query->param('casesensitive') || 0);
	}
    }

#     print "tpquery->{type}: ";
#     print @{$tpquery->{type}};
#     print "<br />";
    
    return;
}

1;
