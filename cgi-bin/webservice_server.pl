#!/usr/bin/perl -w

# RPC XML webservice for Textpresso
#
# Copyright (c) by Arun Rangarajan & Hans-Michael Muller, Caltech, 2007.
#
# Arun started writing script on July 4, 2007 (Independence day!)
#
# Adapted from script "search" in same directory


#
# NEEDS TO BE UPDATED BY ARUN!!!
#

use strict;

# Import the library path TEXTPRESSO_LIB from TextpressoLibrary.pm
use TextpressoLibrary;

use lib TEXTPRESSO_LIB;

use RPC::XML;
use RPC::XML::Server;
use TextpressoWebserviceTasks;
use TextpressoDisplayGlobals;
use TextpressoDatabaseGlobals;
use TextpressoDatabaseQuery;
use TextpressoDatabaseCategories;
use TextpressoDisplayTasks;
use TextpressoDatabaseSearch;
use Time::HiRes qw(gettimeofday);

my $host = "dev\.textpresso\.org"; # do not run this script on main
my $port = "8003";
my $daemon = RPC::XML::Server->new(port => $port);

print "Adding textpresso_webservice\n";
my @sig = ('string string');
$daemon->add_method({ name => 'textpresso.com.textpresso_webservice',
		      signature => \@sig,
		      code => \&textpresso_webservice });

sub textpresso_webservice {
    
    my $input_string = shift;	# this is the XML input payload string sent by the client. see below.
    
    # Please use http://www.textpresso.org/neuroscience to understand how Textpresso's interactive web site
    # takes keywords and category inputs and returns its output.
    #
    # Arun has initially coded the input from client as follows. This could be changed if needed.
    #
    # Let us say the client wants to search the textpresso server for the keyword
    # "purkinje cell" with categories "Brain Area" and "Receptors".
    # The XML data payload from the client should be encoded as:
    #
    # <textpresso_webservice_input>
    #  <keywords>"purkinje cell"</keywords>
    #  <category>"Brain Area"</category>
    #  <category>Receptors</category>
    # </textpresso_webservice_input>
    #
    # The XML file above does not have all the input parameters for Textpresso and the following
    # XML file is more complete. (Look at the search results page of Textpresso interactive web
    # site to understand these other search options.)
    #
    # <textpresso_webservice_input>
    #  <keywords>"purkinje cell"</keywords>
    #
    #  <category>\"Brain Area\"</category>
    #  <category>Receptors</category>
    #
    #  <field>abstract</field>
    #  <field>body</field>
    #  <field>title</field>
    #
    #  <search_scope>sentence</search_scope>
    #  <search_mode>boolean</search_mode>
    #
    #  <exact_match>0</exact_match>
    #  <case_sensitive>1</case_sensitive>
    #
    #  <filter_string>\+antibodies\[sentence\]</filter_string>
    # </textpresso_webservice_input>
    
    # get the keywords
    $input_string =~ /<keywords>(.*)<\/keywords>/;
    my $keywords = $1;
    
    # get the categories
    my @categories = ();
    while ($input_string =~ /<category>(.*)<\/category>/g) {
	push @categories, $1;
    }
    
    # get the fields
    my @fields = ();
    while ($input_string =~ /<field>(.*)<\/field>/g) {
	push @fields, $1;
    }
    
    # get other input variables
    $input_string =~ /<search_scope>(.*)<\/search_scope>/;
    my $search_scope = $1;
    $input_string =~ /<search_mode>(.*)<\/search_mode>/;
    my $search_mode = $1;
    $input_string =~ /<filter_string>(.*)<\/filter_string>/;
    my $filter_string = $1;
    $input_string =~ /<exact_match>(\d*)<\/exact_match>/;
    my $exact_match = $1;
    $input_string =~ /<case_sensitive>(\d*)<\/case_sensitive>/;
    my $case_sensitive = $1;
    
    # set literature. could be changed to more literatures if needed.
    my @literatures = @{(DB_LITERATURE_DEFAULTS)};  
    
    # initializations and declarations
    ########################################################################
    my $starttime = gettimeofday();
    my $tpquery;
    my %results;
    my $error_searchmode;
    my $error_literature;
    my $stopwordstring = TextpressoDatabaseSearch::getstopwords(DB_STOPWORDS);
    my $foundstopwords = "";
    
    my $searchfilename = "";
    my $tmpfilename;
    # makes a temp file and checks to see if that temp file name already exists,
    # if so it tries another name.
    
    #########################Lisa changed because my system adds slashes
    ########### DB_TMP . '/' . $tmpfilename; -> DB_TMP . $tmpfilename;
    
    do { $tmpfilename = tmpnam() } until (!-e DB_TMP . $tmpfilename);
    $searchfilename = DB_TMP . $tmpfilename;
    system ("touch $searchfilename");
    
    my $tqueryfilename = "";
    do { $tmpfilename = tmpnam() } until (!-e DB_TMP . $tmpfilename);
    $tqueryfilename = DB_TMP . $tmpfilename;
    system ("touch $tqueryfilename");
    
    my $filteredfilename = "";
    do { $tmpfilename = tmpnam() } until (!-e DB_TMP . $tmpfilename);
    $filteredfilename = DB_TMP . $tmpfilename;
    system ("touch $filteredfilename");
    ########################################################################
    
    # parse the input fields here
    my $newsearch = 0;
    if ($search_mode =~ /(boolean|vector)/i) {
	$newsearch = 1;
	($tpquery, $foundstopwords) = TextpressoWebserviceTasks::ParseInputFields
	    (\@literatures, \@fields, \@categories, $exact_match, $case_sensitive, $keywords, $stopwordstring);
	$tpquery->savetofile($tqueryfilename);
    } else {
	print "FIX THIS. search_mode supported are only boolean and vector for now.\n";
    }
    
    #need to fix this. Replace with ParseAndSearch
    %results = textpressosearch($tpquery, 1, $searchfilename, $search_mode); # 1 corresponds to $newsearch
    
    my %filtered_results = ();
    foreach my $lit (keys %results) {
	foreach my $id (keys % {$results{$lit}}) {
	    foreach my $tgt (keys % {$results{$lit}{$id}}) {
		$filtered_results{$lit}{$id}{$tgt} = $results{$lit}{$id}{$tgt};
	    }
	}
    }
    
    if ($filter_string =~ /\w+/) {
	Filter(\%results, \%filtered_results, $filter_string);
    }
    
    saveresults(\%filtered_results, $filteredfilename);

    my %ltk = littgtkey(\%filtered_results); # this also `cleans' up empty entries of results
    my $extramessage = "Search time: " . int((gettimeofday() - $starttime)*1000)/1000 . " seconds.";
    
    # store the keywords in a temp file for use by ProduceXmlOutput
    my $keywordfilename = "";
    my $tmpfilename1;
    do { $tmpfilename1 = tmpnam() } until (!-e DB_TMP . $tmpfilename1);
    $keywordfilename = DB_TMP . $tmpfilename1;
    open (OUT, ">$keywordfilename");
    foreach (@highlightkeywords) {
	print OUT "$_\n";
    }
    close OUT;
    
    # store the categories in a temp file for use by ProduceXmlOutput
    my $categoryfilename = "";
    my $tmpfilename2;
    do { $tmpfilename2 = tmpnam() } until (!-e DB_TMP . $tmpfilename2);
    $categoryfilename = DB_TMP . $tmpfilename2;
    open (OUT, ">$categoryfilename");
    for (my $i = 0; $i < @{$tpquery->{type}}; $i++) {
	if ($tpquery->type($i) eq 'category') {
	    my $c = $tpquery->data($i);
	    print OUT "$c\n";
	}
    }
    close OUT;
    
    (my $fn) = $filteredfilename =~ /.+\/(.+?)$/;
    my $search_result = TextpressoWebserviceTasks::ProduceXmlOutput($search_mode, $fn, $tmpfilename1, $tmpfilename2);
    return $search_result;
}
