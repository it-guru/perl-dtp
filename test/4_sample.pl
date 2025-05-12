#!/usr/bin/perl
#
use strict;
use lib('../lib','lib');
use warnings;
use DTP;
use DTP::Entity::LineChart;
use DTP::Entity::Table;
use Getopt::Long;
use warnings;
my $dtp;

if (defined($ARGV[0]) ne ""){
   $dtp=new DTP("$ARGV[0]");
}
else{
   die("usage: scriptname [ png ] [ jpg ] [ pdf ]\n");
}


my %font=(font       => "Helvetica",
          color      => "darkblue");

$dtp->NewPage();

my @t=("Name:"       =>"Vogler",
       "Vorname:"    =>"Hartmut",
       "Tel:"        =>"1230/9123495\n01233/412326",
       "Geb:"        =>"00.00.1972");

while(my $label=shift(@t)){
   my $val=shift(@t);
   $dtp->WriteLine([$label,$val],
                   %font,
                   bold       =>[1,0],
                   width      =>[90,undef],
                   bordercolor=>'steelblue',
                   background =>'yellow',
                   border     =>1);
}





my %p=(data       =>['Jan'=>[11,22,44,55],
                     'Feb'=>[5,33,2,66],
                     'Mar'=>[15,43,8,60],
                     'Apr'=>[10,43,9,60],
                     'Mai'=>[8,45,12,68],
                     'Jun'=>[4,40,12,68]],
       datacolor  =>['red','green','darkblue','yellow'],
       orientation=>'v',
       border     =>1,
       bgcolor=>'silver',
       shadow=>5,
       bordercolor=>'gray',
      );


my $e=new DTP::Entity::LineChart(%p);
$dtp->WriteLine([$e],%font,minheight=>250,border=>1);

%p=   (data       =>['0'=>[11,22,44,45],
                     '1'=>[5,33,2,36],
                     '3'=>[15,43,8,30],
                     '4'=>[10,43,9,30],
                     '6'=>[8,45,12,38],
                     '333'=>[4,40,12,48]],
       datacolor  =>['red','green','darkblue','yellow'],
       orientation=>'v',
       border     =>1,
       margin=>0,
       padding=>0,
       bordercolor=>'blue',
      );
$e=new DTP::Entity::LineChart(%p);


my $t=new DTP::Entity::Table(["Hallo","Dies ist ein mehrzeiliger Text mit Umbruch\nstart Zeile 2"],
                   %font,
                   bold       =>[1,0],
                   width      =>[50,undef],
                   bordercolor=>'steelblue',
                   border     =>1);

$dtp->WriteLine([$e,$e,$t],%font,minheight=>250,border=>1);

   
foreach my $file ($dtp->GetDocument()){
   printf("created %s\n",$file);
}
