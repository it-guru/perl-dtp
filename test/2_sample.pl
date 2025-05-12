#!/usr/bin/perl
#
use strict;
use lib('../lib','lib');
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

$dtp->NewPage();
$dtp->Line(50,10,100,150);

my $x=200;
my $y=200;
my @text=("Hallo1","Hallo Welt 2","Hallox");
my %font=(font       => "Helvetica",
          color      => "black");

foreach my $text (@text){
   my ($width,$height)=$dtp->TextDimension($text,%font);
   #printf("text=$text   width=$width   height=$height\n");
   $dtp->TextOut($x,$y,$text,%font);
   $x+=$width;
   $y+=$height;
}

$dtp->SetPPos($y+350);
my $blabla=<<EOF;
Dies ist der ganz lange Text, der an versch. Stellen umgebrochen werden muss. Der Text wird auch nach dem foglenden Punkt durch einen Line-Feed umgebrochen.
Und dann kommt dann noch div. Blab Bla und ein zusÃtlicher Line-Feed
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll
Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test. Dies ist ein Test.
Das ist das Ende.
EOF
my $readme="readme.txt not in current dir";
if (open(F,"<readme.txt")){
   $readme=join("",<F>);
   close(F);
}

my @t=("Name:"       =>"Vogler",
       "Vorname:"    =>"Hartmut",
       "Strasse:"    =>"Irgendow 4",
       "Ort:"        =>"96129 Strullendorf OT Amlingstadt",
       "BlaBla:"     =>$blabla,
       "readme:"     =>$readme,
       "Tel:"        =>"1230/9123495\n01233/412326",
       "Geb:"        =>"00.00.1972");

while(my $label=shift(@t)){
   my $val=shift(@t);
   $dtp->WriteLine([$label,$val],
                   %font,
                   bold       =>[1,0],
                   width      =>[90,undef],
                   bordercolor=>'steelblue',
                   background =>'lightgray',
                   border     =>1);
}

#$dtp->NewPage();
#$dtp->NewPage(format=>'A4landscape');
#$dtp->Rec(50,50,150,100,color=>'steelblue',filled=>1);
foreach my $file ($dtp->GetDocument()){
   printf("created %s\n",$file);
}
