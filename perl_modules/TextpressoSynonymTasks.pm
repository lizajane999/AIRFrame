package TextpressoSynonymTasks;

# Package for dealing with synonym functionality
#
# (c) 2008 Ruihua Fang, Caltech, Pasadena.
# Ruihua added the following functions in 10/10/2008:  
# getSearchStringInputSyn, storeSynHash, synonymsFromDB
# for dealing with synonyms search where the word in the
# search string is replace by a list of words consisting
# of the synonyms and the original word itself

use strict;
use TextpressoDatabaseGlobals;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(getSearchStringInputSyn storeSynHash synonymsFromDB getUniqArr);

####added by RF, 10/08/08, for synonyms search
sub getSearchStringInputSyn {

    my $searchStringInput = shift;
    my $words_ref = shift;
    my $exactmatch = shift;
    my $infile_syn = DB_SYNONYM_FILE; 
    ##DB_SYNONYM_FILE refers to synonymList file 
    ##path which is defined in TextpressoDatabaseGlobals.pm
    my %hash_synword;
    my $ref_synHash = storeSynHash($infile_syn);
    my $synonymsListNewFinal;
    my $synonymsListFinal;
    foreach(@$words_ref){
	(my $synonymsListNew, my $synonymsList) = synonymsFromDB($_,$ref_synHash,$exactmatch);
	$hash_synword{$_} = $synonymsListNew;
	$synonymsListNewFinal = $synonymsListNewFinal . ';' . $synonymsListNew;
	$synonymsListFinal = $synonymsListFinal . ';' . $synonymsList;
    }
    $synonymsListNewFinal = substr($synonymsListNewFinal, 1);
    $synonymsListFinal = substr($synonymsListFinal, 1);
    
    my $synSearchStringInput = $searchStringInput;
    for my $k (keys %hash_synword){
	my $synList = $hash_synword{$k};
	if ($k ne $synList) {
	    $synSearchStringInput =~ s/$k/\($synList\)/;
	}
    }
    
    return ($synSearchStringInput, $synonymsListFinal);
}

####added by RF, 10/08/08 for synonyms search
sub storeSynHash {

    my $infile_syn = shift;
    my @arrIn;
    my %synHash;
    open (IN, "<$infile_syn");
    @arrIn = <IN>;
    close (IN);
    
    foreach(@arrIn){
	chomp($_);
	my @lines = split(/,/, $_);
	foreach my $syn (@lines){
	    $synHash{$syn} = $_;
	}
    }
    
    return \%synHash;
}

####added by RF, 10/08/08 for synonyms search
sub synonymsFromDB {
    
    my $word = shift;
    my $ref_synHash = shift;
    my $exactmatch = shift;
    my $synonymsList;
    my @newSynonymArr;
    ##get synonymList from db, th esynonymList stored in DB is separated by ',';
    if($exactmatch){
	while ((my $key, my $value) = each(%$ref_synHash)){
	    if($word eq $key){
		$synonymsList = $value;
		####added by RF, 07/17/08 to rearrange the synList 
                ####so that the original word entered in the search 
		####field will be listed in the beginning 
                ##########################################################################
		
		my @row_syn = split(',', $synonymsList);
		my $deleteIndex;
		for (my $i=0; $i<@row_syn; $i++){
		    if($row_syn[$i] eq $word){
			$deleteIndex = $i;
		    }
			}
		splice(@row_syn, $deleteIndex, 1);
		unshift(@row_syn, $word);
		$synonymsList = join(',', @row_syn);
	    }
	}
        ##########################################################
	my @synonymArr = split(',', $synonymsList);
	foreach(@synonymArr){
	    if($_ eq $word){
		next;
	    }
	    else{
		push(@newSynonymArr, $_);
	    }
	}
	unshift(@newSynonymArr, $word);
        #########################################################
    }
    else{
	while ((my $key, my $value) = each(%$ref_synHash)){
	    my $matchWord = $word . '[A-Za-z0-9-_]*';
	    if($key =~ /$matchWord/){
		my $temp = $value;
		####added by RF, 07/17/08 to rearrange the synList 
                ####so that the original word entered in the search field will be listed in the beginning 
		if($temp =~ /($matchWord)/){
		    my $match = $1;
		    my $word_first = $match . ',';
		    my $word_re = ',' . $match;
		    
		    $temp =~ s/$word_re//;
		    $temp=~ s/$word_first//;
		    
		    my $word_re_f = substr($word_re, 0, 1);
		    if($word_re_f eq ','){
			$word_re = substr($word_re, 1);
		    }
		    $temp = $word_re . ',' . $temp;
		    
		}	
		$synonymsList = $synonymsList . ',' . $temp;
		####end of added by RF, 07/17/08
	    }
	}
	my $testFirst = substr($synonymsList, 0,1);
	if($testFirst eq ','){
	    $synonymsList = substr($synonymsList, 1);
	}
	
	my @synonymsListArr = split(',', $synonymsList);
	my $uniqSynonymsListArr_ref = getUniqArr(\@synonymsListArr);
	my @uniqSynonymsListArr = @$uniqSynonymsListArr_ref;
	$synonymsList = join(',', @uniqSynonymsListArr);
	
	my @synonymArr = split(',', $synonymsList);
	
	foreach(@synonymArr){
	    if(/^$word.*/){
		next;
	    }
	    else{
		push(@newSynonymArr, $_);
	    }
	}
	unshift(@newSynonymArr, $word);
    }
    my $synonymsListNew = join(',', @newSynonymArr);

    return ($synonymsListNew, $synonymsList);  ####added by RF, 07/17/08
}

sub getUniqArr {
    my $arrInput_ref = shift;
    my @uniqArr;
    my %seen = ();
    foreach my $item (@$arrInput_ref){
	push(@uniqArr, $item) unless $seen{$item}++;
    }

    return \@uniqArr;
}

####end added by RF

1;
