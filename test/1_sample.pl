#!/usr/bin/perl
#
use strict;
use lib('lib','../lib');
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
open (FH,"readme.txt");
my $readme;
while(<FH>){
  $readme.=$_;
}
close(FH);
$dtp->NewPage(format=>'A4landscape'); # format [A4landscape|A4] default A4 format
my $x=200;
my $y=200;
my @text=("Hallo1","Hal---","Hallox");
my %font=(font       => "Helvetica",
          color      => "magenta");

foreach my $text (@text){
   my ($width,$height)=$dtp->TextDimension($text,%font);
#   printf("text=$text  \t width=$width \t  height=$height \t font=$font{font}\n");
   $dtp->TextOut($x,$y,$text,%font);
   $x+=$width;
   $y+=$height;
}
$dtp->GetDocument();




#my ($xmin,$ymin,$xmax,$ymax)=$dtp->Workspace();
#$dtp->Line(($xmax-$xmin)/2+$xmin,$ymin+10,($xmax-$xmin)/2+$xmin,$ymax-10);
#$dtp->Line(10,10,30,50,color=>'blue',width=>5);
#$dtp->TextPrint($readme,$xmin,$ymin,$xmax,$ymax,
#               color=>[255,0,0],font=>'Courier',
#                fontsize=>35,cols=>3,widht=>50);# text, optional width default=all, cols default=1, color default='0,0,0'
#$dtp->EndPage();

#$dtp->NewPage();
#$dtp->Color('22,87,44');
#$dtp->SetPos(100,100,typ=>'graphic');
#$dtp->Line(200,100);
#$dtp->Line(200,200);
#$dtp->Line(100,200);
#$dtp->Line(100,100);
#$dtp->Fill();
#$dtp->Color('2,87,99');
#$dtp->SetPos(500,400,typ=>'graphic');
#$dtp->Line(200,320);
#$dtp->Line(200,200);
#$dtp->Line(100,200);
#$dtp->Line(100,100);
#$dtp->Fill();
#$dtp->SetFont(font=>'Courier',size=>20); # Courier, Courier-Bold, Courier-Oblique, Helvetica, Helvetica-Bold, Helvetica-Oblique
                                          # Times-Roman, Time-Bold, Times-Italic, optional size default=10;
#$dtp->SetPos(50,10,typ=>'text');         # optional x default=0, y default=0, typ [graphic|text] default=text

#eval{$dtp->EndPage()};
#die "Abgefangene Exception" if $@;
#$dtp->Stroke();

#$dtp->NewPage(format=>'A4landscape');
#my ($xmin,$ymin,$xmax,$ymax)=$dtp->Workspace();
#$dtp->Line(($xmax-$xmin)/2+$xmin,$ymin+10,($xmax-$xmin)/2+$xmin,$ymax-10);
#$dtp->Line($xmin+10,($ymax-$ymin)/2+$ymin,$xmax-10,($ymax-$ymin)/2+$ymin);
#foreach my $file ($dtp->GetDocument()){
#   printf("created %s\n",$file);
#}

