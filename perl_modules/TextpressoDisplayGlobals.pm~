package TextpressoDisplayGlobals;

# Package provides global constants for all
# Webdisplay related matters of the Textpresso
# system.
#
# (c) 2004 Hans-Michael Muller, Caltech, Pasadena.

# Also contains the "News & Messages" Text
use strict;
use Net::Domain qw(hostname hostfqdn hostdomain);
use Socket;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(DSP_BGCOLOR DSP_TXTCOLOR DSP_LNKCOLOR DSP_AUTHOR DSP_HDRBCKGRND DSP_HDRFACE DSP_HDRSIZE DSP_HDRCOLOR DSP_TXTFACE DSP_TXTSIZE DSP_HIGHLIGHT_COLOR HTML_ROOT HTML_LINKTEMPLATES HTML_MENU HTML_LOGO HTML_PICPASS HTML_NONE HTML_ON HTML_OFF WELCOME HTML_LIT_PATH CGI_LIT_PATH IMG_PATH OWN_CHILD_STRING QUESTION_MARK_IMAGE SYN_LIST SEARCH_KEYWORDS_SYN_KEY SYN_LIST_DISPLAY_KEY);

# Get the name of the localhost
# no need for airframe

# sub htmlroothelper { 
    # workaround to deal with double hostname of 
    # textpresso-www; necessary for cookies to work correctly
  #  my $aux = "http://" . hostfqdn() . "/";
  #   $aux =~ s/textpresso-www\.caltech\.edu/www\.textpresso\.org/g;
  #  return $aux;
# }

## use constant HTML_ROOT => htmlroothelper();
use constant HTML_ROOT => 'http://www.ifa.hawaii.edu/';
####
# -----------------  Begin literature specific changes --------------
####

use constant HTML_LIT_PATH => 'airframe/textpresso/';

####added by RF, for synonyms list
use constant SYN_LIST => 'tdb/astrobiology/syn';

# use constant CGI_LIT_PATH => 'cgi-bin/celegans/';
use constant CGI_LIT_PATH => 'cgi-bin/airframe/textpresso.cgi-bin/';
use constant IMG_PATH => HTML_ROOT . HTML_LIT_PATH . '/gif/';

# use constant HTML_LOGO => HTML_LIT_PATH . '/gif/textpresso4worm.jpg';
use constant HTML_LOGO => 'airframe/textpresso/gif/textpresso_new.jpg';
use constant HTML_PICPASS => HTML_LIT_PATH . '/gif/pwd.jpg';

# This is the text that appears on the home page under News and Messages

use constant WELCOME => '<h4>AIRFrame-Textpresso</h4>
A textmining and information extraction system for astrobiology<br />
<ul><li>
<i><b>This system is under active development</b>, please note any errors, suggestions  and/or constructive criticism and email it to: <a href="mailto:ljmiller@hawaii.edu">Lisa Miller</a> </i>
</li>
<li>As a proof of concept all 10-letter words in search results link to their respective Wikipedia site. This functionality will be used to link concept terms (such as amino acid names) to databases.</li> 
<li>Features include:
<br />
<ul><li>Search for individual keywords and/or all words in one or more categories</li>
<li>Search for synonyms of amino acid names, or for "water". Check "Search synonyms" and try keyword "Sec" and category "Relationships->association" or keyword "H2O" and category "Concepts->celestial entity->meteorite.</li>
<li>Search for terms which include special characters such as "-" or parentheses</li>
<li>Search for phrases which include single characters (such as: "coenzyme q")</li>
<li>Use Boolean expressions (escaping "\" required where shown):
<ul><li>SPACE = AND</li>
<li>\, = OR </li>
<li>\- = AND NOT</li>
<li>\(\) = bracketing for Booleans</li>
</ul></li>
</ul></li></ul>
';

use constant QUESTION_MARK_IMAGE => HTML_ROOT . HTML_LIT_PATH . '/gif/questionmark3.gif';


####
# --------------- End literature specific changes --------------------
####


use constant DSP_BGCOLOR => 'white';
use constant DSP_TXTCOLOR => 'black';
#use constant DSP_LNKCOLOR => '#4d4d4d';
use constant DSP_LNKCOLOR => '#0000ff';
use constant DSP_AUTHOR => 'Hans-Michael Muller';
use constant DSP_HDRBCKGRND => '#444488';
use constant DSP_HDRFACE => 'Verdana,sans-serif';
use constant DSP_HDRSIZE => 'medium';
use constant DSP_HDRCOLOR => 'white';
use constant DSP_TXTFACE => 'verdana, helvetica';
use constant DSP_TXTSIZE => 'small';
use constant DSP_TARGETS => ['abstract', 'acknowledgments', 'body', 'title', 'introduction', 'materials', 'results', 'discussion', 'conclusion', 'references']; 
use constant DSP_SECTION_SEQUENCE => ['title', 'abstract', 'introduction', 'materials', 'results', 'discussion', 'conclusion', 'acknowledgments', 
										'references', 'body']; # section order in which sentences are displayed. 


use constant DSP_HIGHLIGHT_COLOR => {1 => '#ccccff',
				     2 => '#ccffcc',
				     3 => '#ffcccc',
				     4 => '#cccccc',
				     5 => '#ccffff',
				     6 => '#ffccff',
				     7 => '#ffffcc',
				     menutexton => '#00008b',
				     menutextoff => '#ffffff',
				     bgwhite => '#ffffff',
				     oncolor => '#006400',
				     offcolor => '#8b0000',
				     texthighlight => '#ff0000',
				     warning => '#ff0000'};
use constant HTML_LINKTEMPLATES => HTML_ROOT . HTML_LIT_PATH . 'misc/link.templates';


use constant HTML_MENU => { 'Home' => CGI_LIT_PATH . 'home',
			    'Search' => CGI_LIT_PATH . 'search',
			     ##modified by RF 1011/08
			    'Categories/Synonyms' => CGI_LIT_PATH . 'ontology',
                            'Document Finder' => CGI_LIT_PATH . 'docfinder',
			    'User Guide' => CGI_LIT_PATH. 'user_guide',
			    'Feedback' => CGI_LIT_PATH . 'feedback',
			    'Downloads' => CGI_LIT_PATH . 'downloads',
			 
			    'About AIRFrame-Textpresso' => CGI_LIT_PATH . 'about_textpresso',
			    'Copyright' => CGI_LIT_PATH . 'copyright',
			    'Query Language' => CGI_LIT_PATH . 'tql'};

use constant HTML_NONE => 'none';
use constant HTML_ON => 'on';
use constant HTML_OFF => 'off';

# for cascading menu
use constant OWN_CHILD_STRING => ' (all)';

1;
