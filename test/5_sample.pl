#!/usr/bin/perl
#
use strict;
use lib('../lib','lib');
use warnings;
use Getopt::Long;
use warnings;
use DTP;
my $dtp;

if (defined($ARGV[0]) ne ""){
   $dtp=new DTP("$ARGV[0]");
}
else{
   die("usage: scriptname [ png ] [ jpg ] [ pdf ]\n");
}

$dtp->NewPage(format=>'A4landscape');
my ($xmin,$ymin,$xmax,$ymax)=$dtp->Workspace();
$dtp->Line(($xmax-$xmin)/2+$xmin,$ymin+10,($xmax-$xmin)/2+$xmin,$ymax-10);
$dtp->Line($xmin+10,($ymax-$ymin)/2+$ymin,$xmax-10,($ymax-$ymin)/2+$ymin);
foreach my $file ($dtp->GetDocument()){
   printf("created %s\n",$file);
}
