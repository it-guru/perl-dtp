#!/usr/bin/perl
#
use strict;
use lib('../lib','lib');
use DTP::Entity::LineChart;
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

my $x=200;
my $y=200;
my %font=(font       => "Helvetica",
          color      => "darkblue");

foreach my $format (qw(A4 A4landscape)){
   my @t=("Name:"       =>"Vogler",
          "Vorname:"    =>"Hartmut",
          "Strasse:"    =>"Irgendwo 4",
          "Ort:"        =>"96129 Strullendorf OT Amlingstadt",
          "Geb:"        =>"00.00.1972");
   $dtp->NewPage(format=>$format);
   $dtp->WriteLine(["Ueberschrift"],fontsize=>28,bold=>1,align=>'center');
   $dtp->WriteLine(["right\nhans"],fontsize=>20,bold=>1,align=>'right');
   while(my $label=shift(@t)){
      my $val=shift(@t);
      $dtp->WriteLine([$label,$val],
                      %font,
                      width      =>[90,undef],
                      border     =>1);
   }
   
   
   my $e=new DTP::Entity(border=>1);
   $dtp->WriteLine(["Entity:",$e],
                   %font,
                   minheight  =>[undef,50],
                   width      =>[90,undef],
                   border     =>1);
   
   $dtp->Place(undef,undef,new DTP::Entity::LineChart(border=>1),
               height=>50,'margin-bottom'=>0);
   $dtp->Place(undef,undef,new DTP::Entity(border=>1));
}

foreach my $file ($dtp->GetDocument()){
   printf("created %s\n",$file);
}
