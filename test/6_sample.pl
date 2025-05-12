#!/usr/bin/perl
#
use strict;
use lib('../lib','lib');
use warnings;
use DTP;
use DTP::Entity::LineChart;
use DTP::Entity::Table;
use Getopt::Long;
use Data::Dumper;
use warnings;
my $dtp;

if (defined($ARGV[0]) ne ""){
   $dtp=new DTP("$ARGV[0]");
}
else{
   die("usage: scriptname [ png ] [ jpg ] [ pdf ]\n");
}


$dtp->NewPage(format=>"A4landscape");

$dtp->Rec(100,100,742,120,filled=>1,color=>'gray');
$dtp->Rec(100,100,150,150,filled=>1,color=>'darkred');

my $x=170;
my $y=175;
my $text=("Perl DTP Module");
my %font=(font       => "Helvetica",
          color      => "darkred",
          fontsize   => 42);
my ($width,$height)=$dtp->TextDimension($text,%font);
$dtp->TextOut($x,$y,$text,%font);

$dtp->Rec(692,170,742,220,filled=>1,color=>'darkred');
$dtp->Rec(100,200,742,220,filled=>1,color=>'gray');


$x=350;
$y=450;
%font=(font       => "Helvetica",
       color      => "navy",
       fontsize   => 28);
$text=("Extension for Presentations");
$dtp->TextOut($x,$y,$text,%font);
($width,$height)=$dtp->TextDimension($text,%font);
$x+=10;
$y+=$height+10;
$text=("in OpenDocument Format.");
$dtp->TextOut($x,$y,$text,%font);



#$dtp->SetPPos(450);
#$dtp->WriteLine("ODP Extension",
#                %font,
#                bordercolor=>'steelblue',
#                background =>'yellow',
#                border     =>1);




$dtp->NewPage(format=>"A4landscape");

$dtp->Rec(20,30,672,50,filled=>1,color=>'gray');
$dtp->Rec(20,30,70,80,filled=>1,color=>'darkred');

$x=80;
$y=55;
$text=("Perl DTP Module");
%font=(   font       => "Helvetica",
          color      => "darkred",
          fontsize   => 42);
($width,$height)=$dtp->TextDimension($text,%font);
$dtp->TextOut($x,$y+$height,$text,%font);

$y=$y+$height+20;
$dtp->SetPPos($y);
$text=("The Perl DTP Module is a module for Desktop-Publishing, to allow document creation in various formats.

It is licensed as OpenSource-Software, so you can download and use the software free-of-charge.

For more information and download visit the Project Information on Sourceforge.");
%font=(font       => "Helvetica",
       color      => "navy",
       fontsize   => 24);
$dtp->WriteLine($text,%font);

$dtp->Rec(772,527,822,577,filled=>1,color=>'darkred');
#$dtp->Rec(100,200,742,220,filled=>1,color=>'gray');
$dtp->Rec(170,557,822,577,filled=>1,color=>'gray');


$dtp->GetDocument();
