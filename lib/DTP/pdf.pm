package DTP::pdf;
#  a Perl module for Desktop Publishing in pdf-format
#
#  Copyright (C) 2007  Holm Basedow (holm@blauwaerme.de)
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
use pdflib_pl 7.0;
use Data::Dumper;
use DTP;


@ISA=qw(DTP);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=$type->SUPER::new(%$self);
   bless($self,$type);
   return($self);
}

sub GetDocument
{
   my ($self,$filename)=@_;
   if ($filename eq "")
   {
     $filename=sprintf($self->{_Layout}->{tempfile},1);
     $filename.=".pdf";
   }
   PDF_end_page($self->{pdf});
   PDF_end_document($self->{pdf},'');
   if (!open(FH,">$filename")){
      printf STDERR ("ERROR: can't open $filename\n");
      return(undef);
   }
   print FH (PDF_get_buffer($self->{pdf}));
   close(FH);
   printf("INFO: created file=%s\n",$filename);
   return($filename);
}

sub NewPage
{
   my ($self,%param)=@_;
   $self->_storeLayoutParameter(%param);
   if (!defined($self->{pdf})){
      $self->{pdf}=PDF_new();
      PDF_begin_document($self->{pdf},"","");
   }
   else{
      PDF_end_page($self->{pdf});
   }
   PDF_begin_page_ext($self->{pdf}, $self->{_Layout}->{width}, 
                      $self->{_Layout}->{height}, "topdown");
   if ($param{'headerval'} ne ""){
      PDF_create_bookmark($self->{pdf},$param{'headerval'},"");
   }
   $self->{_PPos}=0;
   if (ref($self->{_Layout}->{template}) eq "CODE"){
      &{$self->{_Layout}->{template}}($self);
   }
}

sub _PDFcolor
{
   my $self=shift;
   my $color=shift;
   my ($r,$g,$b)=$self->SUPER::Color(color=>$color);
   return($r,$g,$b);
}

sub TextOut
{
   my ($self,$x,$y,$text,%param)=@_;
   if (!defined($param{bold}))
   {
      $param{bold}=0;
   }
   $x=0                if (!defined($x));
   $y=$self->GetPPos() if (!defined($y));
   my $textparam=$self->_parseTextOutParam(\%param);
   my ($r,$g,$b)=$self->_PDFcolor($param{color});
   PDF_setcolor($self->{pdf},"both","rgb",$r/255,$g/255,$b/255,0);
   my $fontname=$self->_PDFfindFontName($textparam);
   $self->{PDF}->{fh}=PDF_load_font($self->{pdf},$fontname,'auto','');
   PDF_fit_textline($self->{pdf},$text,$x,$y,
                    "font=$self->{PDF}->{fh} fontsize=$textparam->{fontsize}");
#   printf STDERR ("fifi_2 %s - %s\n",$text);
#   }else{
#      $self->{PDF}->{fh}=PDF_load_font($self->{pdf},'Courier','auto','');
#      PDF_setfont($self->{pdf},$self->{_PDF}->{fh}, $textparam->{fontsize});
#      PDF_set_text_pos($self->{pdf},$x,$y);
#      PDF_show($self->{pdf},$text);
#   printf STDERR ("fifi_3 %s - %s\n",$text);
#   }
#   return(1);
}

sub _PDFfindFontName
{
   my ($self,$textparam)=@_;
   my $fn=lc($textparam->{font});
   $fn="Helvetica" if ($fn eq "helvetica");
   $fn="Courier"  if ($fn eq "courier");
   my $fext="";
   if ($textparam->{bold} && !$textparam->{italic}){
      $fext="-Bold";
   }
   if (!$textparam->{bold} && $textparam->{italic}){
      $fext="-Oblique";
   }
   if ($textparam->{bold} && $textparam->{italic}){
      $fext="-BoldOblique";
   }
   return($fn.$fext);
}

sub TextDimension
{
   my ($self,$text,%param)=@_;
   my $textparam=$self->_parseTextOutParam(\%param);
   my $fontname=$self->_PDFfindFontName($textparam);
   if (!defined($self->{PDF}->{fh})){
      $self->{PDF}->{fh}=PDF_load_font($self->{pdf},$fontname,'auto','');
   }
   my $width=PDF_stringwidth($self->{pdf},$text,
                             $self->{_PDF}->{fh},$textparam->{fontsize});
   my $height=$textparam->{fontsize};
   return($width,$height);
}

sub Line
{
   my ($self,$x1,$y1,$x2,$y2,%param)=@_;
   $param{color}="black" if (!defined($param{color}));
   $param{width}=1       if (!defined($param{width}));
   $param{style}="solid" if (!defined($param{style}));
   my ($r,$g,$b)=$self->Color(color=>$param{color});
   PDF_setlinewidth($self->{pdf},$param{width});
   PDF_setrgbcolor($self->{pdf},$r/255,$g/255,$b/255);
   PDF_moveto($self->{pdf},$x1,$y1);
   PDF_lineto($self->{pdf},$x2,$y2);
   PDF_stroke($self->{pdf});
}

sub Rec
{
   my ($self,$x1,$y1,$x2,$y2,%param)=@_;

   $param{color}="black" if (!defined($param{color}));
   $param{width}=1       if (!defined($param{width}));
   $param{filled}=0      if (!defined($param{filled}));
   my ($r,$g,$b)=$self->Color(color=>$param{color});
   PDF_setlinewidth($self->{pdf},$param{width});
   PDF_setrgbcolor($self->{pdf},$r/255,$g/255,$b/255);

   my ($xx1,$yy1,$xx2,$yy2)=($x1,$y1,$x2,$y2);
   
   if ($xx1>$xx2){
      my $t=$xx2;
      $xx2=$xx1;
      $xx1=$t;
   }
   if ($yy1<$yy2){
      my $t=$yy2;
      $yy2=$yy1;
      $yy1=$t;
   }
   PDF_rect($self->{pdf},$xx1,$yy1,$xx2-$xx1,$yy1-$yy2);
   if ($param{filled}){
      PDF_fill_stroke($self->{pdf});
   }
   else{
      PDF_stroke($self->{pdf});
   }
}



# after here code is obsolete, was the first try

sub Begin 
{
   my ($self,$filename,%param)=@_;
   PDF_begin_document($self->{pdf},"$filename","");
   PDF_set_info($self->{pdf},"Subject",$param{subject});
   PDF_set_info($self->{pdf},"Title", $param{title});
   PDF_set_info($self->{pdf},"Creator",$param{creator});
   PDF_set_info($self->{pdf},"Author",$param{author});
}

sub TextPrint
{
   my ($self,$text,$xmin,$ymin,$xmax,$ymax,%param)=@_;
   my ($var,$pos,$curtext,$cols,$textwidth);
   my ($r,$g,$b)=$self->TextOut(x=>$xmin,y=>$ymin,text=>$text,%param);
   PDF_setcolor($self->{pdf},"both","rgb",$r/255,$g/255,$b/255,0);
   $self->{fh}=PDF_load_font($self->{pdf},$self->{_Text}->{font},'auto','');
   PDF_setfont($self->{pdf},$self->{fh}, $self->{_Text}->{fontsize});
   PDF_set_text_pos($self->{pdf},$self->{_Text}->{x},
                    $self->{_Text}->{y}+$self->{_Text}->{fontsize});
#  my $fsize=PDF_stringwidth($self->{pdf},$text,$param{fontname},$self->{_Text}->{fontsize});
   $self->{_Pdfshow}=1;
   $textwidth=$self->TextDimension($text,$xmax,$ymax,%param);
   if(defined($param{cols}) && ($param{width}*$param{cols})<$textwidth){
     $cols=$param{cols}; 
     $self->{_Curcol}=1;
     $textwidth=$textwidth/$cols-$self->{_Text}->{fontsize}; 
   }elsif(defined($param{cols})){
     $cols=$param{cols}; 
     $self->{_Curcol}=1;
     $textwidth=$textwidth/$cols-$self->{_Text}->{fontsize}; 
   }
#  if(($self->{_Text}->{x}+$fsize)>$xmax){
    $text=$text." ";
    do{
      my $befpos=$pos;
      $pos=pos($text); 
      $curtext=substr($text,0,$pos); 
      if($textwidth<PDF_stringwidth($self->{pdf},$curtext,
                                    $param{fontname},$self->{_Text}->{fontsize})){
        my $beftext=substr($text,0,$befpos);
        if(PDF_stringwidth($self->{pdf},$beftext,
                           $param{fontname},$self->{_Text}->{fontsize})>$textwidth){
          my $i;
          while(PDF_stringwidth($self->{pdf},substr($beftext,0,$i),
                                $param{fontname},
                                $self->{_Text}->{fontsize})<$textwidth){
            $i++; 
          }
          $self->_CheckNew_Col_or_Page($xmin,$ymin,$xmax,
                                       $ymax,$param{color},cols=>$cols);
          if($self->{_Pdfshow} eq 1){
            PDF_show($self->{pdf},substr($beftext,0,$i-1));
            $self->{_Pdfshow}=0;
          }else{
            $beftext=~ s/^ //;
            PDF_continue_text($self->{pdf},substr($beftext,0,$i-1));
          }
          $text=substr($text,$i-1,length($text));
        }else{
          $self->_CheckNew_Col_or_Page($xmin,$ymin,$xmax,$ymax,
                                       $param{color},cols=>$cols);
          if($self->{_Pdfshow} eq 1){
            $beftext=~ s/^ //;
            PDF_show($self->{pdf},$beftext);
            $self->{_Pdfshow}=0;
          }else{
            $beftext=~ s/^ //;
            PDF_continue_text($self->{pdf},$beftext);
          }
          $text=substr($text,$befpos,length($text));
        }
      }
    }while($text=~/[_!\?\.=,\ ;:\+-]/g);
    $self->_CheckNew_Col_or_Page($xmin,$ymin,$xmax,
                                 $ymax,$param{color},cols=>$cols);
    $curtext=~ s/^ //;
    PDF_continue_text($self->{pdf},$curtext);
#  }else{
#    $self->_CheckNew_Col_or_Page($xmin,$ymin,$xmax,$ymax,$param{color},cols=>$cols);
#    PDF_show($self->{pdf},$text);
#  }
}


sub _CheckNew_Col_or_Page
{
  my ($self,$xmin,$ymin,$xmax,$ymax,$color,%param)=@_;
  my $texty=PDF_get_value($self->{pdf},'texty',0);
  if($ymax<=($texty+$self->{_Text}->{fontsize})){
    if(defined($param{cols}) && $param{cols}>$self->{_Curcol}){
      $self->{_Text}->{x}=((($xmax-($self->{_Layout}->{border}*2))/
                             $param{cols})*$self->{_Curcol});
      PDF_set_text_pos($self->{pdf},$self->{_Text}->{x},
                       $self->{_Text}->{y}+$self->{_Text}->{fontsize});
      $self->{_Curcol}++;
      $self->{_Pdfshow}=1;
    }else{
      $self->EndPage();
      $self->NewPage(width=>$self->{_Layout}->{width},
                     height=>$self->{_Layout}->{height});
      PDF_setcolor($self->{pdf},"both","rgb",$self->{_Text}->{color}->[0]/255,
                                             $self->{_Text}->{color}->[1]/255,
                                             $self->{_Text}->{color}->[2]/255,0);
      PDF_setfont($self->{pdf},$self->{fh}, $self->{_Text}->{fontsize});
      PDF_set_text_pos($self->{pdf},$xmin,$ymin+$self->{_Text}->{fontsize});
      $self->{_Curcol}=1;
      $self->{_Pdfshow}=1;
    }
  }
}

sub Image 
{
   my ($self,$imagetype,$filename,$x,$y,%param)=@_;
   my $img=PDF_load_image($self->{pdf},$imagetype,$filename,'');
   PDF_fit_image($self->{pdf},$img,$x,$y,'');
}

1;
