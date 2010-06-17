#!/usr/bin/perl

use strict;
use lib "/srv/www/airframe/perl_modules/";
# use lib "/usr/local/lib/textpresso/celegans/";
use TextpressoSystemGlobals;
use TextpressoSystemTasks;
use TextpressoGeneralTasks;
use TextpressoGeneralGlobals;
use File::stat;

my $USAGE = <<END_USAGE;

    $0 <command (optional)>

    current available commands: categories-only

    (c) Hans-Michael Muller, Pasadena, 2005-8
    Script process all incoming files that are not marked to be excluded.

END_USAGE

print "$USAGE\n";

# global command

my $command = $ARGV[0];

# if timestamp of (i)ncoming is newer than the
# timestamp of the (c)urrent one, and it's not
# (e)xcluded, do the following:
#
# 1) eliminate from index the content of current file
# 2) eliminate from annotation the content of current file,
#    if field is annotated
# 3) copy incoming file to current file and tokenize it
# 4) annotate incoming file if field is annotated
# 5) index tokenized incoming file
# 6) summarize all bib. fields into one file
#
# The order of processing is important. Annotations have
# to be indexed too, so indexing is done last.
# Supplementals are updated separately

###############################################################################################

# Read in the lexicon. Lexicon is like lexicon{phrase}{category} -> attributes
my $lexdir = SY_ROOT . (SY_SUBROOTS)->{ontology} . (SY_ONTOLOGY)->{lexica};
print "Loading lexicon...\n";
my %lexicon = ReadLexica($lexdir, (GE_DELIMITERS)->{lexicon});
my $size_of_lexicon = keys (%lexicon);
print "Loaded. Lexicon size = $size_of_lexicon.\n\n";

# Time-stamp entries
my @timeBfrProcessing = ();
my @timeAfterProcessing = ();
my $totalProcessingTime = 0.0;
my $no_of_papers = 0;

foreach my $pfield (keys % {(SY_PASSTHROUGH_FIELDS)}, keys % {(SY_ANNOTATION_FIELDS)}) {
    print "pfield = $pfield\n";
    my $incoming = SY_ROOT . (SY_SUBROOTS)->{includes} . (SY_SOURCE_FIELDS)->{$pfield};
    my $excluding = SY_ROOT . (SY_SUBROOTS)->{excludes} . (SY_SOURCE_FIELDS)->{$pfield};
    my $fld = (SY_PASSTHROUGH_FIELDS)->{$pfield} || (SY_ANNOTATION_FIELDS)->{$pfield};
    my $current = SY_ROOT . (SY_SUBROOTS)->{processedfiles} . $fld;
    
    my @incfiles = <$incoming*>;
  
    foreach my $ifile (@incfiles) {
	(my $efile = $ifile) =~ s/$incoming/$excluding/;
	if (!-e $efile) {
	    my $ist = stat($ifile);
	    my $imtime = $ist->mtime;
	    (my $cfile = $ifile) =~ s/$incoming/$current/;
	    my $cmtime = 0;
	    if (-e $cfile) {
		my $cst = stat($cfile);
		$cmtime = $cst->mtime;
	    }
	    if ($imtime > $cmtime) {
		@timeBfrProcessing = localtime();
		if (defined((SY_INDEX_FIELDS)->{$pfield})) {
		    print "\nStarting work at ", scalar localtime, ".\n";
		    foreach my $itype (keys % {(SY_INDEX_TYPE)}) {
			# 1) eliminate from index the content of current file
			my $outfield = SY_ROOT . (SY_SUBROOTS)->{indices};
			$outfield .= (SY_INDEX_FIELDS)->{$pfield};
			my $sourcefile;
			if (($itype eq 'keyword') && ($command ne 'categories-only')) {
			    $sourcefile = $cfile;
			} elsif (($itype eq 'semantic') || ($itype eq 'grammatical')) {
			    my $aux = SY_ROOT . (SY_SUBROOTS)->{annotations};
			    $aux .= (SY_ANNOTATION_FIELDS)->{$pfield};
			    $aux .= (SY_ANNOTATION_TYPE)->{$itype};
			    ($sourcefile = $cfile) =~ s/$current/$aux/;
			}
			RemoveFromIndex($sourcefile, $outfield, $itype) if ($sourcefile ne "");
		    }
		    print "Index entries removed at ", scalar localtime, ".\n";
		}
		if (defined((SY_ANNOTATION_FIELDS)->{$pfield})) {
		    foreach my $itype (keys % {(SY_ANNOTATION_TYPE)}) {
			# 2) eliminate from annotation the content of current file,
			#    if field is annotated
			my $outfield = SY_ROOT . (SY_SUBROOTS)->{annotations};
			$outfield .= (SY_ANNOTATION_FIELDS)->{$pfield};
			RemoveFromAnnotation($cfile, $outfield, $itype);
		    }
		}
		print "Annotations removed at ", scalar localtime, ".\n";
		# 3) copy incoming file to current file and tokenize it
		my @lines = SpecialReplacements(GetLines($ifile));
		my $outline = Tokenizer(@lines);
		open (OUT, ">$cfile");
		print OUT $outline;
		close (OUT);
		print "Tokenized and copied $ifile at ", scalar localtime, ".\n";
		print "timestamps new: ", scalar localtime $imtime;
		print ", old: ", scalar localtime $cmtime, ".\n";		
		if (defined((SY_ANNOTATION_FIELDS)->{$pfield})) {
		    foreach my $itype (keys % {(SY_ANNOTATION_TYPE)}) {
			# 4) annotate incoming file if field is annotated
			my $outfield = SY_ROOT . (SY_SUBROOTS)->{annotations};
			$outfield .= (SY_ANNOTATION_FIELDS)->{$pfield};
# ***************************** LISA ADDED *******************************************
			my $outfield2 = SY_ROOT . (SY_SUBROOTS)->{xml};
			$outfield2 .= (SY_ANNOTATION_FIELDS)->{$pfield};
			AddToAnnotationInOneProcess($cfile, $outfield, $outfield2, $itype, \%lexicon);
			# AddToAnnotationInOneProcess($cfile, $outfield, $itype, \%lexicon);
		    }
		}
		print "Annotated at ", scalar localtime, ".\n";
		# remove special preprocessing tags (<WSD> and possibly others)
		# from current file
		RemovePreprocessingTags($cfile);
		if (defined((SY_INDEX_FIELDS)->{$pfield})) {
		    foreach my $itype (keys % {(SY_INDEX_TYPE)}) {
			# 5) index tokenized incoming file
			my $outfield = SY_ROOT . (SY_SUBROOTS)->{indices};
			$outfield .= (SY_INDEX_FIELDS)->{$pfield};
			my $sourcefile;
			if (($itype eq 'keyword') && ($command ne 'categories-only')) {
			    $sourcefile = $cfile;
			} elsif (($itype eq 'semantic') || ($itype eq 'grammatical')) {
			    my $aux = SY_ROOT . (SY_SUBROOTS)->{annotations};
			    $aux .= (SY_ANNOTATION_FIELDS)->{$pfield};
			    $aux .= (SY_ANNOTATION_TYPE)->{$itype};
			    ($sourcefile = $cfile) =~ s/$current/$aux/;
			}
			AddToIndex ($sourcefile, $outfield, $itype) if ($sourcefile ne "");
		    }
		    print "Indexed at ", scalar localtime, ".\n";
		}
		# 6) if $pfield is one of the bib fields, update SY_BIB_NAME entry
		if (defined((SY_BIB_FIELDS)->{$pfield})) {
		    my $aux = SY_ROOT . (SY_SUBROOTS)->{processedfiles} . SY_BIB_NAME;
		    (my $bibfile = $cfile) =~ s/$current/$aux/;
		    my @oldbib = GetLines($bibfile);
		    my $entrypattern = $pfield . SY_BIB_SEPARATOR;
		    my @newbib = ();
		    foreach my $entry (@oldbib) {
			if ($entry !~ /$entrypattern/) {
			    push @newbib, $entry;
			}
		    }
		    my @newlines = GetLines($cfile);
		    foreach my $line (@newlines) {
			push @newbib, $entrypattern . $line;
		    }
		    open (OUT, ">$bibfile");
		    print OUT join("\n", @newbib);
		    close (OUT);
		}
		@timeAfterProcessing = localtime();
		$totalProcessingTime += ($timeAfterProcessing[2]*60*60 + $timeAfterProcessing[1]*60 + $timeAfterProcessing[0])
		    -($timeBfrProcessing[2]*60*60 + $timeBfrProcessing[1]*60 + $timeBfrProcessing[0]);
		$no_of_papers++;
		print "Processing time so far = $totalProcessingTime s.   No of papers processed = $no_of_papers.\n";
		
	    }
	} else {
	    print "$efile exists.\n";
	}
    }
    # write a .sort file sorting all entries of a field
    my @allfiles = <$current/*>;
    my %aux = ();
    foreach my $file (@allfiles) {
	(my $name = $file) =~ s/$current\///;
	my @alines = GetLines ($file);
	my $upper = (scalar(@alines) < 10) ? scalar(@alines) : 10;
	my $content;
	for (my $i = 0; $i < $upper; $i++) {
	    $content .= $alines[$i];
	}
	$content =~ s/\s//g;
	push @{$aux{$content}}, $name;
    }
    open(OUT, ">$current/\.sort");
    foreach my $key (sort { lc($b) cmp lc($a) } keys % aux) {
	print OUT join("\n", @{$aux{$key}}), "\n";
    }
    close(OUT);
}

print "Total time taken = $totalProcessingTime s\n";
print "Total time taken per file = ", $totalProcessingTime/$no_of_papers, " s\n" if ($no_of_papers > 0);
