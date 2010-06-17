package TextpressoWebserviceTasks;

# Package provide classes and methods for
# tasks related to Textpresso web service
#
# (c) 2007 Arun Rangarajan & Hans-Michael Muller, Caltech, Pasadena.

use strict;
use TextpressoGeneralGlobals;
use TextpressoDisplayGlobals;
use TextpressoDatabaseGlobals;
use TextpressoDatabaseCategories;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ParseInputFields ProduceXmlOutput);

sub ParseInputFields { # adapted from ParseInputFields from 
                       # TextpressoDisplayTasks.pm
    my $p_literatures = shift;
    my $p_fields = shift;
    my $p_categories = shift;
    my $exact_match = shift;
    my $case_sensitive = shift;
    my $keywords = shift;
    my $stopwordstring = shift;

    my $tpquery = new TextpressoDatabaseQuery;
    $tpquery->init;
    
    my %literatures = ();
    foreach (@$p_literatures) {
		$literatures{$_} = 1;
    }

    my %targets = ();
    foreach (@$p_fields) {
		$targets{$_} = 1;
    }

    my @categories = ();
    foreach (@$p_categories) {
	push @categories, $_;
    }
    my $size_of_categories = @categories;
    
    for (my $i = 0; $i < 4; $i++) {
	if (defined($categories[$i])) {
	    my $aux = (DB_CATEGORIES)->{$categories[$i]};
	    if (defined(@{(DB_CATEGORYCHILDREN)->{$categories[$i]}})) {
		foreach my $child (@{(DB_CATEGORYCHILDREN)->{$categories[$i]}}) {
		    $aux .= "," . (DB_CATEGORIES)->{$child};
		}
	    }
	    
#
# TODO: check what $query->param('sentencerange') does
#
#	    	$tpquery->addsimple('category', $aux,
#				$query->param('sentencerange'), $exact_match || 0,
#				$case_sensitive || 0, \%literatures, \%targets);
	    $tpquery->addsimple('category', $aux,
				10, $exact_match || 0,
				$case_sensitive || 0, \%literatures, \%targets);
	}
    }
    
#
# TODO: check what $query->param('sentencerange') does
#
#    my $foundstopwords = ParseSearchString($keywords, $tpquery, $stopwordstring, 0, '>',
#					   $query->param('sentencerange'), $exact_match || 0,
#					   $case_sensitive || 0, \%literatures, \%targets);
    my $foundstopwords = ParseSearchString($keywords, $tpquery, $stopwordstring, 0, '>',
					   10, $exact_match || 0,
					   $case_sensitive || 0, \%literatures, \%targets);
    
    return ($tpquery, $foundstopwords);
}


sub ProduceXmlOutput
{
    # globals
    my $search_mode = shift;
    my $tmpfile = $query->param('tmpfile');
    my $keywordfilename = DB_TMP . "/tmp/" . $query->param('tmpfilename1');
    my $categoryfilename = DB_TMP . "/tmp/" . $query->param('tmpfilename2');
    
    
    # read in the results from tmpfile
    my $filename = DB_TMP . "/tmp/" . $tmpfile;
    my %results = readresults($filename);
    
    my $xml_output = "";
    $xml_output .= "<\?xml version\=\"1.0\" standalone\=\"no\"\?>\n";
    my $dtdaddress = HTML_ROOT . "neuroscience/xml_dtd/export_xml.dtd";
    $xml_output .= "<!DOCTYPE textpresso_output SYSTEM \"$dtdaddress\">\n";
    
    if ($mode eq 'singleentry') 
    {
	my $wbid = $query->param('wbid');
	my $field = $query->param('tgt');
	foreach my $lit (keys %results)
	{
	    $xml_output .= "<textpresso_output>\n";
	    $xml_output .= " <singleresult>\n";
	    $xml_output .= annotations_in_xml();
	    $xml_output .= "\n";
	    $xml_output .= "  <textpresso_article>\n";
	    $xml_output .= single_biblio_entry_in_xml($lit, $wbid);
	    $xml_output .= "\n";
	    $xml_output .= matching_sentences_in_xml(\%results, $lit, $field, $wbid, $keywordfilename, $categoryfilename);
	    $xml_output .= "\n";
	    $xml_output .= "  <\/textpresso_article>\n";
	    $xml_output .= " <\/singleresult>\n";
	    $xml_output .= "<\/textpresso_output>\n";
	}
    }
    elsif ($mode eq 'allentries') 
    {
	$xml_output .= "<textpresso_output>\n";
	$xml_output .= " <allresults>\n";
	$xml_output .= annotations_in_xml();
	$xml_output .= "\n";
	foreach my $lit (keys %results)
	{
	    foreach my $wbid (keys % {$results{$lit}})
	    {
		foreach my $field (keys % {$results{$lit}{$wbid}})
		{
		    $xml_output .= "  <textpresso_article>\n";
		    $xml_output .= single_biblio_entry_in_xml($lit, $wbid);
		    $xml_output .= "\n";
		    $xml_output .= matching_sentences_in_xml(\%results, $lit, $field, $wbid, $keywordfilename, $categoryfilename);
		    $xml_output .= "\n";
		    $xml_output .= "  <\/textpresso_article>\n\n";
		}
	    }
	}
	$xml_output .= " <\/allresults>\n";
	$xml_output .= "<\/textpresso_output>\n";
    }
    
    # validate the XML file with Richard Tobin's XML well-formedness checker and validator
    my $xml_file = DB_TMP . "/tmp/" . "\/xmlfile";
    open (OUT, ">$xml_file");
    print OUT $xml_output;
    
    my @args = ("./rxp", "-Vs", "$xml_file");
    my $x = system (@args);
    if ($x != 0)
    {
	$xml_output .= "<!-- This XML file failed validation test. exit status of RXP XML parser = $x. If you are concerned, please contact the Textpresso group. -->\n";
    }
    else
    {
	$xml_output .= "<!-- This XML file passed the validation test. -->\n";
    }
    
    return $xml_output;
}
