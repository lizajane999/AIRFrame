#!/usr/bin/perl -w

use strict;
# The following line needs adjustments for each implementation
use lib "/usr/local/lib/textpresso/dataprocessing/astrobiology/";
# end line that needs adjustments
use TextpressoSystemGlobals;

my $USAGE = <<END_USAGE;

$0 (c) Hans-Michael Muller, Pasadena, 2007
    Script creates the directory structure for the system database.

END_USAGE

print "$USAGE\n";

my $root = SY_ROOT;
my $rootann = SY_ROOT . '/' . (SY_SUBROOTS)->{annotations};
my $rootinc = SY_ROOT . '/' . (SY_SUBROOTS)->{includes};
my $rootexc = SY_ROOT . '/' . (SY_SUBROOTS)->{excludes};
my $rootind = SY_ROOT . '/' . (SY_SUBROOTS)->{indices};
my $rootont = SY_ROOT . '/' . (SY_SUBROOTS)->{ontology};
my $rootsup = SY_ROOT . '/' . (SY_SUBROOTS)->{supplementals};
my $rootpro = SY_ROOT . '/' . (SY_SUBROOTS)->{processedfiles};
my $rootetc = SY_ROOT . '/' . (SY_SUBROOTS)->{etc};

# create root directory
morp($root);

# create annotation directories
morp($rootann);
foreach my $k1 (keys % {(SY_ANNOTATION_FIELDS)}) {
    my $aux1 = $rootann . (SY_ANNOTATION_FIELDS)->{$k1};
    morp($aux1);
    foreach my $k2 (keys % {(SY_ANNOTATION_TYPE)}) {
	my $aux2 = $aux1 . (SY_ANNOTATION_TYPE)->{$k2};
	morp($aux2);
	if (SY_ANNOTATION_SUBTYPE_INSTANCES =~ /$k1/) {
	    foreach my $k3 (keys % {(SY_ANNOTATION_SUBTYPE)}) {
		my $aux3 = $aux2 . (SY_ANNOTATION_SUBTYPE)->{$k3};
		morp($aux3);
	    }
	}
    }
}

# create includes directory
morp($rootinc);
foreach my $k1 (keys % {(SY_SOURCE_FIELDS)}) {
    my $aux1 = $rootinc . (SY_SOURCE_FIELDS)->{$k1};
    morp($aux1);
}

# create excludes directory
morp($rootexc);
foreach my $k1 (keys % {(SY_SOURCE_FIELDS)}) {
    my $aux1 = $rootexc . (SY_SOURCE_FIELDS)->{$k1};
    morp($aux1);
}

# create indices directory
morp($rootind);
foreach my $k1 (keys % {(SY_INDEX_FIELDS)}) {
    my $aux1 = $rootind . (SY_INDEX_FIELDS)->{$k1};
    morp($aux1);
    foreach my $k2 (keys % {(SY_INDEX_TYPE)}) {
	if ((join(" ", keys % {(SY_ANNOTATION_FIELDS)}) =~ /$k1/) ||
	    (join(" ", keys % {(SY_ANNOTATION_TYPE)}) !~ /$k2/)) {
	    my $aux2 = $aux1 . (SY_INDEX_TYPE)->{$k2};
	    morp($aux2);
	    if (SY_INDEX_SUBTYPE_INSTANCES =~ /$k2/) {
		foreach my $k3 (keys % {(SY_INDEX_SUBTYPE)}) {
		    my $aux3 = $aux2 . (SY_INDEX_SUBTYPE)->{$k3};
		    morp($aux3);
		}
	    }
	} 
    }
}

# create ontology directory
morp($rootont);
foreach my $k1 (keys % {(SY_ONTOLOGY)}) {
    my $aux1 = $rootont . (SY_ONTOLOGY)->{$k1};
    morp($aux1);
}

# create supplementals directory
morp($rootsup);
foreach my $k1 (keys % {(SY_SUPPLEMENTALS)}) {
    my $aux1 = $rootsup . (SY_SUPPLEMENTALS)->{$k1};
    morp($aux1);
}

# create processedfiles directories
morp($rootpro);
foreach my $k1 (keys % {(SY_PASSTHROUGH_FIELDS)}) {
    my $aux1 = $rootpro . (SY_PASSTHROUGH_FIELDS)->{$k1};
    morp($aux1);
}
foreach my $k1 (keys % {(SY_ANNOTATION_FIELDS)}) {
    my $aux1 = $rootpro . (SY_ANNOTATION_FIELDS)->{$k1};
    morp($aux1);
}

# create etc directory
morp($rootetc);

sub morp {
    
    my $aux = shift;
    mkdir($aux) || 
	print "Directory $aux already created. Not generated.\n";
    
}
