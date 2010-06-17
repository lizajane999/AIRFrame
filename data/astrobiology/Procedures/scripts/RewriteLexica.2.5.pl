#!/usr/bin/perl

use strict;
use lib "/usr/local/lib/textpresso/";
use TextpressoGeneralTasks;
use TextpressoGeneralGlobals;

use File::stat;
use File::Basename;

my $dirin = $ARGV[0];
my $dirout = $ARGV[1]; # that directory should be empty
                       # before starting the script!


my %oldlex = ReadLexica($dirin, (GE_DELIMITERS)->{lexicon});
my %newlex = ();
foreach my $key (keys % oldlex) {
    (my $aux = $key) =~ s/ \\(.) /$1/g; # remove all backslashes
    my $newkey = ReplaceSpecChar($aux);
    foreach my $cat (keys % { $oldlex{$key} }) {
	@{$newlex{$newkey}{$cat}} = @{$oldlex{$key}{$cat}};
    }
    delete $oldlex{$key};
}
WriteLexica($dirout, (GE_DELIMITERS)->{lexicon}, \%newlex);
