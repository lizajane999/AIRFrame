package TextpressoGeneralGlobals;

# Package provides global constants for
# various matters related to Textpresso.
#
# (c) 2005-8 Hans-Michael Muller, Caltech, Pasadena.

use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(GE_DELIMITERS GE_SPECIALCHARS);

use constant GE_DELIMITERS => { lexicon => '#####',
				start_annotation => '## BOA ##',
				end_annotation => '## EOA ##',
				start_sentence_left => '### s',
				start_sentence_right => ' ###',
				end_sentence => '### EOS ###',
				parent_category => '## PARENTCATEGORY ##',
				annotation_entry_left => '\s|-|^',
				annotation_entry_right => '\s|-|$',
				keyword_entry => '\s',
#				word => ' -'};
				word => '\s'};
        
                                  # rules for replacing perl metacharacters 
                                  # and other characters worth keeping
                                  # with literal descriptions in text ...
    
use constant GE_SPECIALCHARS => { # turns " into DQ
                                  '\"' => "_DQ_",
				  # turns ' into SQ
				  '\'' => "_SQ_",
				  # turns < into LT    
				  '\<' => "_LT_",
				  # turns > into GT
				  '\>' => "_GT_", 
				  # turns + into EQ
				  '\=' => "_EQ_",
				  # turns & into AND
				  '\&' => "_AND_",
				  # turns @ into AT
				  '\@' => "_AT_", 
				  # turns / into SLASH
				  '\/' => "_SLH_",
				  # turns $ into DOLLAR
				  '\$' => "_DLR_",
				  # turns % into PERCENT
				  '\%' => "_PCT_",
				  # turns ^ into CARET
				  '\^' => "_CRT_",
				  # turns * into STAR
				  '\*' => "_STR_",
				  # turns + into PLUS
				  '\+' => "_PLS_",
				  # turns | into VERTICAL
				  '\|' => "_VRT_",
				  # turns \ into BACKSLASH
				  '\\' => "_BSL_",
				  # turns # into HASH
				  '\#' => "_HSH_",
				  # dash has a special place and is not always turned.
				  # turning all punctuation. 
				  # into literals .....
				  '\.' => "_PRD_",
				  '\?' => "_QMK_",
				  '\!' => "_EMK_",
				  '\,' => "_CMM_",
				  '\;' => "_SCL_",
				  '\:' => "_CLN_",
				  '\[' => "_OSB_",
				  '\]' => "_CSB_",
				  '\(' => "_ORB_",
				  '\)' => "_CRB_",
				  '\{' => "_OCB_",
				  '\}' => "_CCB_"};

1;
