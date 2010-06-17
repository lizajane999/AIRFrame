#!/usr/bin/perl

# CGI script splash-page to sentence-saver
#
# Copyright (c) Hans-Michael Muller 2009.

use strict;

# Import the library path TEXTPRESSO_LIB from TextpressoLibrary.pm
use TextpressoLibrary;

use lib TEXTPRESSO_LIB;
use TextpressoDisplayGlobals;
use CGI;

my $query = new CGI;

my $srf = $query->param("fn");
$srf =~ s/^\/tmp\///g;
my $newurl = HTML_ROOT . "cgi-bin\/azurebrd\/sentence\_word\_category\.cgi\?"
    . "action\=Search\+Results\+\!\&curator\=karen\&tempfile=$srf";
print $query->redirect($newurl);
