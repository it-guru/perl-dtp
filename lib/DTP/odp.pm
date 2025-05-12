package DTP::odp;
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
use OpenOffice::OODoc;
use Data::Dumper;
use DTP;
use DTP::GD;
use File::Temp("tempfile");


@ISA=qw(DTP);

sub new
{ 
   my $type=shift;
   my $self={@_};

   $self=$type->SUPER::new(%$self);
   bless($self,$type);

   #tempfile (original document)
   my ($fh,$filename)=tempfile();
   $self->{'_TEMPF'}=$filename;

   return($self);
}


sub GetDocument
{
   my ($self,$filename)=@_;

   _WriteStyles($self);
   $self->{'_ODP'}->save;

   # read temp-file, and write presentation-file
   if (open(IN,'<',$self->{_TEMPF})){
      binmode(IN);
      if ($filename eq "")
      {
        $filename=sprintf($self->{_Layout}->{tempfile},1);
        $filename.=".odp";
      }
      if (!open(FH,">$filename")){
         printf STDERR ("ERROR: can't open $filename\n");
         return(undef);
      }
      binmode(FH);
      print FH (join("",<IN>));
      close(FH);
      unlink($self->{'_TEMPF'});
      printf("INFO: created file=%s\n",$filename);
   }
   return(1);
}

sub NewPage
{
   my ($self,%param)=@_;
   $self->_storeLayoutParameter(%param);

   if (defined($self->{'_ODP'})){
      # initialize secound to last slide
      my $pagenr=$self->{'_PAGENR'}+1;
      my $slide=$self->{'_ODP'}->insertDrawPage(
         $self->{'_SLIDE'},
         "name"      => "page$pagenr",  
         "style"     => "dp1",
         "master"    => "Standard",
         "position"  => "after",
         attributes  => {
            "presentation:presentation-page-layout-name"   => "AL1T1"
         }
      );

      $self->{'_SLIDE'}=$slide;
      $self->{'_PAGENR'}=$pagenr;
   }
   else{
      # create object and initialize first slide
      my $doc = odfDocument(
         file     => $self->{'_TEMPF'},
         create   => 'presentation'
      );
      my $slide=$doc->selectDrawPageByName("page1");

      #create standard-styles
      $doc->updateStyle(
         "dp1",
         family      => "drawing-page",
         properties  => {
            "presentation:background-visible"   => "true",
            "presentation:background-objects-visible" => "true",
            "presentation:display-footer"       => "true",
            "presentation:display-page-number"  => "false",
            "presentation:display-date-time"    => "true"
         }   
      );
      $doc->updateStyle(
         "dp2",
         family      => "drawing-page",
         properties  => {
            "presentation:display-header"       => "true",
            "presentation:display-footer"       => "true",
            "presentation:display-page-number"  => "false",
            "presentation:display-date-time"    => "true"
         }   
      );

      # additional for powerpoint-compatibility
      my $notes = $doc->selectChildElementByName($slide,'presentation:notes');
      $doc->removeElement($notes);

      $self->{'_ODP'}=$doc;
      $self->{'_SLIDE'}=$slide;
      $self->{'_PAGENR'}=1;
   }

   $self->{'_PPos'}=0;
   if (ref($self->{_Layout}->{template}) eq "CODE"){
      &{$self->{_Layout}->{template}}($self);
   }
}

sub Line
{
   my ($self,$x1,$y1,$x2,$y2,%param)=@_;

   $param{color}="black"   if(!defined($param{color}));
   $param{width}=0         if(!defined($param{width}));
   # maybe line-style,..

   my ($r,$g,$b)=$self->Color(color=>$param{color});
   # convert color to hexcode
   $param{color}="#".sprintf("%2.2x",$r).sprintf("%2.2x",$g).sprintf("%2.2x",$b);

   my $stylename=_GetStyleNameByDef($self,"gr",color=>$param{color},width=>$param{width});
   $self->{'_ODP'}->appendElement(
      $self->{'_SLIDE'},
      "draw:line",
      attributes  => {
      "draw:style-name" => $stylename,
      "draw:text-style-name" => "P1",
      "draw:layer"      => "layout",
      "svg:x1"          => _GetPPTMetrics($self,$x1,"x")."cm",
      "svg:y1"          => _GetPPTMetrics($self,$y1,"y")."cm",
      "svg:x2"          => _GetPPTMetrics($self,$x2,"x")."cm",
      "svg:y2"          => _GetPPTMetrics($self,$y2,"y")."cm"
      }
   );
}

sub TextOut
{
   my ($self,$x,$y,$text,%param)=@_;
   my $doc = $self->{'_ODP'};
   $param{fontsize}="12"   if(!defined($param{fontsize}));
   $param{color}="black"   if(!defined($param{color}));
   $param{font}="Arial"   if(!defined($param{font}));

   my ($r,$g,$b)=$self->Color(color=>$param{color});
   # convert color to hexcode
   $param{color}="#".sprintf("%2.2x",$r).sprintf("%2.2x",$g).sprintf("%2.2x",$b);
   my $grstylename=_GetStyleNameByDef($self,"txtgr");
   my $pstylename=_GetStyleNameByDef($self,"txtp",color=>$param{color},fontsize=>$param{fontsize},font=>$param{font});
   my $tstylename=_GetStyleNameByDef($self,"txtt",color=>$param{color},fontsize=>$param{fontsize},font=>$param{font});

   # load (or calculate) text-dimensions
   my %dimensionCache=%{$self->{'dimCache'}};
   my ($width,$height);
   if(exists($dimensionCache{qq($param{font};$param{fontsize};$text)})) {
      my %thisdim=%{$dimensionCache{qq($param{font};$param{fontsize};$text)}}; 
      $width=$thisdim{width};
      $height=$thisdim{height};
   }
   else {
      ($width,$height)=TextDimension($self,$text,%param);
   }

   my $frame = $doc->appendElement(
      $self->{'_SLIDE'},
      "draw:frame",
      attributes => {
         "draw:style-name" => $grstylename,
         "draw:text-style-name"  => $pstylename,
         "draw:layer"      => "layout",
         "svg:width"       => _GetPPTMetrics($self,$width)."cm",
         "svg:height"      => _GetPPTMetrics($self,$height)."cm",
         "svg:x"           => _GetPPTMetrics($self,$x,"x")."cm",
         "svg:y"           => _GetPPTMetrics($self,$y-$height,"y")."cm"
      }
   );
   my $textbox = $doc->appendElement(
      $frame,
      "draw:text-box"
   );
   my $p = $doc->appendElement(
      $textbox,
      "text:p",
      attributes     => {
         "text:style-name" => $pstylename
      }
   );
   $doc->appendElement(
      $p,
      "text:span",
      text  => $text,
      attributes  => {
         "text:style-name" => $tstylename
     }
   );
}

sub _GetPPTMetrics
{
   my $self=shift;
   my $oldmetric=shift;
   my $coordtype=shift;
   my $templatewidth=$self->{_Layout}->{width};
   my $templateheight=$self->{_Layout}->{height};

   my $faktor;
   my $layout;
   # select used format and set factor for conversion
   if($templatewidth<$templateheight){
      $layout="potrait";
      $faktor=$templateheight/21;
   }
   else{
      $layout="landscape";
      $faktor=$templatewidth/28;
   }

   my $newmetric = ($oldmetric/$faktor);
   
   # set x-position right when format is potrait
   if($layout eq "potrait"){
      if($coordtype eq "x"){
         $newmetric+=6.58;
      }
   }
   
   return $newmetric;
}

sub TextDimension
{
   my ($self,$text,%param)=@_;

   my $doc=$self->{'_ODP'};
   
   # use gd to get text-dimensions
   my $gd=new GD::Image($self->{_Layout}->{width},
                        $self->{_Layout}->{height});
   my $textparam=$self->_parseTextOutParam(\%param);
   my $fontname=$self->_GDfindFontName($textparam);
   my @dim=$self->_GDstringFT(undef,1,$fontname,$textparam->{fontsize},0.0,0,0,$text);

   # add 15% more for text-width
   my ($width,$height)=(($dim[2]-$dim[0])+($dim[2]*0.15),$dim[1]-$dim[7]);

   # store dimension in cache
   my %dimensionCache;
   if(exists($self->{'dimCache'})) {
      %dimensionCache=%{$self->{'dimCache'}}
   }
   my %dimension;
   $dimension{width}=$width;
   $dimension{height}=$height;
   $dimensionCache{qq($textparam->{font};$textparam->{fontsize};$text)}=\%dimension;
   $self->{'dimCache'}=\%dimensionCache;
   
   return($width,$height);
}
sub _GDstringFT
{
   my $self=shift;
   my $gd=shift;
   if ($gd){
      my @dim=$gd->stringFT(@_);
      return(@dim);
   }
   return(GD::Image->stringFT(@_));
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

sub _GetStyleNameByDef
{
   my $self=shift;
   my $styletype=shift;
   my %styledef=@_;
   my $styles=$self->{'_STYLES'};

   # create stylekey for current style
   my $stylekey=join("|",
               map({
                  "$_".$styledef{$_}
               } sort(keys(%styledef)))); 

   my $name;
   if(!defined($styles)) {
      $styles={byname=>{},byvalue=>{}};
   }
   if(!defined($styles->{byvalue}->{$styletype})) {
      $styles->{byvalue}->{$styletype}={};
   }
   # use existing style, or create new
   if(exists($styles->{byvalue}->{$styletype}->{$stylekey})) {
      $name=$styles->{byvalue}->{$styletype}->{$stylekey}->{name};
   }
   else {
      $name="Style".$styletype.sprintf("%03d",keys(%{$styles->{byvalue}->{$styletype}})+1);
      $styledef{name}=$name;
      $styles->{byvalue}->{$styletype}->{$stylekey}=\%styledef;
      $styles->{byname}->{$styletype}->{$name}=\%styledef;

   }

   $self->{'_STYLES'}=$styles;

   return($name);
}

sub _WriteStyles
{
   my $self=shift;
   my %styles=%{$self->{'_STYLES'}->{byvalue}};
   my $doc=$self->{'_ODP'};

   foreach my $styletype (keys(%styles)) {
      foreach my $typedef (keys(%{$styles{$styletype}})) {
         foreach my $stylekey (keys(%{$styles{$styletype}{$typedef}})) {
            my %style=%{$styles{$styletype}{$typedef}};
            if($stylekey eq "name") {           # filter style-names
               if($styletype eq "dp") {         # if styletype is drawing-page
               }
               elsif($styletype eq "gr") {      # if styletype is graphic
                  my %properties=(
                     "draw:textarea-horizontal-align"      => "center",
                     "draw:textarea-vertical-align"        => "middle"
                  );
                  if (defined($style{width}) && $style{width} != 0) {
                     $properties{'svg:stroke-width'}=($style{width}/100).'cm';
                     $properties{'draw:marker-start-width'}='0.75cm';
                     $properties{'draw:marker-end-width'}='0.75cm';
                     $properties{'fo:padding-top'}='0.275cm';
                     $properties{'fo:padding-bottom'}='0.275cm';
                     $properties{'fo:padding-left'}='0.4cm';
                     $properties{'fo:padding-right'}='0.4cm';
                     
                  }
                  if (defined($style{color})) {
                     $properties{'svg:stroke-color'}=$style{color};
                  }

                  $doc->createStyle(
                     $style{name},
                     family      => "graphic",
                     parent      => "standard",
                     properties  => \%properties
                  );
               }
               elsif($styletype eq "txtgr") {      # if stletype is graphic (text)
                  $doc->createStyle(
                     $style{name},
                     family      => "graphic",
                     parent      => "standard",
                     properties  => {
                        "draw:stroke"        => "none",
                        "svg:stroke-color"   => "#000000",
                        "draw:fill"          => "none",
                        "draw:fill-color"    => "#ffffff",
                        "draw:textarea-horizontal-align" => "left",
                        "draw:auto-grow-height" => "true",
                        "draw:auto-grow-width"  => "true",
                        "fo:min-height"   => "0cm",
                        "fo:min-width"    => "0cm",
                        "fo:padding-top" => "0cm",
                        "fo:padding-bottom" => "0cm",
                        "fo:padding-left" => "0cm",
                        "fo:padding-right" => "0cm",
                     }
                  );
               }
               elsif($styletype eq "txtp") {      # if styletype is paragraph
                  my %properties=(
                        "fo:color"  => $style{color},
                        "fo:font-family"  => $style{font},
                        "style:font-family-generic"   => "swiss",
                        "style:font-pitch"   => "variable"
                  );

                  if (defined($style{fontsize})) {
                     $properties{'fo:font-size'}=$style{fontsize}."pt";
                     $properties{'style:font-size-asian'}=$style{fontsize}."pt";
                     $properties{'style:font-size-complex'}=$style{fontsize}."pt";
                  }

                  $doc->createStyle(
                     $style{name},
                     family      => "paragraph",
                     properties  => \%properties
                  );
               }
               elsif($styletype eq "txtt") {      # if styletype is text
                  my %properties=(
                        "fo:color"  => $style{color},
                        "fo:font-family"  => $style{font},
                        "style:font-family-generic"   => "swiss",
                        "style:font-pitch"   => "variable"
                  );

                  if (defined($style{fontsize})) {
                     $properties{'fo:font-size'}=$style{fontsize}."pt";
                     $properties{'style:font-size-asian'}=$style{fontsize}."pt";
                     $properties{'style:font-size-complex'}=$style{fontsize}."pt";
                  }

                  $doc->createStyle(
                     $style{name},
                     family      => "text",
                     properties  => \%properties
                  );
               }
               else {
                  print STDERR ("Style not defined: $styletype");
               }
            }
         }
      }
   }
}


1;
