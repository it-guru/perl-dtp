package DTP::Entity::LineChart;
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

use strict;
use vars(qw(@ISA));
use Data::Dumper;
use DTP::Entity;

@ISA=qw(DTP::Entity);


=pod

=head1 NAME

DTP::Entity::LineChart - Chart line graph

=head1 DESCRIPTION

Chart

=head1 CONSTRUCTOR

=over

=item new()

 my $e=new DTP::Entity::LineChart();

B<Constructor to create the DTP object.>

=back

=cut

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($type->SUPER::new(%$self),$type);
   return($self);
}



sub onDraw
{
   my $self=shift;
   my ($xmin,$ymin,$xmax,$ymax)=$self->Workspace();




   if ($self->{shadow}>0){
      my %p=(filled=>1,color=>'black');
      if ($self->{shadowcolor} ne ""){
         $p{color}=$self->{shadowcolor};
      }
      $self->Rec($xmin+$self->{shadow},$ymin+$self->{shadow},$xmax,$ymax,%p);
      $xmax-=$self->{shadow};  # reduce the Workspace
      $ymax-=$self->{shadow};
   }

   if ($self->{bgcolor} ne ""){
      $self->Rec($xmin,$ymin,$xmax,$ymax,color=>$self->{bgcolor},filled=>1);
   }
   if ($self->{border}){
      my %p=(filled=>0);
      $p{color}=$self->{bordercolor} if ($self->{bordercolor} ne "");
      $self->Rec($xmin,$ymin,$xmax,$ymax,%p);
   }
   #
   # Pass 1 : calculation significant points
   #
   my %descfont=(fontsize=>8);
   my $isXnumeric=1;
   my @chk;
   @chk=@{$self->{data}} if (ref($self->{data}) eq "ARRAY");
   my $yDataMax=0;
   my $yDataMin=0;
   my $xDataMax=0;
   my $xDataMin=0;
   my @data;
   my @xdesc;
   my $xdescFontHeight=0;
   my @xdescFontWidth;
   my $c=0;
   while(defined(my $xlabel=shift(@chk))){
      my $data=shift(@chk);
      $data=[$data] if (!ref($data) eq "ARRAY");
      foreach my $yval (@$data){
         $yDataMax=$yval if ($yDataMax<$yval);
         $yDataMin=$yval if ($yDataMin>$yval);
      }
     # printf("fifi xlabel=$xlabel  (%s)\n",$xlabel*1);
      if ($xlabel*1 ne $xlabel){  # numeric check for x koordinate
         $isXnumeric=0;
      }
      if ($isXnumeric){
         $xDataMax=$xlabel if ($xDataMax<$xlabel);
         $xDataMin=$xlabel if ($xDataMin>$xlabel);
      }
      $xdesc[$c]=$xlabel;
      my ($width,$height)=$self->TextDimension($xdesc[$c],%descfont);
      $xdescFontHeight=$height if ($xdescFontHeight<$height);
      $xdescFontWidth[$c]=$width;
      push(@data,$xlabel,$data);
      $c++;
   }
   my @ydesc;
   my $ydescFontWidth;
   my @ydescFontWidth;
   my ($yscale,$ymainstep,$ysubstep)=DTP::Entity::calcScaleMax($yDataMax);
   my ($xscale,$xmainstep,$xsubstep);
   if ($isXnumeric){
      @xdescFontWidth=();
      $xdescFontHeight=0;
      ($xscale,$xmainstep,$xsubstep)=DTP::Entity::calcScaleMax($xDataMax);
      for(my $c=0;$c<=10;$c++){
         $xdesc[$c]=$xmainstep*$c;
         my ($width,$height)=$self->TextDimension($xdesc[$c],%descfont);
         $xdescFontHeight=$height if ($xdescFontHeight<$height);
         $xdescFontWidth[$c]=$width;
      }
   }
   for(my $c=0;$c<=10;$c++){
    #  $ydesc[$c]=" ".$ymainstep*$c;
      $ydesc[$c]=$ymainstep*$c;
      my ($width)=$self->TextDimension($ydesc[$c],%descfont);
      $ydescFontWidth=$width if ($ydescFontWidth<$width);
      $ydescFontWidth[$c]=$width;
   }
   my $axesLines=4; 
   my $yBottomLine=$ymax-(1.5*$descfont{fontsize})-$axesLines-$axesLines;
   my $xBottomStart=$xmin+$ydescFontWidth+$axesLines+$axesLines;
   my $xBottomEnd=$xmax-20;
   my $xLeftLine=$xBottomStart;
   my $yLeftStart=$yBottomLine;
   my $yLeftEnd=$ymin+(2.5*$descfont{fontsize});

#printf("fifi d=%s\n",Dumper(\@xdesc));
#printf("fifi w=%s\n",Dumper(\@xdescFontWidth));
   for(my $c=0;$c<=$#xdesc;$c++){
      my $vxBottomStart=$xBottomStart;
      $vxBottomStart+=3*$descfont{fontsize} if (!$isXnumeric);
      my $x=$vxBottomStart+(($xBottomEnd-$vxBottomStart)/$#xdesc*$c);
      $self->Line($x,$yBottomLine,$x,$yBottomLine+$axesLines);
      #($xdescFontWidth[$c])=$self->TextDimension($xdesc[$c],%descfont);
       my ($tx,$ty)=($x-(int(0.5*$xdescFontWidth[$c]))+1,
                     $yBottomLine+$axesLines+(1.4*$descfont{fontsize}));
      $self->TextOut($tx,$ty,$xdesc[$c],%descfont);
#      $dtp->Line($tx-3,$ty,$tx+3,$ty,color=>'green');
#      $dtp->Line($tx,$ty-3,$tx,$ty+3,color=>'green');
#
#      $dtp->Line($tx,$ty+5,$tx,$ty+10);
#      $dtp->Line($tx+$xdescFontWidth[$c],$ty+5,$tx+$xdescFontWidth[$c],$ty+10);
   }
   $self->Line($xBottomStart,$yBottomLine,$xBottomEnd,$yBottomLine);
   for(my $c=0;$c<=10;$c++){
      my $y=$yLeftStart-(($yLeftStart-$yLeftEnd)/10*$c);
      $self->Line($xLeftLine,$y,$xLeftLine-$axesLines,$y);
      $self->TextOut($xLeftLine-$axesLines-$ydescFontWidth[$c],
                    $y+0.5*$descfont{fontsize},
                    $ydesc[$c],%descfont);
   }
   my $ylabel='Y-Koor';
   $ylabel=$self->{ylabel} if (exists($self->{ylabel}));
   $self->TextOut($xmin+2,
                 $yLeftEnd-$descfont{fontsize},
                 $ylabel,%descfont);
   $self->Line($xLeftLine,$yLeftStart,$xLeftLine,$yLeftEnd);
#   printf("fifi isXnumeric=$isXnumeric\n");
#   printf("fifi xDataMin=$xDataMin   xDataMax=$xDataMax\n");
#   printf("fifi yDataMin=$yDataMin   xDataMax=$yDataMax\n");
#   printf("fifi yscale=$yscale  ymainstep=$ymainstep ysubstep=$ysubstep\n");
#   printf("fifi xscale=$xscale \n");

   @chk=@data if (ref($self->{data}) eq "ARRAY");
   my @lastkoord;
   while(defined(my $xlabel=shift(@chk))){
      my $data=shift(@chk);
      $data=[$data] if (!ref($data) eq "ARRAY");
      for(my $lineno=0;$lineno<=$#{$data};$lineno++){
         my $xdata=$xlabel;
         my $ydata=$data->[$lineno];
         if (defined($ydata)){
            if (defined($lastkoord[$lineno])){
               my ($x1,$x2,$y1,$y2)=
                  (0,0,0,0);
               if ($xscale*$lastkoord[$lineno]->[0]>0){
                  $x1=($xBottomEnd-$xBottomStart)/$xscale*
                      $lastkoord[$lineno]->[0];
               }
               if ($xscale*$xdata>0){
                  $x2=($xBottomEnd-$xBottomStart)/$xscale*$xdata;
               }
               if ($yscale*$lastkoord[$lineno]->[1]>0){
                  $y1=($yLeftStart-$yLeftEnd)/$yscale*
                      $lastkoord[$lineno]->[1];
               }
               if ($yscale*$ydata>0){
                  $y2=($yLeftStart-$yLeftEnd)/$yscale*$ydata;
               }
               my %p=();
               if ($self->{datacolor}->[$lineno] ne ""){
                  $p{color}=$self->{datacolor}->[$lineno];
               }
               $self->Line($xBottomStart+$x1,$yLeftStart-$y1,
                           $xBottomStart+$x2,$yLeftStart-$y2,
                           %p);
            }
            $lastkoord[$lineno]=[$xdata,$ydata];
         }
      }
   }

   

   return($self);
}


=pod

=head1 COPYRIGHT

Copyright (C) 2007 Vogler Hartmut. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
