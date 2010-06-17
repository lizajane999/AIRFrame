package TextpressoDisplayTasks;

# Package provide class and methods for
# tasks related to displaying and maintaining
# WebPages
#
# (c) 2005 Hans-Michael Muller, Caltech, Pasadena.

use strict;
use POSIX;
use TextpressoDatabaseSearch;
use TextpressoGeneralTasks;
use TextpressoGeneralGlobals;
use TextpressoDisplayGlobals;
use TextpressoDatabaseGlobals;
use TextpressoDatabaseCategories;
use TextpressoTable;
use IO::Handle;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(PrintTop PrintBottom TLRTable SimpleList CreateFlipPageInterface ParseInputFields ParseSearchString CreateQueryDisplay CreateKeywordInterface CreateDocIDFilter CreateCategoryInterface CreateLiteratureInterface CreateTargetInterface CreateKeywordSpecInterface CreateSearchScopeInterface CreateSearchModeInterface CreateSortByInterface CreateParameterSettingInterface CreateCommandTextArea CreateCommandExplanations CreateDisplayOptions CreateSynonymListDisplay makeentry PrintStopwordWarning PrintGlobalLinkTable gettext getsentences preparesortresults makehighlightterms CreateFilterInterface Filter FilterMO get_annotations_and_positions get_end_pos annotations_in_xml matching_sentences_in_xml single_biblio_entry_in_xml getwebpage CreateAdditionalTopInterface CreateMoreOptionsInterface noss getSearchSynonymsStatus);

sub PrintTop {
    
    my $query = shift;
    my $myself = shift;
    my $menuflag = shift;
    
    my $location = "";
    foreach my $key (keys % { (HTML_MENU) }) {
	my $aux = (HTML_MENU)->{$key};
	$aux =~ s/\//\\\//g;
	if ($myself =~ /$aux/) {
	    $location = $key;
	}
    }
    
    print $query->header(-cookie => [@_]);

    my $javascript = <<JSEND;
    function openlinkwin(NM, X ,Y, ST) {
		Y = Y - 24;
		var prop = "left=" + X + ",top=" + Y;
		prop = prop + ",width=300,height=150,status=no,toolbar=no,menubar=no,scrollbars=no";
		linkWin = window.open("", NM, prop);
		linkWin.document.write("<HTML><head><title>Multiple Links</title></head>");
		linkWin.document.write ("<BODY>");
		var line = "Multiple links for \'" + NM + "\' found; please choose:<p>";
		linkWin.document.write (line);
		linkWin.document.write (ST);
		linkWin.document.write ("</BODY></HTML>");
		linkWin.document.close();
    }
    function closelinkwin() {
		if (!linkWin.closed)
		    linkWin.self.close();
    }
    function ExpandCollapse(item, img_url) {
		obj=document.getElementById(item);
		image = document.getElementById("i" + item);
		if (obj.style.display=="none") {
		    obj.style.display="block";
		    image.src = img_url + "minus.png";
		} else {
		    obj.style.display="none";
		    image.src = img_url + "plus.png";
		}
    }

    function explainCat() {
		alert("Categories are pre-defined bags of words. Selecting categories for a query makes a search more specific. For example, you can retrieve sentences that contain the word water and any planet by typing the keyword 'water' and choosing the category 'Concepts->celestial entity->planet'. A category hit occurs when a particular word or phrase in the sentence is defined as a member of a particular category. Categories will be concatenated by a Boolean 'AND' operation to other categories and keyword(s) if present.");
    }
	
    function explainKeywords() {
		alert("Enter phrases within double quotes. For Boolean AND, separate keywords by white spaces. For Boolean OR, separate keywords by an escaped comma (\\\\\,) with no white spaces. For Boolean NOT, put an escaped dash (\\\\\-) in front of words which are to be excluded. The keyword parser also processed brackets (one level deep). Use escaped bracket \\\\\( and \\\\\) if you want to use them in the context of Boolean algebra. If brackets are not escaped, they will be taken literally, and a search for brackets in text is initiated, for example glp-1(ar220).");
    }

    function explainSynonyms() {
	alert("Synonyms search allows those sentences containing the synonyms of your search keywords to be returned, in addition to those containing the search keywords.  The synonyms are listed in the search field following each of the keyword you entered as well as right above the result table in all the search results display pages.  At the moment, only the synonyms of the word water and the names of the 21 amino acids are enabled.  To view the entire synonyms list, please go to Categories/Synonyms on the top of the page.");
    }
    
    function explainFilter() {
	alert("Put a '+' sign in front of words which have to be included, a '-' sign in front of words which have to be excluded. Enter the field of the word, viz. author, title, year, journal, abstract, type or sentence in square brackets. Enter phrases in double quotes. For example, to find all the papers in the search result that have 'Patel' as author, but not 'Zheng', enter +Patel-Zheng[author]. You can combine several filters and enter something like '+Patel-Zheng[author] -review[type] +localization[sentence]'. Click on Filter! button to activate the filter.");
    }

var isDOM = (document.getElementById ? true : false);
var isIE4 = ((document.all && !isDOM) ? true : false);
var isNS4 = (document.layers ? true : false);
function getRef(id) {
	if (isDOM) return document.getElementById(id);
	if (isIE4) return document.all[id];
	if (isNS4) return document.layers[id];
}
function getSty(id) {
	return (isNS4 ? getRef(id) : getRef(id).style);
}

// Hide timeout.
var popTimer = 0;
// Array showing highlighted menu items.
var litNow = new Array();
function popOver(menuNum, itemNum) {
	clearTimeout(popTimer);
	hideAllBut(menuNum);
	litNow = getTree(menuNum, itemNum);
	changeCol(litNow, true);
	targetNum = menu[menuNum][itemNum].target;
	if (targetNum > 0) {
		thisX = parseInt(menu[menuNum][0].ref.left) + parseInt(menu[menuNum][itemNum].ref.left);
		thisY = parseInt(menu[menuNum][0].ref.top) + parseInt(menu[menuNum][itemNum].ref.top);
		with (menu[targetNum][0].ref) {
			left = parseInt(thisX + menu[targetNum][0].x)+"px";
			top = parseInt(thisY + menu[targetNum][0].y)+"px";
			visibility = 'visible';
      	}
   	}
}
function popOut(menuNum, itemNum) {
	if ((menuNum == 0) && !menu[menuNum][itemNum].target)
		hideAllBut(0)
	else
		popTimer = setTimeout('hideAllBut(0)', 500);
}
function getTree(menuNum, itemNum) {
	itemArray = new Array(menu.length);
	while(1) {
		itemArray[menuNum] = itemNum;
		if (menuNum == 0) return itemArray;
		itemNum = menu[menuNum][0].parentItem;
		menuNum = menu[menuNum][0].parentMenu;
   	}
}
function changeCol(changeArray, isOver) {
	for (menuCount = 0; menuCount < changeArray.length; menuCount++) {
		if (changeArray[menuCount]) {
			newCol = isOver ? menu[menuCount][0].overCol : menu[menuCount][0].backCol;
			// Change the colours of the div/layer background.
			with (menu[menuCount][changeArray[menuCount]].ref) {
				if (isNS4) bgColor = newCol;
				else backgroundColor = newCol;
   	      	}
      	}
   	}
}
function hideAllBut(menuNum) {
	var keepMenus = getTree(menuNum, 1);
	for (count = 0; count < menu.length; count++)
	if (!keepMenus[count])
		menu[count][0].ref.visibility = 'hidden';
	changeCol(litNow, false);
}
function Menu(isVert, popInd, x, y, width, overCol, backCol, borderClass, textClass) {
	this.isVert = isVert;
	this.popInd = popInd
	this.x = x;
	this.y = y;
	this.width = width;
	this.overCol = overCol;
	this.backCol = backCol;
	this.borderClass = borderClass;
	this.textClass = textClass;
	this.parentMenu = null;
	this.parentItem = null;
	this.ref = null;
}
function Item(text, href, frame, length, spacing, target) {
	this.text = text;
	this.href = href;
	this.frame = frame;
	this.length = length;
	this.spacing = spacing;
	this.target = target;
	this.ref = null;
}
function writeMenus() {
	if (!isDOM && !isIE4 && !isNS4) return;

	for (currMenu = 0; currMenu < menu.length; currMenu++) 
	with (menu[currMenu][0]) {
		var str = '';
		var itemX = 0, itemY = 0;

		for (currItem = 1; currItem < menu[currMenu].length; currItem++) 
		with (menu[currMenu][currItem]) {
			var itemID = 'menu' + currMenu + 'item' + currItem;

			var w = (isVert ? width : length);
			var h = (isVert ? length : width);

			if (isDOM || isIE4) {
				str += '<div id="' + itemID + '" style="position: relative; left: ' + itemX + 'px';
				str += '; top: ' + itemY + 'px' + '; width: ' + w + 'px' + '; height: ' + h + 'px' + '; visibility: inherit; ';
				if (backCol) str += 'background: ' + backCol + '; ';
				str += '" ';
			}
			if (isNS4) {
				str += '<layer id="' + itemID + '" left="' + itemX + 'px' + '" top="' + itemY + 'px';
				str += '" width="' +  w + 'px' + '" height="' + h  + 'px'+ '" visibility="inherit" ';
				if (backCol) str += 'bgcolor="' + backCol + '" ';
			}

			if (borderClass) str += 'class="' + borderClass + '" ';

			str += 'onMouseOver="popOver(' + currMenu + ',' + currItem + ')"';
			str += 'onMouseOut="popOut(' + currMenu + ',' + currItem + ')">';

			str += '<table width="' + (w - 8) + 'px' + '" border="0" cellspacing="0" cellpadding="';
			str += (!isNS4 && borderClass ? 3 : 0)  + 'px'+ '"><tr><td align="left" height="' + (h - 7)  + 'px'+ '">';
			str += '<a class="' + textClass + '" href="' + href + '"' + (frame ? ' target="' + frame + '">' : '>');
			str += text + '</a></td>';
			if (target > 0) {
				menu[target][0].parentMenu = currMenu;
				menu[target][0].parentItem = currItem;

				if (popInd) str += '<td class="' + textClass + '" align="right">' + popInd + '</td>';
			}
			str += '</tr></table>' + (isNS4 ? '</layer>' : '</div>');
			if (isVert) itemY += length + spacing;
			else itemX += length + spacing;
		}
		if (isDOM) {
			var newDiv = document.createElement('div');
			document.getElementsByTagName('body').item(0).appendChild(newDiv);
			newDiv.innerHTML = str;
			ref = newDiv.style;
			ref.position = 'absolute';
			ref.visibility = 'hidden';
		}

		if (isIE4) {
			document.body.insertAdjacentHTML('beforeEnd', '<div id="menu' + currMenu + 'div" ' + 'style="position: relative; visibility: hidden">' + str + '</div>');
			ref = getSty('menu' + currMenu + 'div');
		}

		if (isNS4) {
			ref = new Layer(0);
			ref.document.write(str);
			ref.document.close();
		}

		for (currItem = 1; currItem < menu[currMenu].length; currItem++) {
			itemName = 'menu' + currMenu + 'item' + currItem;
			if (isDOM || isIE4) menu[currMenu][currItem].ref = getSty(itemName);
			if (isNS4) menu[currMenu][currItem].ref = ref.document[itemName];
  	 	}
	}
	with(menu[0][0]) {
		ref.left = x;
		ref.top = y;
		ref.visibility = 'hidden';
   	}
}
// Textpresso function
function loadCat(string, ownChildStr) {
	var cat1 = document.getElementById('cat1');
	var cat2 = document.getElementById('cat2');
	var cat3 = document.getElementById('cat3');
	var cat4 = document.getElementById('cat4');
	var cat5 = document.getElementById('cat5');

	if (cat1.value == "Select category 1 from list above") {
		cat1.value = string;
	} else if (cat2.value == "Select category 2 from list above") {
		cat2.value = string;
	} else if (cat3.value == "Select category 3 from list above") {
		cat3.value = string;
	} else if (cat4.value == "Select category 4 from list above") {
		cat4.value = string;
	} else if (cat5.value == "Select category 5 from list above") {
		cat5.value = string;
	}
	hideAllBut(0);
}
function resetCat(catNum) {
	var cat = document.getElementById('cat'+catNum);
	cat.value = "Select category " + catNum + " from list above";
}

var menu = new Array();
function loadMenus(masterString, ownChildStr, gpMenuLength, pMenuLength, cMenuLength) {
	var defOver = '#eedd7a', defBack = '#abccdb';
	var defLength = 19;
	var menuLength = new Array();

	// menu[0] used as a hidden menu used for proper javascript alignment with CGI
	menuLength[0] = 60;
	menu[0] = new Array();
	menu[0][0] = new Menu(true, '<font size="1">></font>', 0, 0, menuLength[0], defOver, defBack, 'itemBorder', 'itemText');
	menu[0][1] = new Item(' <font size="1">List</font>  ', '#', '', 20, 0, 1);

	// grand parent menu
	menuLength[1] = gpMenuLength*8;
	menuLength[2] = pMenuLength*6;
	menuLength[3] = cMenuLength*6;
	menu[1] = new Array();
	var gapX = 13; var gapY = 265;
	var tmp3 = menuLength[0]+gapX;
	var tmp4 = defLength+gapY;
	menu[1][0] = new Menu(true, '<font size="1"><b>></b></font>', tmp3, tmp4, menuLength[1], defOver, defBack, 'itemBorder', 'itemText');
	var array1 = masterString.split(/GRANDPARENT/);
	var childMenuIndex = array1.length + 1;
	for (i=0; i<array1.length; i++) {
		var grandEntry = array1[i];
		var array2 = grandEntry.split(/XXGGPPXX/);
		var grandParent = array2[0];
		var parentMenuIndex = 2+i;
		var length = 18;
		var spacing = -18;
		menu[1][i+1] = new Item('<font size="1" face="Helvetica"><b>'+grandParent+'</b></font>', '#', '', length, spacing, parentMenuIndex);

		// parent menu
		menu[parentMenuIndex] = new Array();
		var x = menuLength[1] + 1;
		var y = defLength*(i+1)-16;
		var width = menuLength[2];
		menu[parentMenuIndex][0] = new Menu(true, '<font size="1"><b>></b></font>', x, y, width, defOver, defBack, 'itemBorder', 'itemText');
		var parentChildEntries = array2[1];
		var array3 = parentChildEntries.split(/PARENT/);
		for (j=0; j<array3.length; j++) {
			var parentChildren = array3[j];
			var array4 = parentChildren.split(/XXPPXX/);
			var parent = array4[0];
			var childMenuIndex;
			if (array4[1]) { // this parent has children
				childMenuIndex++;
				var p2 = parent;
				var re = / \\\(all\\\)/;
				p2 = p2.replace(re, "");
				menu[parentMenuIndex][1+j] = new Item('<font size="1" face="Helvetica"><b>'+p2+'</b></font>', '#', '', length, spacing, childMenuIndex);
				var childrenEntries = array4[1];
				var children = childrenEntries.split(/XXCCXX/);
				menu[childMenuIndex] = new Array();
				var x = menuLength[2] + 1;
				var y = defLength*(j+1)-17-j;
				var width = menuLength[3];
				menu[childMenuIndex][0] = new Menu(true, '<font size="1"><b>></b></font>', x, y, width, defOver, defBack, 'itemBorder', 'itemText');

				for (k=0; k<children.length; k++) {
					var re = / \\\(all\\\)/;
					if (re.test(children[k])) {
						break;
					}
				}
				menu[childMenuIndex][1] = new Item('<font size="1" face="Helvetica"><b>'+children[k]+'</b></font>', 
													"javascript:loadCat('"+children[k]+"','"+ownChildStr+"')", '', length, spacing, 0);
				children.splice(k, 1);
				for (k=0; k<children.length; k++) {
					menu[childMenuIndex][k+2] = new Item('<font size="1" face="Helvetica"><b>'+children[k]+'</b></font>', 
														"javascript:loadCat('"+children[k]+"','"+ownChildStr+"')", '', length, spacing, 0);
				}
			} else {
				menu[parentMenuIndex][1+j] = new Item('<font size="1" face="Helvetica"><b>'+parent+'</b></font>', 
														"javascript:loadCat('"+parent+"','"+ownChildStr+"')", '', length, spacing, 0);
			}
		}
	}

	return;
}

function printCats(masterString, ownChildStr, gpMenuLength, pMenuLength, cMenuLength) {
	loadMenus(masterString, ownChildStr, gpMenuLength, pMenuLength, cMenuLength);
	writeMenus();
}

//added by RF, 10/09/08, for checking the exactmatch if the searchsynonyms checkbox is checked.
function checkExactMatch (element, id) {
    if (element.value == 'on'){
	document.getElementById(id).checked=true;
	element.focus( );
	return false;
    }
    return true;
}
//end added by RF
JSEND

    my %hash = ();
    for my $grandParent (sort keys %{(DB_SUPERCATEGORIES)} ) {
	my @parents = @{(DB_SUPERCATEGORIES)->{$grandParent}};
	
	for my $parent (@parents) {
	    if (defined (@{(DB_CATEGORYCHILDREN)->{$parent}})) {
		my @children = @{(DB_CATEGORYCHILDREN)->{$parent}};
		my $ownChild = $parent;
		push @children, $ownChild;
		for my $child (@children) {
		    $hash{$grandParent}{$parent}{$child} = 1;
		}
	    } else {
		$hash{$grandParent}{$parent} = 1;
	    }
	}
    }
    
    my $masterString = '';
    for my $gP (sort keys %hash) {
	$masterString .= $gP . 'XXGGPPXX';
	if ($hash{$gP} != 1) {
	    for my $p (sort keys %{$hash{$gP}}) {
		$masterString .= $p . 'XXPPXX';
		if ($hash{$gP}{$p} != 1) {
		    for my $c (sort keys %{$hash{$gP}{$p}}) {
			$masterString .= $c . 'XXCCXX'; # child separator
		    }
		    $masterString =~ s/XXCCXX$//;
		}
		$masterString .= 'PARENT'; # parent separator
	    }
	    $masterString =~ s/PARENT$//;
	    $masterString .= 'GRANDPARENT'; # grandParent separator
	}
    }
    $masterString =~ s/GRANDPARENT$//;
    
    # Set menu lengths depending on the length of the characters in each level of depth
    my $gpMenuLength = 0; my $pMenuLength = 0; my $cMenuLength = 0;
    my @gpArray =  keys %{(DB_SUPERCATEGORIES)};
    for my $gp (@gpArray) {
	my @chars = split(//, $gp);
	$gpMenuLength = @chars if (@chars > $gpMenuLength);
	my @parents = @{(DB_SUPERCATEGORIES)->{$gp}};
	for my $p (@parents) {
	    @chars = split(//, $p);
	    $pMenuLength = @chars if (@chars > $pMenuLength);
	    if (defined (@{(DB_CATEGORYCHILDREN)->{$p}})) {
		my @children = @{(DB_CATEGORYCHILDREN)->{$p}};
		for my $c (@children) {
		    @chars = split (//, $c);
		    $cMenuLength = @chars if (@chars > $cMenuLength);
		}
	    }
	}
    }
    
    
    my $ownChildStr = OWN_CHILD_STRING;
    print $query->start_html(-title => $location,
			     -script => $javascript,
			     -author => DSP_AUTHOR,
			     -text => DSP_TXTCOLOR,
			     -link => DSP_LNKCOLOR,
			     -vlink => DSP_LNKCOLOR,
			     -bgcolor => DSP_BGCOLOR,
			     -onLoad=>"printCats('$masterString', '$ownChildStr', '$gpMenuLength', '$pMenuLength', '$cMenuLength')");
    print $query->start_center;
    print $query->img({ -src => HTML_ROOT . HTML_LOGO,
			-border => 0});
    
    if ($menuflag) {
	my @menu = sort keys % { (HTML_MENU) };
	for (my $i = 0; $i < @menu; $i++) {
	    my $link = (HTML_ROOT) . (HTML_MENU)->{$menu[$i]};
	    if ($menu[$i] =~ /^$location$/) {
		my $clr = (DSP_HIGHLIGHT_COLOR)->{menutexton};
		$menu[$i] = "<span style='color:$clr'>" . $menu[$i] . "</span>"; 
	    } else {
		my $clr = (DSP_HIGHLIGHT_COLOR)->{menutextoff};
		$menu[$i] = "<span style='color:$clr;'>" . $menu[$i] . "</span>"; 
	    }
	    $menu[$i] = "<a href='$link' style='text-decoration: none'>" . $menu[$i] . "</a>";
	}  
	my $main_menu = new TextpressoTable;
	$main_menu->init;
	$main_menu->addtablerow(@menu);
	print $main_menu->maketable($query,
				    tablestyle => 'borderless-headerbackground',
				    DSP_HDRBCKGRND => '#999999',
				    DSP_HDRSIZE => 'medium');
    }
    print $query->end_center;
    
    return $location;
}

sub PrintBottom {
    
    my $query = shift;
    my $extramessage = shift;
    print $query->p;
    print $query->span({-style=>"font-size:x-small;"}, "� Textpresso ", scalar localtime, ". ");
    print $query->span({-style=>"font-size:x-small;"}, $extramessage) if ($extramessage ne '');
    print $query->end_html;
}

sub TLRTable { # stands for Top-(Left-Right) Table
    
    my $query = shift;
    my $top = shift;
    my $left = shift;
    my $right = shift;
    my $width = shift;
    my $returnstring = "";
    
    my $auxtb = new TextpressoTable;
    $auxtb->init;
    $auxtb->addtablerow(""); # no header, please
    $auxtb->addtablerow($top);
    $returnstring = $auxtb->maketable($query,
				      tablestyle => 'borderless',
				      width => $width);
    $auxtb->init;
    $auxtb->addtablerow(""); # no header, please
    $auxtb->addtablerow($left, $right);
    $returnstring .= $auxtb->maketable($query,
				      tablestyle => 'borderless',
				      width => $width);

    return $returnstring;
}

sub SimpleList { # made with table
    
    my $query = shift;
    my $returnstring = "";
    
    my $auxtb = new TextpressoTable;
    $auxtb->init;
    foreach (@_) {
	$auxtb->addtablerow($_);
    }
    return $auxtb->maketable($query,
			     tablestyle => 'borderless',
			     DSP_HDRCOLOR => 'black',
			     DSP_HDRSIZE => 'small',
			     width => '100%');		     
}

sub generateweblinks {
    
    my $query = shift;
    my $string = shift;
    my $output = $string;
    my $on = shift;
    my $p_urls = shift;
    my $p_regexps = shift;
    my $p_explanations = shift;
    
    my @urls = @$p_urls; my @regexps = @$p_regexps; my @explanations = @$p_explanations;
    
    if (!$on) {
	return $output;
    }
    
    my %foundterms = ();
    for (my $i=0; $i < @regexps; $i++) {
	my @matches;
	while ($string =~ /($regexps[$i])/g) {
	    push (@matches, $1);
	}
	
	if (@matches) {
	    foreach my $match (@matches) {
		if (!($match eq "")) {
		    $foundterms{$match}{$i} = 1;
		}
	    }
	}
    }
    
    foreach my $term (keys % foundterms) {
	my $target;
	my @nmbs = keys % {$foundterms{$term}};
	if (scalar(@nmbs) < 2) {
	    (my $suburl = $urls[$nmbs[0]]) =~ s/\#\#\#/$term/;
	    my $e = $explanations[$nmbs[0]];
	    $target = $query->a({href=>$suburl, -target=>"_blank",
				 title=>"Link to $e",
				 style=>'text-decoration:none'}, " $term ");
	} else {
	    my $e = "<p>";
	    foreach my $inst (@nmbs) {
		(my $auxurl = $urls[$inst]) =~ s/\#\#\#/$term/;
		$e .= "<a href='" . $auxurl . "' target='_blank'>";
		$e .= $explanations[$inst];
		$e .= "</a><br>";
	    }
	    my $here = rand() . rand();
	    $target = $query->a({href=>"#here", target =>"_self", 
				 # anchor 'here' does not exist, so page stays where it is (hopefully).
				 onClick=>"openlinkwin(\"$term\", event.screenX, event.screenY,\"$e\")",
				 style=>'text-decoration:none'}, $term);
	}
	$output =~ s/(^| )$term( |$)/ $target /g;
    }
	
    return $output;
}

sub CreateFlipPageInterface {

    my $query = shift;
    my $prev = shift;
    my $selector = shift;
    my $next = shift;
    my $displaypage = shift;
    my @choices = @_;

    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("");
    $aux->addtablerow("Goto:");
    my @row = ();
    if ($prev) {
	push @row, $query->submit(-name => 'previouspage', -value => 'previous page')
	    . $query->font(" ");
	
    }
    if ($selector) {
	push @row,$query->font(" ") 
	    . $query->submit(-name => 'gotopage', -value => 'page') 
	    . $query->popup_menu(-name =>'page',
				 -default => $displaypage,
				 -values => \@choices)
	    . $query->font("of", scalar @choices)
	    . $query->font(" ");
    }
    if ($next) {
	push @row, $query->font(" ") . 
	    $query->submit(-name => 'nextpage', -value => 'next page');
    }
	
    $aux->addtablerow(@row);

    return $aux->maketable($query, tablestyle => 'borderless', valign => 'middle');
}

sub ParseInputFields {
    
    my $query = shift;
    my $stopwordstring = shift;
    my $tpquery = new TextpressoDatabaseQuery;
    $tpquery->init;
    
    my %literatures = ();
    foreach ($query->param('literature')) {
	$literatures{$_} = 1;
    }
#
    my %targets = ();
    foreach ($query->param('target')) {
	$targets{$_} = 1;
    }

#    
    for (my $i = 1; $i < 5; $i++) {
	if ($query->param("cat$i") !~ /^Select/) {
	    my $aux = (DB_CATEGORIES)->{$query->param("cat$i")};
	    if (defined(@{(DB_CATEGORYCHILDREN)->{$query->param("cat$i")}})) {
		foreach my $child (@{(DB_CATEGORYCHILDREN)->{$query->param("cat$i")}}) {
		    $aux .= "," . (DB_CATEGORIES)->{$child};
		}
	    }
	    $tpquery->addsimple('category', $aux,
				$query->param('sentencerange'), $query->param('exactmatch') || 0,
				$query->param('casesensitive') || 0, \%literatures, \%targets);
	}
    }
#
    my $foundstopwords = ParseSearchString($query->param('searchstring'), $tpquery, $stopwordstring, 0, '>',
					   $query->param('sentencerange'), $query->param('exactmatch') || 0,
					   $query->param('casesensitive') || 0, \%literatures, \%targets);
#

    return ($tpquery, $foundstopwords);
}

sub ParseSearchString {
    
    my $string = shift;
    my $tpquery = shift;
    my $stopwordstring = shift;
    my $num = shift;
    my $comp = shift;
    my $range = shift;
    my $exactmatch = shift;
    my $casesensitive = shift;
    my $pLit = shift;
    my $pTgt = shift;
    my $foundstopwords = "";
    
    my $originalstring = $string;
    my @phrases = ();
    while ($string =~ /(^|\s)\"([^\"]+)\"(\s|,|\s-|$)/g) {
	push @phrases, $2;
	$string =~ s/$1\"$2\"//;
    }	   
    my @words = ();
    while ($string =~ /(^|\s)(\S+?)(\s|,|\s-|$)/g) {
	push @words, $2;
	$string =~ s/$1$2//;
    }

    my %ticket = ();
    foreach my $t (@phrases) {
	my @entries = split(/\s/, $t);
	my $aux = shift(@entries);
	if ($stopwordstring =~ /\s$aux\s/) {
	    $foundstopwords .= $aux . " ";
	} else {
	    $tpquery->addspecific('&&', 'keyword', $aux, $num, $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	}
	while (my $word = shift(@entries)) {
	    if ($stopwordstring =~ /\s$word\s/) {
		$foundstopwords .= $word . " ";
	    } else {
		$tpquery->addspecific('++', 'keyword', $word, $num, $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	    }
	}
    }
    foreach my $t (@words) {
	if ($stopwordstring =~ /\s$t\s/) {
	    $foundstopwords .= $t . " ";
	} else {
	    $tpquery->addspecific('&&', 'keyword', $t, $num, $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	}
    }

    return $foundstopwords;	   
}

sub CreateQueryDisplay {

    my $query = shift;
    my $tpquery = shift;

    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Query");
    $aux->addtablerow("Condition", 
		      "Concatenation", 
		      "Type", 
		      "Data Entry", 
		      "Comparison",
		      "Numerics",
		      "Sentence Range",
		      "Exact Match?",
		      "Case Sensitive?",
		      "Literatures",
		      "Fields");
    for (my $i = 0; $i < $tpquery->numberofconditions; $i++) {
	my $matchanswer = ($tpquery->exactmatch($i) == 1) ? 'yes' : 'no';
	my $caseanswer = ($tpquery->casesensitive($i) == 1) ? 'yes' : 'no';
	$aux->addtablerow($i,
			  $tpquery->boolean($i),
			  $tpquery->type($i),
			  $tpquery->data($i),
			  $tpquery->comparison($i),
			  $tpquery->occurrence($i),
			  $tpquery->range($i),
			  ($tpquery->exactmatch($i)) ? 'yes' : 'no',
			  ($tpquery->casesensitive($i)) ? 'yes' : 'no',
			  join(", ", $tpquery->literatures($i)),
			  join(", ", $tpquery->targets($i)));
    }

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground', 
			   DSP_HDRBCKGRND => (DSP_HIGHLIGHT_COLOR)->{bgwhite},
			   DSP_HDRCOLOR => 'black');
}

sub CreateDocIDFilter {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Doc ID Filter");
    $aux->addtablerow($query->textfield(-name => 'docidfilter', -size => 50, -maxlength => 255));
    $aux->addtablerow("Leave field empty for no filtering to occur.");
    $aux->addtablerow("If field is filled, only matching entries will be displayed. ");

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small',
			   width => '100%');
}

sub CreateLiteratureInterface {

    my $query = shift;
    my $error = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Literature");
    $aux->addtablerow($query->checkbox_group(-name => 'literature',
					     -values => [sort keys %{(DB_LITERATURE)}],
					     -defaults => [@{(DB_LITERATURE_DEFAULTS)}],
					     -cols => 1));

    return $aux->maketable($query,
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => $error || '#5870a3',
			   width => '50%');
}

sub CreateTargetInterface {

    my $query = shift;
    my @cv = ();
    my $cookieflag = 0;
    foreach my $t (keys %{(DB_SEARCH_TARGETS)}) {
	if (defined($query->cookie("cookie-target-$t"))) {
	    $cookieflag = 1;
	    push @cv, $t if ($query->cookie("cookie-target-$t"));
	}
    }
    my @def = ();
    if ($cookieflag) {
	@def = @cv;
    } else {
	@def = @{(DB_SEARCH_TARGETS_DEFAULTS)};
    }
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Fields");
	
	my @turned_on_fields = ();
	if (!defined($query->param('target'))) {
		for my $t ( keys %{(DB_SEARCH_TARGETS)} ) {
			if ($query->cookie("cookie_target_$t") eq HTML_ON) {
				push @turned_on_fields, $t;
			}
		}
	}
	if (@turned_on_fields == 0) {
		foreach (@{(DB_SEARCH_TARGETS_DEFAULTS)}) {
			push @turned_on_fields, $_;
		}
	}
	my @target_fields = keys %{(DB_SEARCH_TARGETS)};
	for (my $i=0; $i < @target_fields; $i++) {
		if ($target_fields[$i] eq "body") {
			$target_fields[$i] = "non-sectioned";
		}
		if ($turned_on_fields[$i] eq "body") {
			$turned_on_fields[$i] = "non-sectioned";
		}
	}
    $aux->addtablerow($query->checkbox_group(-name => 'target',
					     -values => [sort @target_fields],
					     -defaults => [@turned_on_fields],
						 -rows => 6,
					     -columns => 2));

    return $aux->maketable($query,
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#5870a3',
			   width => '50%');    
}

sub CreateTargetInterfaceOld {

    my $query = shift;
    my @cv = ();
    my $cookieflag = 0;
    foreach my $t (keys %{(DB_SEARCH_TARGETS)}) {
	if (defined($query->cookie("cookie-target-$t"))) {
	    $cookieflag = 1;
	    push @cv, $t if ($query->cookie("cookie-target-$t"));
	}
    }
    my @def = ();
    if ($cookieflag) {
	@def = @cv;
    } else {
	@def = @{(DB_SEARCH_TARGETS_DEFAULTS)};
    }
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Fields");

    $aux->addtablerow($query->checkbox_group(-name => 'target',
					     -values => [sort keys %{(DB_SEARCH_TARGETS)}],
					     -defaults => [@def],
#					     -defaults => [@{(DB_SEARCH_TARGETS_DEFAULTS)}],
					     -rows => 1));

    return $aux->maketable($query,
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#5870a3',
			   width => '50%');    
}

sub CreateSearchScopeInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Search Scope");
    $aux->addtablerow($query->popup_menu(-name => 'sentencerange',
					 -values => [sort keys %{(DB_SEARCH_RANGES)}],
					 -default => DB_SEARCH_RANGES_DEFAULT));

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#5870a3',
			   width => '50%');
}

sub CreateSearchModeInterface {

    my $query = shift;
    my $error = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Search Mode");
    $aux->addtablerow($query->popup_menu(-name => 'mode',
					 -values => [sort @{(DB_SEARCH_MODE)}],
					 -default => DB_SEARCH_MODE_DEFAULT));    

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => $error || '#5870a3',
			   width => '50%');
}

sub CreateSortByInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Sort by");
    my @sortchoice = sort ("score (hits)", keys % {(DB_DISPLAY_FIELDS)});
    $aux->addtablerow($query->popup_menu(-name => 'sort',
					 -values => [@sortchoice],
					 -default => 'score (hits)'));

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#5870a3',
			   width => '50%');
}

sub CreateParameterSettingInterface {

    my $query = shift;
    my $paramtable = new TextpressoTable;
    $paramtable->init;
    $paramtable->addtablerow("Parameter Settings");
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Literature(s): ") .
			     $query->span({-style => 'font-weigt:normal;'}, join(", " , $query->param('literature'))));
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Field(s): ") .
			     $query->span({-style => 'font-weigt:normal;'}, join(", " , $query->param('target'))));
    my $answer = ($query->param('exactmatch')) ? 'Yes' : 'No';
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Exact match? ") .
			     $query->span({-style => 'font-weigt:normal;'}, $answer));
    $answer = ($query->param('casesensitive')) ? 'Yes' : 'No';
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Case sensitive? ") .
			     $query->span({-style => 'font-weigt:normal;'}, $answer));
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Sentence Scope: ") .
			     $query->span({-style => 'font-weigt:normal;'}, $query->param('sentencerange')));
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Search Mode: ") .
			     $query->span({-style => 'font-weigt:normal;'}, $query->param('mode')));
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Sorted by: ") .
			     $query->span({-style => 'font-weigt:normal;'}, $query->param('sort')));
    
    return $paramtable->maketable($query, tablestyle => 'borderless-headerbackground', 
				  DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#5870a3', width => "100%");
}

sub CreateCommandTextArea {

    my $query = shift;
    my $title = shift;
    my $line1 = shift;
    my $line2 = shift;
    my $commandtable = new TextpressoTable;
    $commandtable->init;
    $commandtable->addtablerow("Commands");
    $commandtable->addtablerow($query->span({-style => 'font-style:normal;'}, $line1) .
			       $query->span({-style => 'font-style:normal;'}, $line2));
    $commandtable->addtablerow($query->textarea(-name => 'commands',
						-rows => '8',
						-columns => '50'));
    $commandtable->addtablerow($query->submit(-name => 'submit',
					      -value => 'Submit!'));
    
    return $commandtable->maketable($query, tablestyle => 'borderless-headerbackground',  
				    DSP_HDRSIZE => 'small', width => "100%");
}

sub CreateCommandExplanations {
    
    my $query = shift;
    my $history = shift;
    my $explanation = new TextpressoTable;
    $explanation->init;
    $explanation->addtablerow("Explanations");
    $explanation->addtablerow($query->span({-style => 'font-weight:bold;'}, "Available Commands:"));
    $explanation->addtablerow($query->span({-style => 'font-style:italic;'}, "set ") .
			      $query->span({-style => 'font-style:normal;'}, "parameter-name ") .
			      $query->span({-style => 'font-style:italic;'}, "= ") .
			      $query->span({-style => 'font-style:normal;'}, "value-1, value-2, ... \'"));
    $explanation->addtablerow($query->span({-style => 'font-style:italic;'}, "clear ") .
			      $query->span({-style => 'font-style:normal;'}, "(parameter-name | ") .
			      $query->span({-style => 'font-style:italic;'}, "all") .
			      $query->span({-style => 'font-style:normal;'}, ")"));
    $explanation->addtablerow($query->span({-style => 'font-style:italic;'}, "find ") .
			      $query->span({-style => 'font-style:normal;'}, "(") .
			      $query->span({-style => 'font-style:italic;'}, "keyword ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "category") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "attribute") .
			      $query->span({-style => 'font-style:normal;'}, ") (keyword | ") .
			      $query->span({-style => 'font-style:italic;'}, "\"") .
			      $query->span({-style => 'font-style:normal;'}, "phrase") .
			      $query->span({-style => 'font-style:italic;'}, "\"") .
			      $query->span({-style => 'font-style:normal;'}, " | category | category") .
			      $query->span({-style => 'font-style:italic;'}, ":") .
			      $query->span({-style => 'font-style:normal;'}, "attribute") .
			      $query->span({-style => 'font-style:italic;'}, ":") .
			      $query->span({-style => 'font-style:normal;'}, "value) (") .
			      $query->span({-style => 'font-style:italic;'}, "< ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "== ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, ">") .
			      $query->span({-style => 'font-style:normal;'}, ") number ") .
			      $query->span({-style => 'font-style:italic;'}, "->") .
			      $query->span({-style => 'font-style:normal;'}, " variable-name"));
    $explanation->addtablerow($query->span({-style => 'font-style:normal;'}, "(") .
			      $query->span({-style => 'font-style:italic;'}, "and ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "or ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "not") .
			      $query->span({-style => 'font-style:normal;'}, ") ") .
			      $query->span({-style => 'font-style:normal;'}, "variable-name-1 variable-name-2 ") .
			      $query->span({-style => 'font-style:italic;'}, "->") .
			      $query->span({-style => 'font-style:normal;'}, " variable-name-3"));
    $explanation->addtablerow($query->span({-style => 'font-style:italic;'}, "display ") .
			      $query->span({-style => 'font-style:normal;'}, "variable-name"));
    if ($history ne "") {
	$explanation->addtablerow("");
	$explanation->addtablerow($query->span({-style => 'font-weight:bold;'}, "Last Command(s):"));
	$explanation->addtablerow($query->span({-style => 'font-style:normal;'}, $history));
    }
    
    return $explanation->maketable($query, tablestyle => 'borderless-headerbackground',  
				   DSP_HDRSIZE => 'small', width => "100%", DSP_HDRBCKGRND => 'seagreen');
}

# added by RF
sub CreateSynonymListDisplay {

    my $query = shift;
    ####added by RF, 100908 for synonyms search
    my $lastSynonymsSearch = shift;
    ##added by RF, displaying keywords & synonyms in each page
    my $synListDisplay = shift;
    ####end added by RF
    my $aux = new TextpressoTable;
    $aux->init;
    ####added by RF, 100908 for synonyms search

    if($lastSynonymsSearch eq 'on'){
	$query -> param(-name=>'synListDisplay', -value=>$synListDisplay);
	$aux->addtablerow("");
	my $keywordsSynDisplay = "Keywords & Synonyms: " . $synListDisplay;
	$aux->addtablerow($query->span({-style=>"font-weight:bold;"}, $keywordsSynDisplay));
    }
    ####end added by RF

    return $aux->maketable($query, tablestyle => 'borderless', valign => 'middle');
}
# end added by RF

sub CreateDisplayOptions {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("");
    $aux->addtablerow($query->span({-style=>"font-weight:bold;"}, "Display options:"));

    my $none = HTML_NONE;
    my $on = HTML_ON;
    my $off = HTML_OFF;

    my @row = ();
    my $count = 0;
    my $selfurl = $query->self_url;
    my $oncolor = (DSP_HIGHLIGHT_COLOR)->{oncolor};
    my $offcolor = (DSP_HIGHLIGHT_COLOR)->{offcolor};
    foreach my $opt ('searchterm-highlighting', 'expand-sentences') {
		my $entry = $opt . ': ';
		if (!defined($query->param("disp_$opt"))) {
		    $query->param(-name => "disp_$opt", -value => $on);
		}
		(my $actualurl = $selfurl) =~ s/disp_$opt=$on//g; 
		$actualurl =~ s/disp_$opt=$off//; 
		if ($query->param("disp_$opt") eq $on) {
		    $entry .= $query->start_b;
		    $entry .= $query->a({-href => "$actualurl\;disp_$opt=$on"}, $query->span({-style=>"font-size:small;color:$oncolor"}, $on));
		    $entry .= $query->end_b;
		    $entry .= $query->span({-style=>"font-size:small;"}, " | ");
		    $entry .= $query->a({-href => "$actualurl\;disp_$opt=$off"}, $query->span({-style=>"font-size:small;"}, $off));
		} else {
		    $entry .= $query->a({-href => "$actualurl\;disp_$opt=$on"}, $query->span({-style=>"font-size:small;"}, $on));
		    $entry .= $query->span({-style=>"font-size:small;"}, " | ");
		    $entry .= $query->start_b;
		    $entry .= $query->a({-href => "$actualurl\;disp_$opt=$off"}, $query->span({-style=>"font-size:small;color:$oncolor"}, $off));
		    $entry .= $query->end_b;
		}
		push @row, $entry;
		if ((++$count % 5) == 0) {
		    $aux->addtablerow(@row);
		    @row = ();
		}
    }
    my $entry = "matching sentences: ";
    if (!defined ($query->param("disp_matches"))) {
	$query->param(-name => "disp_matches", -value => 1);
    }
    (my $actualurl = $selfurl) =~ s/disp_matches=($none|1)//g;
    foreach my $opt ("$none", 1) {
	my $str = "";
	if ($query->param("disp_matches") == $opt) {
	    $entry .= $query->start_b;
	    $str = $query->span({-style=>"font-size:small;color:$oncolor"}, $opt);
	} else {
	    $str = $opt;
	}
	$entry .= $query->a({-href => "$actualurl\;disp_matches=$opt"}, $query->span({-style=>"font-size:small;"}, $str));
	$entry .= $query->span({-style=>"font-size:small;"}, " ");
	if ($query->param("disp_matches") == $opt) {
	    $entry .= $query->end_b;
	}
    }
    push @row, $entry;
    if ((++$count % 5) == 0) {
	$aux->addtablerow(@row);
	@row = ();
    }
    $entry = "entries/page: ";
    if (!defined($query->param("disp_epp"))) {
	$query->param(-name => "disp_epp", -value => 5);
    }
    ($actualurl = $selfurl) =~ s/disp_epp=(5|10|20|50)//g;
    foreach my $opt (5, 10, 20, 50) {
	my $str = "";
	if ($query->param("disp_epp") == $opt) {
	    $entry .= $query->start_b;
	    $str = $query->span({-style=>"font-size:small;color:$oncolor"}, $opt);
	} else {
	    $str = $opt;
	}
	$entry .= $query->a({-href => "$actualurl\;disp_epp=$opt"}, $query->span({-style=>"font-size:small;"}, $str));
	$entry .= $query->span({-style=>"font-size:small;"}, " ");
	if ($query->param("disp_epp") == $opt) {
	    $entry .= $query->end_b;
	}
    }
    push @row, $entry;

    $aux->addtablerow(@row);

    return $aux->maketable($query, tablestyle => 'borderless', valign => 'middle');
}

sub makeentry {
    
    my $query = shift;
    my $table = shift;
    my $ltk = shift;
    my $pSEN = shift;
    my $pResults = shift;
    #############################
    my $p_urls = shift;
    my $p_regexps = shift;
    my $p_explanations = shift;
    #############################
    my $var = shift; 
    my $tmpfile = shift;
    my $tmpfilename1 = shift;
    my $tmpfilename2 = shift;
    
    (my $lit, my $key) = split(/\ -\ /, $ltk);
    my %bib = getbib($lit, $key);

    my $img_path = IMG_PATH;
    
    my $none = HTML_NONE;
    my $on = HTML_ON;
    my $leftcontent = "";
    
    if ($query->param("disp_title") eq $on) {
	$leftcontent =  $query->span({-style => "font-weight:bold;margin-left:0em"}, "Title: ") . 
	    highlighttext(generateweblinks($query, $bib{'title'}, 
					   ($query->param("disp_textlinks") eq $on), $p_urls, $p_regexps, $p_explanations), 
			  (DSP_HIGHLIGHT_COLOR)->{texthighlight}, $var, $query->param('casesensitive') || 0). $query->br;
	$leftcontent .=  $query->span({-style => "font-weight:bold;margin-left:0em"}, "Authors: ") .  $bib{'author'} . $query->br; 
	$leftcontent .=  $query->span({-style => "font-weight:bold;margin-left:0em"}, "Journal: ") .  $bib{'journal'} . $query->br; 
	$leftcontent .=  $query->span({-style => "font-weight:bold;margin-left:0em"}, "Year: ") .  $bib{'year'} . $query->br; 
	$leftcontent .=  $query->span({-style => "font-weight:bold;margin-left:0em"}, "Doc ID: ") . $key . $query->br;
    }
    $table->addtablerow($leftcontent);

    $leftcontent = "";
    
    my $bib_textid   = "bib" . $key;
    my $bib_imageid  = "i" . $bib_textid;
    $leftcontent .= $query->a({href => "javascript:ExpandCollapse('$bib_textid', '$img_path')", style => "color:white"},
			      $query->img({-id => "$bib_imageid", 
					   -src=>$img_path.'plus.png'})) .
					       $query->b(" Bibliographic Information ");
    
    my $aux = $bib{'type'};
    my $auxtxt = "";
    if ($aux =~ /(meeting|gazette)/i) {
	$auxtxt = " Unpublished information; cite only with author permission.";
    }
    my $wrnclr =(DSP_HIGHLIGHT_COLOR)->{warning};
    
    if ($auxtxt) {
	$leftcontent .=	$query->div({id => $bib_textid, style => "display:none"},
				    $query->div({style => "margin-left:1em"}),
				    $query->b(" Citation: "), $query->font($bib{'citation'}),
				    $query->br,
				    $query->b(" Type: ") , $query->font($bib{'type'}),
				    $query->br,
				    $query->span({-style => "font-weight:bold;color:$wrnclr;"}, $auxtxt),
				    $query->br,
				    $query->b(" Literature: "), $query->font($lit),
				    $query->br,
				    $query->b(" Accession (PMID): ") , $query->font($bib{'accession'}),
				    );
    } else {
	$leftcontent .=	$query->div({id => $bib_textid, style => "display:none"},
				    $query->div({style => "margin-left:1em"}),
				    $query->b(" Citation: "), $query->font($bib{'citation'}),
				    $query->br,
				    $query->b(" Type: ") , $query->font($bib{'type'}),
				    $query->br,
				    $query->b(" Literature: "), $query->font($lit),
				    $query->br,
				    $query->b(" Accession (PMID): ") , $query->font($bib{'accession'}),
				    );
    }

    $table->addtablerow($leftcontent);
    $leftcontent = "";
    my $abs_textid   = "abs" . $key;
    my $abs_imageid  = "i" . $abs_textid;
    $leftcontent .= $query->a({href => "javascript:ExpandCollapse('$abs_textid', '$img_path')", style => "color:white"},
			      $query->img({-id => "$abs_imageid", 
					   -src=>$img_path.'plus.png'})) .
					       $query->b(" Abstract ");
    $leftcontent .= $query->br;
    $leftcontent .=	$query->div({id => $abs_textid, style => "display:none"},
				    $query->div({style => "margin-left:1em"}),
				    highlighttext(generateweblinks($query, $bib{'abstract'}, 
								   ($query->param("disp_textlinks") eq $on), $p_urls, $p_regexps, $p_explanations),
						  (DSP_HIGHLIGHT_COLOR)->{texthighlight}, $var, $query->param('casesensitive') || 0));
    
    if ($leftcontent ne "") {
	$table->addtablerow($leftcontent);
    }
    $leftcontent = "";
    
    my $auxcontent = "";
    my $ms_textid   = "ms" . $key;
    my $ms_imageid  = "i" . $ms_textid;
    
    if ($query->param("disp_matches") ne $none) 
    {
	my $range = $query->param("disp_matches") - 1;
	
	if ($query->param("disp_expand-sentences") eq HTML_OFF) {
	    $leftcontent .= $query->a({href => "javascript:ExpandCollapse('$ms_textid', '$img_path')", style => "color:white"},
				      $query->img({-id => "$ms_imageid", 
						   -src=>$img_path.'plus.png'})).
						       $query->b(" Matching Sentences ");
	} else {
	    $leftcontent .= $query->a({href => "javascript:ExpandCollapse('$ms_textid', '$img_path')", style => "color:white"},
				      $query->img({-id => "$ms_imageid", 
						   -src=>$img_path . 'minus.png'})).
						       $query->b(" Matching Sentences ");
	}
		
	$table->addtablerow($leftcontent);
	$leftcontent .= $query->br;
	$leftcontent = "";
	
	my %subscore = ();
        my $maxsc = 0;
        my $minsc = 9999999;
        my $sum = 0.0;
	my $ct = 0;
	foreach my $ts (@$pSEN) {
	    (my $tgt, my $senstring) = split (/\#/, $ts);
	    my @sens = $senstring =~ /(\d+)\-/g;
	    my %aux = ();
	    foreach (@sens) {
		$aux{$_}++;
	    }
	    foreach (keys % aux) {
		my $sc = $aux{$_};
                $maxsc = ($sc > $maxsc) ? $sc : $maxsc;
                $minsc = ($sc < $minsc) ? $sc : $minsc;
                $sum += $sc;
                $ct++;
		push @{$subscore{$sc}{$tgt}}, $_;
	    }
	    
	}
        my $midpoint = int($sum/$ct) + 0.25;
        pipe (READER, WRITER);
        my $pid = fork();
        if (!defined($pid)) {
            print WRITER "Bummer, no resource available.";
        } elsif ($pid == 0) {
            # child
            close (READER);
            (my $subcontent, my $scrambled_sentences) = CollectMatchingSentences($query, \%subscore,
                                                                                 $lit, $key, $range, $on, $var,
										 $p_urls, $p_regexps, $p_explanations,
                                                                                 $minsc, $midpoint);
            print WRITER $subcontent, "\#mtpdel\#", $scrambled_sentences;
            close (WRITER);
            exit(0);
        } else {
            #parent
            close (WRITER);
            (my $subcontent, my $scrambled_sentences1) = CollectMatchingSentences($query, \%subscore,
                                                                                  $lit, $key, $range, $on, $var,
										  $p_urls, $p_regexps, $p_explanations,
                                                                                  $midpoint, $maxsc);
            $auxcontent .=  $subcontent;
            undef $/;
            my $line = <READER>;
            close (READER);
            $/ = "\n";
            ($subcontent, my $scrambled_sentences2) = split /\#mtpdel\#/, $line;
            $auxcontent .= $subcontent;
            $auxcontent .= $scrambled_sentences1 . $scrambled_sentences2;
            waitpid($pid, 0);
        }
    }
    
    if ($query->param("disp_expand-sentences") eq HTML_OFF)
    {
    	$leftcontent = $query->div({id => $ms_textid, style => "display:none"},
				   $query->div({style => "margin-left:1em"}),
				   $auxcontent);
    }
    else
    {
    	$leftcontent = $query->div({id => $ms_textid, style => "display:block"},
				   $query->div({style => "margin-left:1em"}),
				   $auxcontent);
    }
    
    if ($leftcontent ne "") {
	$table->addtablerow($leftcontent);
    }
    
    $leftcontent ="";
    if ($query->param("disp_supplementals") eq $on) {
	$leftcontent .= $query->span({-style => "font-weight:bold;font-size:85%"}, " Supplemental links/files: ");
	my $clr = (DSP_HIGHLIGHT_COLOR)->{7};
	$leftcontent .= $query->a({-href => "exportendnote?mode=singleentry&lit=$lit&id=$key"}, 
				  $query->span({-style => "background:$clr;text-decoration:none;font-size:85%"},"reference in endnote"));
	$leftcontent .= " ";
	$clr = (DSP_HIGHLIGHT_COLOR)->{1};
	$leftcontent .= $query->a({-href => "exportxml?mode=singleentry&tmpfile=$tmpfile&keywordfilename=$tmpfilename1&categoryfilename=$tmpfilename2&wbid=$key"}, 
				  $query->span({-style => "background:$clr;text-decoration:none;font-size:85%"},"reference in xml"));
	$leftcontent .= " ";
	
################################# ADD DOI LINK or SEARCH ########## Lisa M. 3/10 ##############################################################3
	my $link = $bib{'accession'};# gettext($lit, 'accession', $key);
	chomp($link);

	if ($link =~ m/^DOI/i) {
	    $link = substr($link, 4);
	    $link =~ s/\s//g;
	    my $clr = (DSP_HIGHLIGHT_COLOR)->{6};
	    $leftcontent .= $query->a({-href => "http://dx.doi.org/$link",
			    -target => "_blank"},
			    $query->span({-style => "background:$clr;text-decoration:none;"}, "full text via DOI lookup"));
	    $leftcontent .= " ";
	}
	if ($link =~ m/^AB/i) {
		$link = substr($link, 3);
		$link =~ s/\s//g;
		my $clr = (DSP_HIGHLIGHT_COLOR)->{2};
		$leftcontent .= $query->a({-href => "http://www.liebertonline.com/action/doSearch?nh=20&categoryId=1005&searchText=$link",
							-target => "_blank"},
			  $query->span({-style => "background:$clr;text-decoration:none;"}, "full text via Astrobiology journal online"));
		$leftcontent .= " ";
	}
	if ($link =~ m/^GS/i) {
		$link = substr($link, 3);
		$link =~ s/\s//g;
		my $clr = (DSP_HIGHLIGHT_COLOR)->{3};
		$leftcontent .= $query->a({-href => "http://scholar.google.com/scholar?hl=en&q=$link",
										    -target => "_blank"},
		      $query->span({-style => "background:$clr;text-decoration:none;"}, "search Google Scholar for full text article"));
		$leftcontent .= " ";
	}
# 	my $pmid = $bib{'accession'};
# 	chomp ($pmid);
# 	$pmid =~ s/\s//g;
# 	if ($pmid =~ /pmid\s*(\d+)/i) {
# 	    $pmid = $1;
# 	}
# 	if ($pmid =~ /^\d+$/) {
# 	    my $clr = (DSP_HIGHLIGHT_COLOR)->{6};
# 	    $leftcontent .= $query->a({-href => "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=$pmid&retmode=ref&cmd=prlinks",
# 				       -target => "_blank"},
# 				      $query->span({-style => "background:$clr;text-decoration:none;font-size:85%"}, "online text"));
# 	    $leftcontent .= " ";
# 	    my $clr = (DSP_HIGHLIGHT_COLOR)->{2};
# 	    $leftcontent .= $query->a({-href => "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Display&db=pubmed&dopt=pubmed_pubmed&from_uid=$pmid",
# 				       -target => "_blank"},
# 				      $query->span({-style => "background:$clr;text-decoration:none;font-size:85%"}, "related articles"));
# 	}
# 	if ($key =~ /WBPaper/) {
# 	    $leftcontent .= " ";
# 	    my $clr = (DSP_HIGHLIGHT_COLOR)->{7};
# 	    $leftcontent .= $query->a({-href => "http://www.wormbase.org/db/misc/paper?name=$key;class=Paper", -target => "_blank"},
# 				      $query->span({-style => "background:$clr;text-decoration:none;font-size:85%"}, "Wormbase reference"));
# 	}
# 	if ($pmid =~ /^\d+$/) {
# 	    $leftcontent .= " ";
# 	    my $clr = (DSP_HIGHLIGHT_COLOR)->{1};
# 	    $leftcontent .= $query->a({-href => "http://www.ncbi.nlm.nih.gov/sites/entrez?db=pubmed&cmd=retrieve&dopt=AbstractPlus&list_uids=$pmid",
# 				       -target => "_blank"},
# 				      $query->span({-style => "background:$clr;text-decoration:none;font-size:85%"}, "Pubmed citation"));
# 	}
# 	# Special treatment for Caltech WormLab; make pdfs available
# 	if ($query->remote_host() =~ /(131\.215\.|\.caltech\.edu)/) {
# 	    my $fn = DB_ROOT . '/' . (DB_LITERATURE)->{$lit} . '/' . DB_TEXT . '/pdf/' . $key . '.pdf'; 
# 	    if (-e "$fn") {
# 		$leftcontent .= " ";
# 		my $clr = (DSP_HIGHLIGHT_COLOR)->{4};
# 		my $addr = HTML_ROOT . "/celegans/tdb/" . (DB_LITERATURE)->{$lit} . '/' . DB_TEXT . '/pdf/' . $key . '.pdf';
# 		$leftcontent .= $query->a({-href => $addr,
# 					   -target => "_blank"},
# 					  $query->span({-style => "background:$clr;text-decoration:none;font-size:85%"}, "pdf"));
# 	    }
# 	}
    }
    if ($leftcontent ne "") {
	$table->addtablerow($leftcontent);
    }
    
    return 1;
    
}

sub PrintStopwordWarning {

    my $query = shift;
    my $words = shift;
    my $warncolor = shift;

    print $query->span({-style => "color:$warncolor;"},
		       "One or more stopwords have been found: <i>$words</i>. ");	
    print $query->span({-style => "color:$warncolor;"},
		       "Search results may be inaccurate (because of automatic exclusion of stopwords).");	
    print $query->br;
}

sub PrintGlobalLinkTable {

    my $query = shift;
    my %urls = @_;
    my @clr = ();
    $clr[0] = (DSP_HIGHLIGHT_COLOR)->{7};
    $clr[1] = (DSP_HIGHLIGHT_COLOR)->{5};
    $clr[2] = (DSP_HIGHLIGHT_COLOR)->{1};
    $clr[3] = (DSP_HIGHLIGHT_COLOR)->{4};
    $clr[4] = (DSP_HIGHLIGHT_COLOR)->{2};
    $clr[5] = (DSP_HIGHLIGHT_COLOR)->{3};
    $clr[6] = (DSP_HIGHLIGHT_COLOR)->{6};
    
    my @rows = ();
    my $color = 0;
    foreach my $txt (sort keys % urls) {
	push @rows, $query->a({-href => $urls{$txt}, -target => "_blank"}, 
			      $query->span({-style => "background:$clr[$color];text-decoration:none"},$txt));
	$color++;
    }
    my $glblnktbl = new TextpressoTable;
    $glblnktbl->init;
    $glblnktbl->addtablerow();
    $glblnktbl->addtablerow($query->span({-style => "font-weight:bold;"}, "Global links/files:"),
			    @rows);

    return $glblnktbl->maketable($query, tablestyle => 'borderless', valign => 'middle');
}

sub getbib {

    my $lit = shift;
    my $docid = shift;
    my %bib = ();
    my $fn = DB_ROOT . '/' . (DB_LITERATURE)->{$lit} . '/' .
	DB_TEXT . '/' . (DB_DISPLAY_FIELDS)->{'bib'} . '/' . $docid;
    my @lines = GetLines($fn);
    my $sep = DB_BIB_SEPARATOR;
    foreach my $line (@lines) {
	(my $field, my $entry) = split /$sep/, $line;
	$bib{$field} .= $entry;
    }
    foreach my $k (keys % bib) {
	my $e = $bib{$k};
	($bib{$k} = InverseReplaceSpecChar($e)) =~ s/\\//g;
    }

    return %bib;
}

sub gettext {

    my $literature = shift;
    my $field = shift;
    my $docid = shift;
    my $lineseparated = shift;

    my $fn = DB_ROOT . '/' . (DB_LITERATURE)->{$literature} . '/' .
	DB_TEXT . '/' . (DB_DISPLAY_FIELDS)->{$field} . '/' . $docid;

    return ($lineseparated) ? GetLines($fn) : join ("", GetLines($fn));
}

sub getsentences {

    my $literature = shift;
    my $target = shift;
    my $docid = shift;

    my $fn = DB_ROOT . '/' . (DB_LITERATURE)->{$literature} . '/' .
	DB_TEXT . '/' . (DB_SEARCH_TARGETS)->{$target} . '/' . $docid;

    return GetLines($fn);
}

sub preparesortresults {
    
    my $pLTK = shift;
    my $sortcriterion = shift;

    my %scorelist = ();
    my %invlist = ();
    
    if ($sortcriterion =~ /(score|hits)/i) {
	foreach my $ltk (keys % { $pLTK }) {
	    my $score = 0;
	    foreach my $clstr (@{ $$pLTK{$ltk} }) {
		(my $tgt, my $sens) = split (/\#/, $clstr); 
		$score += noss($sens);
	    }
	    $scorelist{$ltk} = $score;
	}
    } else {
	my %lits = ();
	foreach my $ltk (keys % { $pLTK }) {
	    (my $lit, my $key) = split(/\ \-\ /, $ltk);
	    $lits{$lit} = 1;
	}
	my %sorts = ();
	foreach my $lit (keys % lits) {
	    my @aux = gettext($lit, $sortcriterion, ".sort", 1);
	    for (my $i = 0; $i < @aux; $i++) {
		$sorts{$lit}{$aux[$i]} = $i;
	    }
	}
	foreach my $ltk (keys % { $pLTK }) {
	    (my $lit, my $key) = split(/\ \-\ /, $ltk);
	    if ($sortcriterion =~ /year/i) {
		$scorelist{$ltk} = (defined($sorts{$lit}{$key})) ? -$sorts{$lit}{$key} : -99999999;
	    } else {
		$scorelist{$ltk} = (defined($sorts{$lit}{$key})) ? $sorts{$lit}{$key} : -99999999;
	    }
	}
    }
    foreach my $ltk (keys % scorelist) {
	push @{$invlist{$scorelist{$ltk}}}, $ltk;
    }
    
    return %invlist;
}

sub highlighttext {

    my $text = shift;
    my $color = shift;
    my $var = shift;
    my $casesensitive = shift;
    
    my $ldel = (GE_DELIMITERS)->{annotation_entry_left};
    my $rdel = (GE_DELIMITERS)->{annotation_entry_right};
    

    my $leftsub = "\<span style=\'color:$color;\'\>";
    my $rightsub = "\<\/span\>";

    if ($casesensitive) { 
    	while ($text =~ s/($ldel)($var)($rdel)/$1$leftsub$3$rightsub$4/) {}; # One bracket inside $var
    } else {
    	while ($text =~ s/($ldel)($var)($rdel)/$1$leftsub$3$rightsub$4/i) {}; # One bracket inside $var
    }
		
    return $text;
}

sub makehighlightterms {

    my $tpquery = shift;
    my $mode = shift;
    my $lit = shift;
    my $tgt = shift;
    my $key = shift;
    my %ret = ();
    
# print "tpquery->{type}: ";
# print @{$tpquery->{type}};
#  print "<br />";
 
    if ($mode eq 'keyword') {
#       print "In keyword mode: ";
#       print "tpquery->{type}: ";
#       print @{$tpquery->{type}};
#       print "<br />";
	for (my $i = 0; $i < @{$tpquery->{type}}; $i++) {
	    if ($tpquery->type($i) eq 'keyword') {
		my @list = split (/\,/, $tpquery->data($i));
		foreach my $item (@list) {
		#  print 'ITEM: '.$item."\n";
		    $ret{($tpquery->exactmatch($i)) ? $item : $item . '[^\s\=]*?'} = 1;
		}
	    }
	}
    } elsif ($mode eq 'category') {
	#my $annfile = DB_ROOT . '/' . (DB_LITERATURE)->{$lit} . '/' .
	  #  DB_ANNOTATION . '/' . (DB_SEARCH_TARGETS)->{$tgt} . '/semantic/' . $key;
	    my $annfile = DB_ROOT. (DB_LITERATURE)->{$lit} .
	    DB_ANNOTATION . (DB_SEARCH_TARGETS)->{$tgt} . 'semantic/' . $key;
# 	    print 'FILE: '.$annfile."<br />";
	undef $/;
	open (IN, "<$annfile");
	my $aline = <IN>;
	close (IN);
	$/ = "\n";
	my $boa = (GE_DELIMITERS)->{start_annotation};
	my $eoa = (GE_DELIMITERS)->{end_annotation};
	my @splits = split (/$eoa/, $aline);
# 	print "In category mode";
# 	print "tpquery->{type}: ";
# 	print @{$tpquery->{type}};
# 	print "<br />";
	for (my $i = 0; $i < @{$tpquery->{type}}; $i++) {
# 	  print 'i = '.$i.'<br />';
	    if ($tpquery->type($i) eq 'category') {
# 	      print 'In query <br />';
		my @list = split (/\,/, $tpquery->data($i));
		foreach my $item (@list) {
		    foreach my $si (@splits) {
			if ($si =~ /\n$item /) {
			    (my $extract) = $si =~ /$boa\n(.+?)\n/;
			    $ret{$extract} = 1;
			}
		    }
		}
	    }
	}
    }

    return (keys % ret);
}

sub Filter {

    my $p_results = shift;
    my $p_filtered_results = shift;
    my $filter_string = shift;

    my @filter_p = (); # Positive
    my @filter_n = (); # Negative
    
    my @terms = split /([\[\]])/, $filter_string;
    
    for (my $i=0; $i < @terms; $i+=4)
    {	
	my $f_string = $terms[$i];
	my $search_field  = $terms[$i + 2];
	
	# Get the filters
	my @entries = split /([-+])/, $f_string;
	my $positive = 0; @filter_p = (); @filter_n = (); my $count_p = 0; my $count_n = 0;
	foreach my $entry (@entries)
	{
	    if ($entry eq "+")
	    {	$positive = 1;
		next;
	    } elsif ($entry eq "-")
	    {	$positive = 0;
		next;
	    }
	    
	    $entry =~ s/\"(.*)\"/$1/;
	    
	    if ($positive == 1 && $entry =~ /\w+/)
	    {	$filter_p[$count_p] = $entry;
		$count_p++;
	    } elsif ($positive == 0 && $entry =~ /\w+/)
	    {	$filter_n[$count_n] = $entry;
		$count_n++;
	    }
	}
	
	# Identify $search_field
	my $display_field_flag = 0;
	foreach my $db_display_field (keys % { (DB_DISPLAY_FIELDS) })
	{	if ($search_field eq $db_display_field)
		{	$display_field_flag = 1;
			last;
		    }
	    }
	
	if ($display_field_flag) {	
	    foreach my $lit (keys % { $p_results }) {	
		foreach my $f_n (@filter_n) {
		    my @words = ($f_n);
		    my %filterindex = PrepareFilterIndex($lit, $search_field, @words);
		    %$p_filtered_results = booleannot($p_filtered_results, \%filterindex, DB_SEARCH_RANGES->{'document'});
		}
		foreach my $f_p (@filter_p) {
		    my @words = ($f_p);
		    my %filterindex = PrepareFilterIndex($lit, $search_field, @words);
		    %$p_filtered_results = booleanand($p_filtered_results, \%filterindex, DB_SEARCH_RANGES->{'document'});
		}
	    }
	} elsif ($search_field eq "sentence") {
	    foreach my $lit (keys % { $p_results }) {
		foreach my $search_target ( @{(DB_SEARCH_TARGETS_DEFAULTS)} ) { # abstract, body, title	
		    foreach my $f_n (@filter_n) {
			# If $f_n is a phrase, then store individual words in @words
			my @words = ($f_n);
			if ($f_n =~ / /) {	
			    @words = split / /, $f_n;
			}
			my %filterindex = PrepareFilterIndex($lit, $search_target, @words);
			%$p_filtered_results = booleannot($p_filtered_results, \%filterindex, 'sentence');
		    }
		    foreach my $f_p (@filter_p) {
			# If $f_p is a phrase, then store individual words in @words
			my @words = ($f_p);
			if ($f_p =~ / /) {
			    @words = split / /, $f_p;
			}
			my %filterindex = PrepareFilterIndex($lit, $search_target, @words);
			%$p_filtered_results = booleanand($p_filtered_results, \%filterindex, 'sentence');			
		    }
		}
	    }
	}
    }

    return;
}

sub get_annotations_and_positions {

    my $literature = shift;
    my $target = shift;
    my $docid = shift;
    my $sen = shift;

    $sen = (GE_DELIMITERS)->{start_sentence_left} . $sen . (GE_DELIMITERS)->{start_sentence_right};
    my $boa = (GE_DELIMITERS)->{start_annotation};
    my $eoa = (GE_DELIMITERS)->{end_annotation};
    
    # get only the needed categories
    my %needed_categories;
    foreach (keys % {(DB_CATEGORIES)}) {
	$needed_categories{(DB_CATEGORIES)->{$_}} = 1;
    }
    
    my $fn = DB_ROOT .'/'.(DB_LITERATURE)->{$literature}.'/'.DB_ANNOTATION.'/'.(DB_SEARCH_TARGETS)->{$target}.'/semantic/'.$docid;
    my @text = ();

    open (IN, "<$fn");
    my $switch = 0;
    while (my $line = <IN>) {
	chomp($line);
	if ($switch) {
	    last if ($line eq (GE_DELIMITERS)->{end_sentence});
	    push @text, $line;
	}
	$switch = 1 if ($line eq $sen);
    }
    close (IN);
    
    my %markup_hash;
    while (@text)
    {
	my $line1 = shift @text;
	die ("Improper line assumptions about annotation files in exportxml.\n") if ($line1 ne $boa);
	my $word = shift @text;
	my $n = shift @text;
	my @markups;
	my $entry = shift @text;
	while ($entry ne $eoa)
	{
	    $entry =~ /^([\w_-]+) /;
	    my $markup = $1;
	    if (defined($needed_categories{$markup}))
	    {
		$markup_hash{$n}{$word}{$markup} = 1;
	    }
	    $entry = shift @text;
	}
    }

    return %markup_hash;
}

sub get_end_pos {

    my $actual_pos = shift;
    my $w = shift;
    
    my $delimiters = (GE_DELIMITERS)->{'word'};
    my @del = split //, $delimiters;
    my $splitter = "";
    for (my $i=0; $i < @del; $i++)
    {
	$splitter .= $del[$i];
    }
    my @e = split (/([$splitter])/, $w);	
    my $no_of_words = scalar @e;
    my $end_pos;
    if ($no_of_words > 1) {
	$end_pos = $actual_pos + int(($no_of_words -1)/2);
    } else {
	$end_pos = $actual_pos;
    }

    return $end_pos;
}

sub annotations_in_xml {
    my $s = "";
    $s .= "  <annotation>\n";
    foreach my $k (sort keys % {(DB_CATEGORIES)}) {
	my $x = (DB_CATEGORIES)->{$k};
	$x = entity_reference_xml($x);
	$k = entity_reference_xml($k);
	$s .= "   <category_label name=\"$x\">$k<\/category_label>\n";
    }
    $s .= "  <\/annotation>\n";

    return $s;
}

sub matching_sentences_in_xml {

    my $presults = shift;
    my $lit = shift;
    my $wbid = shift;
    my $keywordfilename = shift;
    my $categoryfilename = shift;
    
    my @keywords = ();
    open (IN, "<$keywordfilename");
    while (my $k = <IN>) {
	chomp $k;
	$k =~ s/\\S\*\?//;
	push @keywords, $k;
    }
    close IN;

    my @categories = ();
    open (IN, "<$categoryfilename");
    while (my $c = <IN>) {
	my @a = split /,/, $c;
	push @categories, @a;
    }
    close IN;

    my $string = "";
    $string .= "   <matching_sentences>\n";
    foreach my $field (sort keys % {$$presults{$lit}{$wbid}}) {
	$string .= "    <field_$field>\n";
	my $sentencestring = $$presults{$lit}{$wbid}{$field};
	while (1) {
	    my @sens = $sentencestring =~ /(\d+)\-/g;
	    my %senscore = ();
	    foreach my $s (@sens) {
		$senscore{$s}++;
	    }
	    my $max_sen = "";
	    my $max_score = 0;
	    foreach my $s (keys % senscore) {
		if ($senscore{$s} > $max_score) {
		    $max_sen = $s;
		    $max_score = $senscore{$s};
		}
	    }
	    
	    last if ($max_score == 0);
	    my @sentences = getsentences($lit, $field, $wbid);
	    my $s = $sentences[$max_sen - 1];
	    $s = entity_reference_xml($s);
	    my $aux = "\n     <sentence id=\"$max_sen\" subscore=\"$max_score\">\n";
	    (my $s1 = InverseReplaceSpecChar($s)) =~ s/\\//g;
	    $aux .= "      <content>$s1</content>\n";
	    my %annotations = get_annotations_and_positions($lit, $field, $wbid, $max_sen);
	    
	    my @sorted_pos = sort { $a <=> $b } (keys %annotations);
	    foreach my $pos (@sorted_pos) {
		foreach my $w (sort keys % {$annotations{$pos}}) {
		    my $actual_pos = $pos+1;
		    # find end position
		    my $end_pos = get_end_pos($actual_pos, $w);
		    
		    my $iskeyword = 0;
		    foreach my $k (@keywords) {
			$iskeyword = 1 if ($w =~ /$k/);
		    }
		    foreach my $m (sort keys % {$annotations{$pos}{$w}}) {
			my $iscat = 0;
			foreach my $c (@categories) {
			    $iscat = 1 if ($m =~ /$c/);
			}
			my $bom = "      <$m start_pos=\"$actual_pos\" end_pos=\"$end_pos\"";
			if ($iskeyword == 1) {
			    $bom .= " matched_entity=\"keyword\">";
			} elsif ($iscat == 1) {
			    $bom .= " matched_entity=\"category\">";
			} else {
			    $bom .= '>';
			}
			my $eom = "</$m>\n";
			$w = entity_reference_xml($w);
			my $repl = $bom . $w . $eom;
			$aux .= $repl;
		    }
		}
	    }
	    $string .= "$aux" . "     </sentence>\n";
	    $sentencestring =~ s/$max_sen-\d+//g;
	}
	$string .= "    <\/field_$field>\n";
    }
    $string .= "   <\/matching_sentences>\n";

    return $string;    
}

sub single_biblio_entry_in_xml {

    my $lit = shift; # C. elegans
    my $id = shift; # WBPaperX
    
    my %bib = getbib($lit, $id);
    my $entry = "   <bibliography>\n";
    $entry .= "    <literature>";
    $entry .= entity_reference_xml($lit);
    $entry .= "<\/literature>\n";
    $entry .= "    <doc_id>";
    $entry .= entity_reference_xml($id);
    $entry .= "<\/doc_id>\n";
    
    foreach my $enfield (reverse sort keys % {(DB_DISPLAY_FIELDS)}) {
	my $aux = '';
	if ($enfield eq 'accession') {
	    $aux .= "    <$enfield>"; 
	    $aux .= entity_reference_xml($bib{$enfield});
	    $aux .= "<\/$enfield>\n";
	} elsif ($enfield ne 'bib') {
	    my $x = entity_reference_xml($bib{$enfield});
	    $x =~ s/\n//g;
	    if ($enfield eq 'citation') {
		my $v = '';
		my $p = '';
		if ($x =~/V : (.+?) P : (.+)/) {
		    $v = $1;
		    $p = $2;
		}
		$aux .= "    <volume>";
		$aux .= entity_reference_xml($v);
		$aux .= "</volume>\n";
		$aux .= "    <page>";
		$p =~ s/ /-/;
		$aux .= entity_reference_xml($p);
		$aux .= "</page>\n";
	    } elsif ($enfield eq 'author') {
		while ($x =~ /([\w\-]+) ([\w\-]+)/g) {
		    $aux .= "    <$enfield>"; 
		    $aux .= entity_reference_xml($1) . entity_reference_xml($2);
		    $aux .= "<\/$enfield>\n";
		}
	    } else {
		$aux .= "    <$enfield>"; 
		$aux .= entity_reference_xml($x);
		$aux .= "<\/$enfield>\n";
	    }
	}
	$entry .= $aux;
    }
    $entry .= "   <\/bibliography>\n";

    return $entry;
}

sub entity_reference_xml {
    
    my $string = shift;
    
    $string =~ s/\&/\&amp\;/g;
    $string =~ s/</\&lt\;/g;
    $string =~ s/>/\&gt\;/g;
    $string =~ s/\"/\&quot\;/g;
    $string =~ s/\'/\&apos\;/g;

    return $string;
}

sub getwebpage{

    my $u = shift;
    my $page = "";
	use LWP::UserAgent;
	
    my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
    
    $page = $response->content;    #splits by line

    return $page;
}

sub CreateAdditionalTopInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Search for keywords or categories or both");
    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#ffffff',
			   width => '700');
}

####added by RF, 101508, for retrieving the searchsynonyms 
####status to display synonyms list when the searchsynonyms 
####is on when the search button is clicked.  Once the search 
####button is clicked, the searchsynonyms is unclicked, which 
####caused confusion when the user want to do a non synonyms 
####search at this point
sub getSearchSynonymsStatus {

    my $checksearchfilename = shift;
     my @checksearchsynonyms;
    open(IN, "<$checksearchfilename");
    @checksearchsynonyms = <IN>;
    close(IN);
    my $lastSynonymsSearch = pop(@checksearchsynonyms);
    chomp($lastSynonymsSearch);

    return $lastSynonymsSearch;
}
####end added by RF

sub CreateKeywordInterface {

    my $query = shift;
    ####added by RF, 0926, for synonyms search
    my $SearchKeywordsSyn = shift; ##added by RF, 07/10/08, for displaying 
                                   ##keyword, synonyms in 'searchstring' 
                                   ##textfield
    my $searchsynonyms = $query->param('searchsynonyms');  ##added by RF, 
                                                           ##07/11/08, 
                                                           ##for synonym search
    my $search = $query->param('search');
    ####added by RF, 07/11/08, for replacing the 
    ####original search string of the textfield, 
    ####'searchstring' with keywords & synonyms list
    if($search){
	if($SearchKeywordsSyn && $searchsynonyms eq 'on'){
	    $query -> param(-name=>'searchstring', -value=>$SearchKeywordsSyn);
	    $query -> param(-name=>'searchsynonyms', -value=>'off');  
	}
    }
    
    ####end added by RF
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Keywords " . $query->a({href => "javascript:explainKeywords()", style => "color:#4d4d4d"}, 
					      $query->img({-src=>QUESTION_MARK_IMAGE, -width=>"13", -height=>"13"})));
    $aux->addtablerow($query->textfield(-name => 'searchstring', -size => 50, -maxlength => 255));
    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small',
			   width => '700');
}

sub CreateKeywordSpecInterface {

    my $query = shift;
    my $keywordspec = $query->font("&nbsp;");

    ####modified by RF, 0926, for synonyms search
    $keywordspec .= $query->checkbox(-name => 'exactmatch', -checked=>'checked', 
				     -id => 'exactmatchID', -style => 'font-style:normal;', -label => 'Exact match')
	. $query->font("&nbsp;")
	. $query->checkbox(-name => 'casesensitive', -label => 'Case sensitive')
	. $query->font("&nbsp;") ##added by RF  07/02/08
    ####added by RF, 07/22/08, if the searchsynonym is checked, check the exactmatch checkbox.
        . $query->checkbox(-name => 'searchsynonyms', -checked => 'checked', 
			   -label => 'Search synonyms', -onClick=>"javascript:checkExactMatch(this, 'exactmatchID')")
	. "  " . $query->a({href => "javascript:explainSynonyms()", style => "color:#4d4d4d"}, 
			   $query->img({-src=>QUESTION_MARK_IMAGE, -width=>"13", -height=>"13"}));  ##added by RF  07/02/08
    ####end modified by RF

    return $keywordspec;
}

sub CreateMoreOptionsInterface {

    my $query = shift;
    my $error_searchmode = shift;
    
    my $opt ='search-options';
    my $on = HTML_ON; 
    my $off = HTML_OFF;
    my $oncolor = (DSP_HIGHLIGHT_COLOR)->{oncolor};
    my $offcolor = (DSP_HIGHLIGHT_COLOR)->{offcolor};

    if (!defined($query->param("disp_$opt"))) {
		$query->param(-name => "disp_$opt", -value => $off);
    }

    my $selfurl = $query->self_url;
    (my $actualurl = $selfurl) =~ s/disp_$opt=$off//g;
    $actualurl =~ s/disp_$opt=$on//g; 

    my $entry = $query->b($query->span({-style => "color:#5870a3;"},
				       "Advanced Search Options : "));
    if ($query->param("disp_$opt") eq $on) {
	$entry .= $query->start_b;
	$entry .= $query->a({-href => "$actualurl\;disp_$opt=$on"}, $query->span({-style=>"font-size:100%;color:$oncolor"}, $on));
	$entry .= $query->end_b;
	$entry .= $query->span({-style=>"font-size:100%;"}, " | ");
	$entry .= $query->a({-href => "$actualurl\;disp_$opt=$off"}, $query->span({-style=>"font-size:100%;color:#0000ff"}, $off));
    } else {
	$entry .= $query->a({-href => "$actualurl\;disp_$opt=$on"}, $query->span({-style=>"font-size:100%;color:#0000ff"}, $on));
	$entry .= $query->span({-style=>"font-size:100%;"}, " | ");
	$entry .= $query->start_b;
	$entry .= $query->a({-href => "$actualurl\;disp_$opt=$off"}, $query->span({-style=>"font-size:100%;color:$offcolor"}, $off));
	$entry .= $query->end_b;
    }
    if ($query->param("disp_$opt") eq $off) {
	$entry .= $query->span({-style => "color:#5870a3;font-size:85%;"},
			       " [" .
			       "location (abstract, full text), " .
			       "sorting  (year, score,..), " .
			       "filtering (author, journal,..)]");
    }
    my $dispstyle = ($query->param("disp_$opt") eq $on) ? "block" : "none";
    $entry .= $query->div({-style => "display:$dispstyle"},
			  $query->div({style => "margin-left:1em"}),
			  CreateTargetInterface($query),
			  CreateSearchScopeInterface($query) .
			  CreateSortByInterface($query) .
			  CreateExclusionInterface($query).
			  CreateSearchModeInterface($query, $error_searchmode).
			  OptionalFilterInterface($query));
    
    return $entry;
}

sub CreateCategoryInterface {
    
    my $query = shift;

    my %allCats = ();
    for my $cat (sort keys %{(DB_CATEGORIES)} ) {
	$allCats{$cat} = 1;
    }
    my %parentChildren;
    for my $parent (sort keys %{(DB_CATEGORYCHILDREN)} ) {
	my @children = @{(DB_CATEGORYCHILDREN)->{$parent}};
	my $masterChild = "any " . $parent;
	unshift(@children, $masterChild);
	foreach (@children) {
	    $parentChildren{$parent}{$_} = 1;
	}
	shift(@children);
	foreach (@children) {
	    delete $allCats{$_};
	}
    }
    my $masterString = '';
    for my $masterCat (sort keys %allCats) {
	$masterString .= $masterCat . ',';
	if (keys %{$parentChildren{$masterCat}}) {
	    foreach (sort keys %{$parentChildren{$masterCat}}) {
		$masterString .= $_ . ';';
	    }
	}
	$masterString .= ':';
    }
    
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Categories " . $query->a({href => "javascript:explainCat()", style => "color:#4d4d4d"}, 
						$query->img({-src=>QUESTION_MARK_IMAGE, -width=>"13", -height=>"13"})));
    use TextpressoDatabaseCategories;
    my $miniT = new TextpressoTable;
    $miniT->init;
    $miniT->addtablerow();
    
    my %allCats = ();
    for my $cat (sort keys %{(DB_CATEGORIES)} ) {
	$allCats{$cat} = 1;
    }
    my %parentChildren;
    for my $parent (sort keys %{(DB_CATEGORYCHILDREN)} ) {
	my @children = @{(DB_CATEGORYCHILDREN)->{$parent}};
	my $masterChild = "any " . $parent;
	unshift(@children, $masterChild);
	foreach (@children) {
	    $parentChildren{$parent}{$_} = 1;
	}
	shift(@children);
	foreach (@children) {
	    delete $allCats{$_};
	}
    }
    my $masterString = '';
    for my $masterCat (sort keys %allCats) {
	$masterString .= $masterCat . ',';
	if (keys %{$parentChildren{$masterCat}}) {
	    foreach (sort keys %{$parentChildren{$masterCat}}) {
		$masterString .= $_ . ';';
	    }
	}
	$masterString .= ':';
    }
    $miniT->addtablerow($query->button({-onMouseOver => "javascript:popOver(0, 1)", 
					-onMouseOut => "javascript:popOut(0, 1)",
					-value=>"List >"}) );
    my $none = HTML_NONE;
    my $none1 = "Select category 1 from list above";
    my $none2 = "Select category 2 from list above";
    my $none3 = "Select category 3 from list above";
    my $none4 = "Select category 4 from list above";
    my $none5 = "Select category 5 from list above";
    $miniT->addtablerow($query->textfield({-name => 'cat1', -default => $none1, -id => 'cat1', -size => "35"}) . ' ' . 
			$query->button({-onClick=>"javascript:resetCat(1)", -value=>"Reset"}) );
    $miniT->addtablerow($query->textfield({-name => 'cat2', -default => $none2, -id => 'cat2', -size => "35"}) . ' ' . 
			$query->button({-onClick=>"javascript:resetCat(2)", -value=>"Reset"}) );
    $miniT->addtablerow($query->textfield({-name => 'cat3', -default => $none3, -id => 'cat3', -size => "35"}) . ' ' . 
			$query->button({-onClick=>"javascript:resetCat(3)", -value=>"Reset"}) );
    $miniT->addtablerow($query->textfield({-name => 'cat4', -default => $none4, -id => 'cat4', -size => "35"}) . ' ' . 
			$query->button({-onClick=>"javascript:resetCat(4)", -value=>"Reset"}) );
    $miniT->addtablerow($query->textfield({-name => 'cat5', -default => $none5, -id => 'cat5', -size => "35"}) . ' ' . 
			$query->button({-onClick=>"javascript:resetCat(5)", -value=>"Reset"}) );
    
    $aux->addtablerow($miniT->maketable($query, tablestyle => 'borderless', valign => 'middle'));

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small',
			   width => '700');
}

sub CreateFilterInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Narrow your search results with filter: " 
		      . $query->a({href => "javascript:explainFilter()", style => "color:#4d4d4d"}, 
				  $query->img({-src=>QUESTION_MARK_IMAGE, -width=>"13", -height=>"13"})));
    $aux->addtablerow($query->textfield(-name => 'filterstring', -size => 50, -maxlength => 255) . " " .
		      $query->submit(-name => 'filter', -value => 'Filter!'));

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small',
			   width => '700');
}

sub FilterMO {	

    my $p_results = shift;
    my $p_filtered_results = shift;
    my $authorfilter = shift;
    my $journalfilter = shift;
    my $yearfilter = shift;
    my $mtabstracts = shift;
    my $fuabstracts = shift;
    my $supplementals = shift;
    my $filter_string = shift;
    
    $filter_string .= " -MEETING_ABSTRACT-GAZETTE_ABSTRACT[type]" if ($mtabstracts eq 'on');
    $filter_string .= " -EDITORIAL-BOOK_CHAPTER-MONOGRAM-COMMENT-COMMUNICATION-OTHER-CORRECTION-ADDENDUM-ERRATUM-NEWS-REVIEW-ARTICLE-LETTER-NOTE-WORMBOOK[type]" if ($fuabstracts eq 'on');
    $filter_string .= " -SUPPLEMENTAL[type]" if ($supplementals eq 'on');

    if (defined($authorfilter)) {
	my @authors = split /\,/, $authorfilter;
	foreach (@authors) {
	    $filter_string .= " +" . $_ ."[author]";
	}
    }
    if (defined($journalfilter)) {
	my @journals = split /\,/, $journalfilter;
	foreach (@journals) {
	    $filter_string .= " +" . $_ ."[journal]";
	}
    }
    if (defined($yearfilter)) {
	my @years = split /\,/, $yearfilter;
	foreach (@years) {
	    $filter_string .= " +" . $_ ."[year]";
	}
    }
    
    my @filter_p = (); # Positive
    my @filter_n = (); # Negative
    
    my @terms = split /([\[\]])/, $filter_string;
    
    for (my $i=0; $i < @terms; $i+=4)
    {	
	my $f_string = $terms[$i];
	my $search_field  = $terms[$i + 2];
	
        # Get the filters
	my @entries = split /([-+])/, $f_string;
	my $positive = 0; @filter_p = (); @filter_n = (); my $count_p = 0; my $count_n = 0;
	foreach my $entry (@entries)
	{
	    if ($entry eq "+")
	    {	$positive = 1;
		next;
	    } elsif ($entry eq "-")
	    {	$positive = 0;
		next;
	    }
	    
	    $entry =~ s/\"(.*)\"/$1/;
	    
	    if ($positive == 1 && $entry =~ /\w+/)
	    {	$filter_p[$count_p] = $entry;
		$count_p++;
	    } elsif ($positive == 0 && $entry =~ /\w+/)
	    {	$filter_n[$count_n] = $entry;
		$count_n++;
	    }
	}
	
	# Identify $search_field
	my $display_field_flag = 0;
	foreach my $db_display_field (keys % { (DB_DISPLAY_FIELDS) }) {
	    if ($search_field eq $db_display_field) {
		$display_field_flag = 1;
		last;
	    }
	}
	if ($display_field_flag) {	
	    foreach my $lit (keys % { $p_results }) {
		foreach my $f_n (@filter_n) {
		    my @words = ($f_n);
		    my %filterindex = PrepareFilterIndex($lit, $search_field, @words);
		    %$p_filtered_results = booleannot($p_filtered_results, \%filterindex, DB_SEARCH_RANGES->{'document'});
		} 
		foreach my $f_p (@filter_p) {
		    my @words = ($f_p);
		    my %filterindex = PrepareFilterIndex($lit, $search_field, @words);
		    %$p_filtered_results = booleanand($p_filtered_results, \%filterindex, DB_SEARCH_RANGES->{'document'});
		}
	    }
	} elsif ($search_field eq "sentence") {
	    foreach my $lit (keys % { $p_results }) {	
		foreach my $search_target ( @{(DB_SEARCH_TARGETS_DEFAULTS)} ) { # abstract, body, title
		    foreach my $f_n (@filter_n) {
			# If $f_n is a phrase, then store individual words in @words
			my @words = ($f_n);
			if ($f_n =~ / /) {
			    @words = split / /, $f_n;
			}
			my %filterindex = PrepareFilterIndex($lit, $search_target, @words);
			%$p_filtered_results = booleannot($p_filtered_results, \%filterindex, DB_SEARCH_RANGES->{'sentence'});
		    }		    
		    foreach my $f_p (@filter_p) {
			# If $f_p is a phrase, then store individual words in @words
			my @words = ($f_p);
			if ($f_p =~ / /) {	
			    @words = split / /, $f_p;
			}
			my %filterindex = PrepareFilterIndex($lit, $search_target, @words);
			%$p_filtered_results = booleanand($p_filtered_results, \%filterindex, DB_SEARCH_RANGES->{'sentence'});	
		    }
		}
	    }
	}
    }

    return $filter_string;
}

sub CreateExclusionInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Article Exclusions");
    if (defined($query->cookie("cookie-exclude-mtabstracts"))) {
	$aux->addtablerow($query->i($query->checkbox(-name => 'mtabstracts',
						     -value => ($query->cookie("cookie-exclude-mtabstracts")) ? 'on' : 'off',
						     -checked => ($query->cookie("cookie-exclude-mtabstracts") == 1) ? 1 : 0,
						     -label => 'exclude worm meeting and WBG abstracts'))); 
    } else {
	$aux->addtablerow($query->i($query->checkbox(-name => 'mtabstracts',
						     -label => 'exclude worm meeting and WBG abstracts'))); 
    }
    if (defined($query->cookie("cookie-exclude-fuabstracts"))) {
	$aux->addtablerow($query->i($query->checkbox(-name => 'fuabstracts',
						     -value => ($query->cookie("cookie-exclude-fuabstracts")) ? 'on' : 'off',
						     -checked => ($query->cookie("cookie-exclude-fuabstracts") == 1) ? 1 : 0,
						     -label => 'exclude published paper abstracts')));
    } else {
	$aux->addtablerow($query->i($query->checkbox(-name => 'fuabstracts',
						     -label => 'exclude published paper abstracts'))); 
    }
    if (defined($query->cookie("cookie-exclude-supplementals"))) {
	$aux->addtablerow($query->i($query->checkbox(-name => 'supplementals',
						     -value => ($query->cookie("cookie-exclude-supplementals")) ? 'on' : 'off',
						     -checked => ($query->cookie("cookie-exclude-supplementals") == 1) ? 1 : 0,
						     -label => 'exclude paper supplementals'))); 
    } else {
	$aux->addtablerow($query->i($query->checkbox(-name => 'supplementals',
						     -checked => 1,
						     -value => 'on',
						     -label => 'exclude paper supplementals'))); 
    }
    
    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#5870a3',
			   width => '50%');
}

sub OptionalFilterInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Optional Filters");
    $aux->addtablerow($query->font("&nbsp;") . $query->b("Author: ") . $query->textfield(-name => 'authorfilter', -size => 30, -maxlength => 255));
    $aux->addtablerow($query->b("Journal: ") . $query->textfield(-name => 'journalfilter', -size => 30, -maxlength => 255));
    $aux->addtablerow( $query->font("&nbsp;") . $query->font("&nbsp;") . $query->font("&nbsp;") . $query->font("&nbsp;") .
		       $query->b("Year: ") .
		       $query->textfield(-name => 'yearfilter', -size => 30, -maxlength => 255));
    $aux->addtablerow($query->font("&nbsp;") . $query->b("Doc ID: ") . $query->textfield(-name => 'docidfilter', -size => 30, -maxlength => 255));

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#5870a3',
			   width => '50%');    
}

sub PrintDatabaseInformation
{
    my $query = shift;
    my $m1 = new TextpressoTable;
    $m1->init;
    $m1->addtablerow("Database Description");
    my %count = ();
    foreach my $lit (keys % {(DB_LITERATURE)}) {
	my $fn = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_TEXT;
    	my @types = @{(DB_SEARCH_TARGETS_DEFAULTS)};
    	my @content = ();
    	foreach my $type (sort @types) {
	    opendir (DIR,"$fn/$type/");
	    my @fl = readdir (DIR);
	    closedir (DIR);
	    my $nu = @fl;
	    $nu -= 2;
	    $count{total} += $nu;
	    (my $nice = $type) =~ s/$fn\///; 
	    $count{$nice} += $nu;
	    push @content, "$nice ($nu)" if ($nu);
    	}
    }
    
    my @aux = ();
    my $n_abstract = $count{abstract};
    my $n_body = $count{body};
    foreach my $t (sort keys % count) {
    	push @aux, "$t : $count{$t}";
    }
    $m1->addtablerow("Current database contains <b>$n_body</b> full text papers and <b>$n_abstract</b> abstracts.");
    
    print $m1->maketable ($query,
			  tablestyle => 'borderless-headerbackground',
			  DSP_HDRSIZE => 'small',
			  width => '50%');

    return;
}

sub PrepareFilterIndex {

    my $lit = shift;
    my $search_target = shift;
    my @words = @_;

    my $stopwords = getstopwords(DB_STOPWORDS);
    my %filterindex = ();
    my $no_of_words = @words;
    for (my $w = 0; $w < $no_of_words; $w++) {
	if (! ($stopwords =~ /$words[$w]/i)) {
	    my @infilenames = ();
	    if (length($words[$w]) > 1) {
		$words[$w] =~ tr/A-Z/a-z/;
		$words[$w] =~ /(\w{2})/;
		(my $letter1, my $letter2) = split //, $1;
		# Make the filter case-insensitive
		my $small_letter = $letter1;
		$letter1 =~ tr/a-z/A-Z/;
		my $capital_letter = $letter1;
		
		# First letter small
		my $infiles_small = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
		    . "keyword/" . $small_letter . "/" . $letter2 . "/" . $words[$w]; 
		@infilenames = <$infiles_small*>;
		
		# First letter CAPS
		$words[$w] =~ s/^$small_letter/$capital_letter/;
		my $infiles_capital = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
		    . "keyword/" . $capital_letter . "/" . $letter2 . "/" . $words[$w]; 
		my @infilenames_c = <$infiles_capital*>;
		foreach (@infilenames_c) {
		    push @infilenames, $_;
		}
		
		# All CAPS
		my $caps_filter = $words[$w];
		$caps_filter =~ tr/a-z/A-Z/;
		$caps_filter =~ /(\w{2})/;
		($letter1, $letter2) = split //, $1;
		my $tmp = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
		    . "keyword/" . $letter1 . "/" . $letter2 . "/" . $caps_filter; 
		my @caps = <$tmp*>;
		foreach (@caps) {	
		    push @infilenames, $_;
		}
	    } else {
		# Make the sentence filter case-insensitive
		# First letter small
		my $l1 = $words[$w] =~ tr/A-Z/a-z/;
		my $tmp = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
		    . "keyword/" . $l1 . "/LITERAL";
		@infilenames = ($tmp);
		# First letter CAPS
		$l1 = $words[$w] =~ tr/a-z/A-Z/;
		$tmp = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
		    . "keyword/" . $l1 . "/LITERAL";
		push @infilenames, $tmp;
	    }
	    foreach my $in_file (@infilenames) {
		readindexfile($lit, $search_target, $in_file, \%filterindex, $w);
	    }
	}
    }
    if (%filterindex) {
	if ($no_of_words > 1) { # Check for adjacency of filter words
	    return booleanandnextneighbors(\%filterindex);
	} else {
	    return %{$filterindex{0}};
	} 
    } else {
	return ();
    }
}

sub noss { # number of sentences in string index

    my $a = shift;
    return  scalar(@{[$a =~ /(\-)/g]});
}

sub CollectMatchingSentences {
    
    my $query = shift;
    my $p_subscore = shift;
    my $lit = shift;
    my $key = shift;
    my $range = shift;
    my $on = shift;
    my $var = shift;
    my $p_urls = shift;
    my $p_regexps = shift;
    my $p_explanations = shift;
    my $minsc = shift;
    my $maxsc = shift;

    my %text = ();
    my %hide = ();
    my $subcontent = "";
    my $scrambled_sentences = "";
    
    foreach my $sc (sort descending keys % {$p_subscore}) {
	if (($sc >= $minsc) && ($maxsc >= $sc)) {
	    foreach my $tgt (sort keys % {$$p_subscore{$sc}}) {
		foreach my $sen (sort descending @{$$p_subscore{$sc}{$tgt}}) {
		    if (!defined($text{$tgt})) {
			@{$text{$tgt}} = getsentences($lit, $tgt, $key);
			############################################################################
			# Find sentences that are very long or look like tables and figures - arun.
			for (my $i=0; $i < @{$text{$tgt}}; $i++) {
			    $hide{$tgt}[$i] = 0;
			}
			
			for (my $i=0; $i < @{$text{$tgt}}; $i++) {
			    my @s = split /\s+/,$text{$tgt}[$i];
			    my $size_of_s = @s;
			        
			        # Very long sentence
			    if ($size_of_s >= 400) {
				$hide{$tgt}[$i] = 1;
			    }
			        
			        # Table or figure
			    if ($text{$tgt}[$i] =~ /\d+\s+\d+\s+\d+\s+\d+/ && ( ($text{$tgt}[$i] =~ /table/i) || ($text{$tgt}[$i] =~ /figure/i)) ) {
				$hide{$tgt}[$i] = 1;
			    }
			        
			        # Repeat patterns
			    if (($size_of_s < 400) && ($text{$tgt}[$i] ne "")) {
				foreach my $w (@s) {
				    if ($w =~ /\w+/) {
					my $rep = $w." ".$w." ".$w." ".$w;
					if ($text{$tgt}[$i] =~ /"\Q$rep\E"/i) {
					    $hide{$tgt}[$i] = 1;
					    last;
					}
				    }
				}
			    }
			}
			############################################################################
		    }
		        
		    my $actual = $sen - 1;
		    my $lower = ($actual - $range < 0) ? 0 : $actual - $range;
		    my $upper = ($actual + $range > scalar(@{$text{$tgt}})) ? scalar(@{$text{$tgt}}) : $actual + $range;
		    my $new_window = 0;
		    for (my $i = $lower; $i <= $upper; $i++) {
			$new_window = 1 if ($hide{$tgt}[$i] == 1);
		    }
		        
		    if ($new_window == 0) {
			if ($text{$tgt}[$lower] ne "") {
				my $tgt_display = $tgt;
				$tgt_display = "non-sectioned" if ($tgt eq "body");
			    $subcontent .= $query->span({-style => "font-weight:bold;"}, " SECTION: " . $tgt_display . ". ");
			    for (my $i = $lower; $i < $actual; $i++) {
				(my $tirs = InverseReplaceSpecChar($text{$tgt}[$i])) =~ s/\\//g;
				$subcontent .= highlighttext(generateweblinks($query, $tirs, 
									      ($query->param("disp_textlinks") eq $on),
									      $p_urls, $p_regexps, $p_explanations),
							     (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
							     $var, $query->param('casesensitive')|| 0);
			    }
			    my $emphasis = ($range > 0) ? "font-weight:bold;" : "font-weight:normal;";
			        
			    (my $tirs = InverseReplaceSpecChar($text{$tgt}[$actual])) =~ s/\\//g;
			    $subcontent .= $query->span({-style => $emphasis}, 
							highlighttext(generateweblinks($query, $tirs, 
										       ($query->param("disp_textlinks") eq $on),
										       $p_urls, $p_regexps, $p_explanations),
								      (DSP_HIGHLIGHT_COLOR)->{texthighlight},
								      $var, $query->param('casesensitive') || 0));
			    for (my $i = $actual + 1; $i <= $upper; $i++) {
				(my $tirs = InverseReplaceSpecChar($text{$tgt}[$i])) =~ s/\\//g;
				$subcontent .= highlighttext(generateweblinks($query, $tirs, ($query->param("disp_textlinks") eq $on),
									      $p_urls, $p_regexps, $p_explanations),
							     (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
							     $var, $query->param('casesensitive') || 0);
			    }
			    $subcontent .= $query->span({-style => "font-style:italic;"}, 
							" [Field: " . $tgt . ", subscore: " . sprintf("%4.2f", $sc) . "]");
			    $subcontent .= $query->br;
			}
		    } else {#puts weird tables, long files, etc into a file rat
			my $sen_file_name;
			do { $sen_file_name = tmpnam() } until (!-e DB_TMP . '/' . $sen_file_name);
			my $file_name = $sen_file_name;
			$sen_file_name = DB_TMP . '/' . $sen_file_name;
			open (OUT, ">$sen_file_name") || die ("Could not open $sen_file_name for writing.");
			my $highlighted_sen = "";
			$scrambled_sentences .= $query->span({-style => "font-weight:bold;"}, " Sen. " . $sen . ": ");
			for (my $i = $lower; $i < $actual; $i++) {
			    (my $tirs = InverseReplaceSpecChar($text{$tgt}[$i])) =~ s/\\//g;
#                            $highlighted_sen = highlighttext(generateweblinks($query, $tirs, 
#									      ($query->param("disp_textlinks") eq $on),
#			                                                      $p_urls, $p_regexps, $p_explanations),
#							     (DSP_HIGHLIGHT_COLOR)->{texthighlight},
#							     $var, $query->param('casesensitive') || 0);
#                            print OUT "$highlighted_sen\n";
			    print OUT "$tirs\n";
			}
			my $emphasis = ($range > 0) ? "font-weight:bold;" : "font-weight:normal;";
			(my $tirs = InverseReplaceSpecChar($text{$tgt}[$actual])) =~ s/\\//g;
#                        $highlighted_sen = $query->span({-style => $emphasis}, 
#							highlighttext(generateweblinks($query, $tirs, 
#										       ($query->param("disp_textlinks") eq $on),
#                                                                                      $p_urls, $p_regexps, $p_explanations), 
#								      (DSP_HIGHLIGHT_COLOR)->{texthighlight},
#								      $var, $query->param('casesensitive') || 0));
#                        print OUT "$highlighted_sen\n";
			print OUT "$tirs\n";
			for (my $i = $actual + 1; $i <= $upper; $i++) {
			    (my $tirs = InverseReplaceSpecChar($text{$tgt}[$i])) =~ s/\\//g;
#                            $highlighted_sen = highlighttext(generateweblinks($query, $tirs, ($query->param("disp_textlinks") eq $on),
#                                                                             $p_urls, $p_regexps, $p_explanations),
#                                                             (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
#                                                             $var, $query->param('casesensitive') || 0);
#                            print OUT "$highlighted_sen\n";
			    print OUT "$tirs\n";
			}
			close(OUT);
			$scrambled_sentences .= $query->a({-href => "showsentence?filename=$file_name", -target => '_blank',
							   -style => 'text-decoration:none'},
							  $query->font({-color => 'darkgreen'},
								       " [Sentence\(s\) appears to be scrambled. Click to see (opens new window)] "));
			$scrambled_sentences .= $query->span({-style => "font-style:italic;"}, 
							     " [Field: " . $tgt . ", subscore: " . sprintf("%4.2f", $sc) . "]");
			$scrambled_sentences .= $query->br . $query->div({style => "margin-bottom:8px"}, "");
		    }
		}
	    }
	}
    }
    return ($subcontent, $scrambled_sentences);
}

sub ascending { $a <=> $b }
sub descending { $b <=> $a }

1;
