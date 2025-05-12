package DTP::GD;
#  a Perl module for Desktop Publishing in pdf-format
#
#  Copyright (C) 2007  Holm Basedow (it@guru.de)
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
use GD;
use Data::Dumper;
use DTP;


@ISA=qw(DTP);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=$type->SUPER::new(%$self);
   bless($self,$type);
   $self->{_GDPage}=[];
   return($self);
}

sub NewPage
{
   my ($self,%param)=@_;

   $self->_storeLayoutParameter(%param);
   
   my $img=new GD::Image($self->{_Layout}->{width},
                         $self->{_Layout}->{height});

   return(undef) if (!defined($img));
   $self->{_Page}++;
   my $filename=sprintf($self->{_Layout}->{tempfile},$self->{_Page});
   push(@{$self->{_GDPage}},{GD=>$img,filename=>$filename,color=>{}});
   #
   # allocate white as transparent (compatible to pdf)
   #
   my $background=$self->_GDcolor([255,255,255]);
   $self->_GD->transparent($background);
   $self->{_PPos}=0;
   if (ref($self->{_Layout}->{template}) eq "CODE"){
      &{$self->{_Layout}->{template}}($self);
   }
   
   return(1);
}

sub _GD   # internal method to get the gd opject of the current page
{
   my $self=shift;
   return(undef) if ($self->{_Page}==0);
   return($self->{_GDPage}->[$self->{_Page}-1]->{GD});
}

sub _GDcolor
{
   my $self=shift;
   my $color=shift;
   my ($r,$g,$b)=$self->SUPER::Color(color=>$color);
   my $key="$r,$g,$b";
   if (!defined($self->{_GDPage}->[$self->{_Page}-1]->{color}->{$key})){
      $self->{_GDPage}->[$self->{_Page}-1]->{color}->{$key}=
                  $self->_GD->colorAllocate($r,$g,$b);
   }
   return($self->{_GDPage}->[$self->{_Page}-1]->{color}->{$key});

}

sub Line
{
   my ($self,$x1,$y1,$x2,$y2,%param)=@_;
   my $gd=$self->_GD;
   return(undef) if (!defined($gd));
   $param{color}="black" if (!defined($param{color}));
   $param{style}="solid" if (!defined($param{style}));
   $param{width}=1       if (!defined($param{width}));
   my $GDcolor=$self->_GDcolor($param{color});
   $gd->setThickness($param{width});
   $gd->line($x1,$y1,$x2,$y2,$GDcolor);
}


sub TextOut
{
   my ($self,$x,$y,$text,%param)=@_;
   my $gd=$self->_GD;
   return(undef) if (!defined($gd));
   $x=0                if (!defined($x));
   $y=$self->GetPPos() if (!defined($y));
   my $textparam=$self->_parseTextOutParam(\%param);
   my $fontname=$self->_GDfindFontName($textparam);
   if (!defined($fontname)){
      printf STDERR ("ERROR: can't find requested font '%s'\n",
                     $textparam->{font});
      return(undef);
   }
   my $GDcolor=$self->_GDcolor($param{color});
   $self->GDstringFT($gd,$GDcolor,$fontname,
                     $textparam->{fontsize},0.0,$x,$y,$text);
   return(1);
}

sub TextDimension
{
   my ($self,$text,%param)=@_;

   my $gd=$self->_GD;
   return(undef) if (!defined($gd));
   my $textparam=$self->_parseTextOutParam(\%param);
   my $fontname=$self->_GDfindFontName($textparam);
   if (!defined($fontname)){
      printf STDERR ("ERROR: can't find requested font '%s'\n",
                     $textparam->{font});
      return(undef);
   }
   my $GDcolor=$self->_GDcolor($param{color});
   my @dim=$self->GDstringFT(undef,$GDcolor,$fontname,
                             $textparam->{fontsize},0.0,0,0,$text);

   my ($width,$height)=($dim[2]-$dim[0],$dim[1]-$dim[7]);
#printf("fifi TextDimension t=$text fontsize=$textparam->{fontsize} width=$width height=$height fontname=$fontname\n");
   return($width,$height);
}

sub GDstringFT
{
   my $self=shift;
   my $gd=shift;
   if ($gd){
      my @dim=$gd->stringFT(@_);
#      $self->Line(@dim[0,1],@dim[2,3],color=>'red');
#      $self->Line(@_[4]-5,@_[5],@_[4]+5,@_[5],color=>'blue');
#      $self->Line(@_[4],@_[5]-5,@_[4],@_[5]+5,color=>'blue');
      return(@dim);
   }
   return(GD::Image->stringFT(@_));
}


sub Image
{
   my ($self,$imagetype,$filename,$x,$y,%param)=@_;
   my $gd=$self->_GD;

   my $image;
   if ($imagetype eq "png"){
      $image=GD::Image->newFromPng($filename,0);
      my $white = $image->colorClosest(255,255,255); # find white
      $image->transparent($white);
   }
   if (defined($image)){
      my ($width,$height) = $image->getBounds();
      $gd->copy($image,$x,$y-$height,0,0,$width,$height);
   }



}


sub _GDfindFontName
{
   my ($self,$textparam)=@_;
   my $fn=lc($textparam->{font});
   my $GDFontDir="DTP/fonts";
   $fn="arial" if ($fn eq "helvetica");
   $fn="cour"  if ($fn eq "courier");
   my $fext="";
   if ($textparam->{bold} && !$textparam->{italic}){
      $fext="bd";
   }
   if (!$textparam->{bold} && $textparam->{italic}){
      $fext="i";
   }
   if ($textparam->{bold} && $textparam->{italic}){
      $fext="bi";
   }
   my $fontShortName="$fn$fext.ttf";
   if (!defined($self->{_GD_FontPath}->{$fontShortName})){
      foreach my $dir (@INC){
         my $checkName="$dir/$GDFontDir/$fontShortName";
         if (-r $checkName){
            $self->{_GD_FontPath}->{$fontShortName}=$checkName;
            last;
         }
      }
   }
   return($self->{_GD_FontPath}->{$fontShortName});
}


1;
