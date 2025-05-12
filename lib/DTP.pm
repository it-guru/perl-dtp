package DTP;
#  a Perl module for Desktop Publishing 
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
use UNIVERSAL;
use vars(qw(@ISA $VERSION));
use Data::Dumper;
use DTP::Entity;

$VERSION="0.0.1";
@ISA=qw(UNIVERSAL);


=pod

=head1 NAME

DTP - Perl module to create simple various document typs

=head1 DESCRIPTION

DTP.pm is a wrapper module that allows easy generation of documents like pdf, jpg, gif within perl.
All colors are specified als name (f.e. "black","red",...) or as array of
three 0-255 numbers (RGB).

=head1 CONSTRUCTOR

=over

=item new()

 my $dtp=new DTP();

B<Constructor to create the DTP object.>

=back

=cut

sub new
{
   my $type=shift;
   my $self={};
   if ($#_==0){
      eval("use DTP::$_[0];");
      die($@) if ($@ ne "");
      my $obj;
      eval('$obj=new DTP::'.$_[0].'();');
      die($@) if ($@ ne "");
      return($obj);
   }
   bless($self,$type);
   $self->_storeLayoutParameter(format=>'A4',template=>\&_DefaultPageTemplate);
   $self->{_Page}=0;
   $self->{_PPos}=0;
   return($self);
}

sub _storeLayoutParameter
{
   my ($self,%param)=@_;
   if (defined($param{format}) && 
       (defined($param{width}) || defined($param{height}))){
      die("_storeLayoutParameter ERROR: format and width/height couldn't be".
          " defined at the same call");
   }
   if (exists($param{format})){
      if ($param{format} eq "A4landscape"){
         $param{width} =842;
         $param{height}=595;
      }
      if ($param{format} eq "A4"){
         $param{width} =595;
         $param{height}=842;
      }
      delete($param{format});
   }
   $self->{_Layout}={} if (!defined($self->{_Layout}));
   foreach my $p (qw(width height border punchborder template)){
     $self->{_Layout}->{$p}=$param{$p} if (exists($param{$p}));
   }
   # default Values
   $self->{_Layout}->{width}=595  if (!defined($self->{_Layout}->{width}));
   $self->{_Layout}->{height}=842 if (!defined($self->{_Layout}->{height}));
   $self->{_Layout}->{border}=10  if (!defined($self->{_Layout}->{border}));
   if (!defined($self->{_Layout}->{punchborder})){
      $self->{_Layout}->{punchborder}=25;
   }
   if (!defined($self->{_Layout}->{tempfile})){
      $self->{_Layout}->{tempfile}='/tmp/doc%04d';
   }
}

sub _DefaultPageTemplate
{
   my $self=shift;
   my ($xmin,$ymin,$xmax,$ymax)=$self->Workspace();
   $self->Rec($xmin,$ymin,$xmax,$ymax);
   $self->SetPPos($ymin+3); # some pixel space to the border
}


=pod

=head1 Low-Level METHODS

=over

=item Line()

 $dtp->Line($x1,$y1,$x2,$y2,(width => 1,
                             style => "solid"|"dotted",
                             color => "black" ));

draw a line in the document

=back

=cut

sub Line
{
   my ($self,$x1,$y1,$x2,$y2,%param)=@_;
   die("Method: Line not not implemented");
}


=pod

=over

=item TextOut()

 $dtp->TextOut($x,$y,$text,(
                            font       => "Courier"|"Helvetica",
                            fontsize   => 10;
                            underline  => 1|0,
                            italic     => 1|0,
                            bold       => 1|0,
                            color      => [0,0,0]));

This method writes extreme simple a text to the document. No wrapping 
,newline handling or page wrapping is done.
If $x is undef, 0+border is used. If $y is undef, the current ppos is
used. PPos isn't modified.

=back

=cut

sub TextOut
{
   my ($self,$x,$y,$text,%param)=@_;
   die("Method: Line not not implemented");
}

sub _parseTextOutParam
{
   my ($self,$param)=@_;

   my %p=%$param;
   $self->{_TextOutParam}={} if (!defined($self->{_TextOutParam}));
   foreach my $pn (qw(color italic bold underline fontsize font)){
      if (exists($p{$pn})){
         $self->{_TextOutParam}->{$pn}=$p{$pn};
         delete($p{$pn});
      }
   }
   if (keys(%p)){
      die("ERROR: invalid param ".join(",",keys(%p))." in TextOut");
   }
   foreach my $pn (qw(italic bold underline)){
      if (!defined($self->{_TextOutParam}->{$pn})){
         $self->{_TextOutParam}->{$pn}=0;
      }
   }
   if (!defined($self->{_TextOutParam}->{color})){
      $self->{_TextOutParam}->{color}="black";
   }
   if (!defined($self->{_TextOutParam}->{fontsize})){
      $self->{_TextOutParam}->{fontsize}=10;
   }
   if (!defined($self->{_TextOutParam}->{font})){
      $self->{_TextOutParam}->{font}="Helvetica";
   }
   return($self->{_TextOutParam});
}

sub Textout   # Holm's construct - deprecate
{
   my ($self,%param)=@_;
   # text position
   if(!defined($self->{_Text}->{x}=$param{x})){
     $self->{_Text}->{x}=$self->{_Layout}->{border};
   }
   $self->{_Text}->{y}=$param{y} if(defined($param{y}));

   # text format
   if(!defined($self->{_Text}->{font}=$param{font})){
     $self->{_Text}->{font}='Helvetica';
   }
   if(!defined($self->{_Text}->{fontsize}=$param{fontsize})){
     $self->{_Text}->{fontsize}='10';
   }
   foreach my $p (qw(underline italic bold)){
     if ($param{$p}){
        $self->{_Text}->{$p}=1;
     }
     else{
        $self->{_Text}->{$p}=1;
     }
   }
  

  # text color
  my ($r,$g,$b)=$self->Color(color=>$param{color});
  return($r,$g,$b);
}


=pod

=over

=item Color()

 $dtp->Color((color => 'black'));

Format written color like "black" in RGB Format or set the default color

=back

=cut

sub Color
{
  my ($self,%param)=@_;
  my ($r,$g,$b)=(255,255,255);
  if(defined($param{color}) && ref($param{color}) eq 'ARRAY'){  
    ($r,$g,$b)=@{$param{color}};
  }elsif(defined($param{color})){  
    if($param{color} eq 'black'){
       ($r,$g,$b)=(0,0,0);
    }
    elsif($param{color} eq 'white'){
       ($r,$g,$b)=(255,255,255);
    }
    elsif($param{color} eq 'red'){
       ($r,$g,$b)=(255,0,0);
    }
    elsif($param{color} eq 'green'){
       ($r,$g,$b)=(0,255,0);
    }
    elsif($param{color} eq 'yellow'){
       ($r,$g,$b)=(255,255,0);
    }
    elsif($param{color} eq 'blue'){
       ($r,$g,$b)=(0,0,225);
    }
    else{
       if (!defined($self->{_ColorTable})){
          my @rgb=("/etc/X11");
          push(@rgb,map({"$_/DTP/colors"} @INC));
          $self->{_ColorTable}={};
          foreach my $rgbdir (@rgb){
             my $rgbfile="$rgbdir/rgb.txt";
             if (-r $rgbfile){
                if (open(F,"<$rgbfile")){
                   while(my $line=<F>){
                      $line=~s/\s*$//;
                      $line=~s/^\s*//;
                      if (my ($lr,$lg,$lb,$name)=
                             $line=~m/^(\d+)\s+(\d+)\s+(\d+)\s+(.*)$/){
                         $self->{_ColorTable}->{lc($name)}=[$lr,$lg,$lb];
                      }
                   }
                   close(F);
                }
             }
          }
       }
       if (exists($self->{_ColorTable}->{lc($param{color})})){
          return(@{$self->{_ColorTable}->{lc($param{color})}});
       }
    }
  }else{
    ($r,$g,$b)=(0,0,0);
  }
  return($r,$g,$b);
}


=pod

=over


=item Image()

 $dtp->Image($x,$y,$filename,$type,(border  => 0,
                                    padding => 0 ));

Places a image in the document. If $y is not specified (undef), the current
PPos is used (see GetPPos and SetPPos). If $x is not specifed (undef), the
first useable x position is used (f.e. 0+border from NewPage)

=back

=cut

sub Image
{
  my ($self,$x,$y,$filename,$type,%param)=@_;
  die("Method: Image not not implemented");
}


=pod

=over

=item NewPage()

 $dtp->NewPage(param);

Initialize a new page. You can specifiy some parameters. If you didn't
specifiy one, the value of the parameter of the last NewPage command is
used. If there is no previous NewPage command (f.e. at the first page) the
following defaults are used:

 width=595
 height=842
 template=undef
 border=10
 punchborder=25
 tempfile='/tmp/doc%04d'

These are also the posibles parameters, too. If a NewPage call is done, the
current page is closed - soo an EndPage method isn't needed (and not defined).

=back

=cut

sub NewPage
{
  my ($self,%param)=@_;
  die("Method: NewPage not implemented");
}


=pod

=over

=item GetPage()

 $dtp->GetPage();

Returs the current pagenumber starting with 0 as the first page.

=back

=cut

sub GetPage
{
  my ($self,%param)=@_;
  die("Method: GetPage not implemented");
}


=pod

=over

=item SetPPos(Y)

Set's the current Y Position in the current page. The x=0 and y=0 is in
the left upper corner.

=back

=cut

sub SetPPos
{
   my ($self,$newpos)=@_;
   return($self->{_PPos}=$newpos);
}

=pod

=over

=item GetPPos()

Returns the current Y postion on the current page. 

=back

=cut

sub GetPPos
{
   my ($self)=@_;
   return($self->{_PPos});
}

=pod

=over

=item GetDocument(MODE)

Returns the resulting document(s). MODE can be AS_HANDLE or AS_FILE. If
you specify AS_HANDLE directly the tempoary filenames are returned.

=back

=cut

sub GetDocument
{
  my ($self,$mode)=@_;
  die("Method: GetDocument not implemented");
}
#
# Defins for the Result method
#
sub AS_HANDLE { return(0); }
sub AS_FILE   { return(1); }


=pod

=over

=item TextDimension("txt",param)

Returns in array context (width,height). In scalar context only
the width of the text is returned. All parameters of TextOut are
useable.

=back

=cut

sub TextDimension
{
   my ($self,%param)=@_;
   die("Method: TextDimension not implemented");
}

=pod

=over

=item Fill()

fill a area

=back

=cut

sub Fill
{
  my ($self,%param)=@_;
  die("Method: Fill not implemented");
}

=pod

=over

=item Circle()

draw a circle

=back

=cut

sub Circle
{
  my ($self,%param)=@_;
  die("Method: Circle not implemented");
}

=pod

=head1 Height-Level METHODS

=over

=item Chart()

draw a chart

=back

=cut

sub Chart
{
  my ($self,%param)=@_;
  die("Method: Chart not implemented");
}

=pod

=over

=item Rec($x1,$y1,$x2,$y2,
                          (color=>'black',
                           width=>1,
                           filled=>0
                          )

draw a rectangle

=back

=cut

sub Rec
{
  my ($self,$x1,$y1,$x2,$y2,%param)=@_;
  $param{color}="black" if (!defined($param{color}));
  $param{style}="solid" if (!defined($param{style}));
  $param{width}=1       if (!defined($param{width}));
  $param{filled}=0      if (!defined($param{filled}));
  my %lparam=%param;
  delete($lparam{filled});
  if ($param{filled}){
     if ($x1<$x2){
        for(my $x=$x1;$x<=$x2;$x++){
           $self->Line($x,$y1,$x,$y2,%lparam);
        }
     }
     else{
        for(my $x=$x2;$x>=$x1;$x--){
           $self->Line($x,$y1,$x,$y2,%lparam);
        }
     }
  }
  $self->Line($x1,$y1,$x2,$y1,%lparam);
  $self->Line($x1,$y2,$x2,$y2,%lparam);
  $self->Line($x1,$y1,$x1,$y2,%lparam);
  $self->Line($x2,$y1,$x2,$y2,%lparam);
}

=pod

=over

=item WriteLine([text],%param)
 
  Parameters:
 
  font       => ["Courier"|"Helvetica"],
  fontsize   => 10;
  underline  => [1|0],
  italic     => [1|0],
  bold       => [1|0],
  border     => [1],
  bordercolor=> ["red"],
  width      => [1],
  minheight  => 10,
  background => ["gray"],
  padding    => [0],
  margin     => 0,
  color      => [[0,0,0]]

Writes a "pack" of text starting from the current ppos

=back

=cut

sub WriteLine
{
   my ($self,$text,%INparam)=@_;
   my ($xmin,$ymin,$xmax,$ymax)=$self->Workspace();
   my %param=();
   my @direction=qw(left right top bottom);

   #
   # Pass1 : genereate default parameters
   #
   $text=[$text] if (ref($text) ne "ARRAY");
   $INparam{fontsize}=10      if (!exists($INparam{fontsize}));
   if (!exists($INparam{linespace})){
      $INparam{linespace}=int($INparam{fontsize}*0.2);
   }
   $INparam{align}='left'     if (!exists($INparam{align}));
   $INparam{padding}=5        if (!exists($INparam{padding}));
   $INparam{'margin-left'}=5  if (!exists($INparam{'margin-left'}) &&
                                  !exists($INparam{margin}));
   $INparam{'margin-right'}=5 if (!exists($INparam{'margin-right'}) &&
                                  !exists($INparam{margin}));
   $INparam{margin}=0         if (!exists($INparam{margin}));
   $INparam{color}="black"    if (!exists($INparam{color}));
   foreach my $p0 (qw(underline italic bold border padding margin)){
      $INparam{$p0}=0  if (!exists($INparam{$p0}));
   }
   my $maxcol=$#{$text};
   foreach my $direction (@direction){
      if (exists($INparam{"margin-$direction"})){
         $param{"margin-$direction"}=$INparam{"margin-$direction"};
      }
      if (!defined($param{"margin-$direction"})){
         $param{"margin-$direction"}=$INparam{margin};
      }
   }

   #
   # Pass2 : distribute variables to all columns
   #
   my @directionvars=qw(padding border);
   my @varnames=qw(font fontsize underline linespace color background
                   italic bold align bordercolor width minheight maxheight);
   push(@varnames,@directionvars);
   foreach my $basen (@directionvars){
      foreach my $direction (@direction){
         push(@varnames,"$basen-$direction");
      }
   }
   foreach my $pn (@varnames){
      if (exists($INparam{$pn})){
         if (ref($INparam{$pn}) ne "ARRAY"){
            my $l=[];
            for(my $c=0;$c<=$maxcol;$c++){push(@$l,$INparam{$pn})}
            $param{$pn}=$l;
         }
         else{
            $param{$pn}=$INparam{$pn};
         }
      }
   }
   foreach my $basen (@directionvars){
      for(my $col=0;$col<=$maxcol;$col++){
         if (defined($param{$basen}->[$col])){
            foreach my $direction (@direction){
               if (!defined($param{"$basen-$direction"}->[$col])){
                  $param{"$basen-$direction"}->[$col]  =$param{$basen}->[$col];
               }
            }
         }
      }
      delete($param{$basen});
   }

   #
   # Pass3 : preprocess text values
   #
   for(my $col=0;$col<=$maxcol;$col++){
      $text->[$col]=[$text->[$col]] if (ref($text->[$col]) ne "ARRAY");
   }

   #
   # Pass4 : calc column widths
   #
   $param{width}=[] if (!defined($param{width}));
   my $definedwidth=0;
   my $definedcolums=0;
   for(my $col=0;$col<=$maxcol;$col++){
      if (defined($param{width}->[$col])){
         $definedwidth+=$param{width}->[$col];
         $definedcolums++;
      }
   }
   my $workwidth=($xmax-$xmin)-$param{"margin-right"}-$param{"margin-left"};
   my $defwidth=($workwidth-$definedwidth)/($maxcol-$definedcolums+1);
   for(my $col=0;$col<=$maxcol;$col++){
      if (!defined($param{width}->[$col])){
         $param{width}->[$col]=$defwidth;
      }
   }

   #
   # Pass5 : wrap text
   #
   my @tp;
   my @linestart;
   my @lineend;
   my @textwidth;
   for(my $col=0;$col<=$maxcol;$col++){
      my @dlines;  # do base wrap on \n characters
      for(my $line=0;$line<=$#{$text->[$col]};$line++){
         if (ref($text->[$col]->[$line])){
            push(@dlines,$text->[$col]->[$line]);
         }
         else{
            push(@dlines,split(/\n/,$text->[$col]->[$line]));
         }
      }
      $text->[$col]=\@dlines;
      $tp[$col]={font     =>$param{font}->[$col],
                 fontsize =>$param{fontsize}->[$col],
                 italic   =>$param{italic}->[$col],
                 bold     =>$param{bold}->[$col],
                 color    =>$param{color}->[$col],
                 underline=>$param{underline}->[$col]};
      # font based wrapping
      my $lline=0;
      while($lline<=$#{$text->[$col]}){
         if (defined($text->[$col]->[$lline]) && 
             !ref($text->[$col]->[$lline]) &&
             length($text->[$col]->[$lline])>0){
            $text->[$col]->[$lline]=~s/\s*$//;
            my ($width)=$self->TextDimension($text->[$col]->[$lline],
                                             %{$tp[$col]});
            $textwidth[$col]->[$lline]=$width;
            my $cellwidth=$param{width}->[$col]-
                          $param{"padding-left"}->[$col]-
                          $param{"padding-right"}->[$col];
            if ($width>$cellwidth){  # need wrap ?
               my $workline=$text->[$col]->[$lline];
               my $maxokchar=int(length($workline)/2);
               my $lastmaxokchar=length($workline);
               my $lastwidth=$width;
               while($maxokchar>1){
                  my $sworkline=substr($workline,0,$maxokchar);
                  my ($width)=$self->TextDimension($sworkline,
                                                   %{$tp[$col]});
                  $textwidth[$col]->[$lline]=$width;
                  my $cur=$maxokchar;
                  my $offset=int(abs($cur-$lastmaxokchar)/2);
                  $offset=1 if ($offset==0);
                  if ($width>$cellwidth){
                     $maxokchar-=$offset;
                  }
                  else{
                     $maxokchar+=$offset;
                  }
                  if ($maxokchar==$lastmaxokchar){
                     last;
                  }
                  $lastmaxokchar=$cur;
                  $lastwidth=$width;
               }
               my $maxokchar_lev0=$maxokchar;
               while($maxokchar>0){
                  last if (substr($workline,0,$maxokchar)=~m/\s$/);
                  $maxokchar--;
               }
               $maxokchar=$maxokchar_lev0 if ($maxokchar<=0);
               my $line1=substr($workline,0,$maxokchar);
               my $line2=substr($workline,$maxokchar);
               my @n=splice(@{$text->[$col]},$lline,999999,$line1,$line2);
               shift(@n); # remove old line
               push(@{$text->[$col]},@n); # add the rest
            }
         }
         $lline++;
      }
      $linestart[$col]=0;
   }

   #
   # Pass6 : print it out
   #
   my $maxy;
   my $pagecount=0;
   my $pagebreakspace=3; # ensure space to the border
   while(1){
      my $y0=$self->GetPPos()+$param{"margin-top"};
      my $x0=$xmin+$param{"margin-left"};
      my $pagebreaked=0; 
      my $curx=$x0;
      $maxy=$y0;
      #
      # calc maxy
      #
      for(my $col=0;$col<=$maxcol;$col++){
         $lineend[$col]=$#{$text->[$col]};
         next if ($lineend[$col]==-1);
         next if ($linestart[$col]>$lineend[$col]); # all is already printed
         if (ref($text->[$col]->[0])){
            my $w=$param{"width"}->[$col]-$param{"padding-left"}->[$col]-
                  $param{"padding-right"}->[$col];
            my $h=$param{"fontsize"}->[$col];
            if (defined($param{"minheight"}->[$col])){
               if ($h<$param{"minheight"}->[$col]){
                  $h=$param{"minheight"}->[$col];
               }
            }
            $text->[$col]->[0]->_setDimension($w,$h);
            ($w,$h)=$text->[$col]->[0]->_getDimension();
            $text->[$col]=[$text->[$col]->[0]];
            my $ychk=$y0+$param{"padding-top"}->[$col]+$h+
                         $param{"padding-bottom"}->[$col];
            if ($maxy<$ychk){
               $maxy=$ychk;
            }
         }
         else{
            my $requestedlines=$lineend[$col]-$linestart[$col];
            my $cury=$y0+$param{"padding-top"}->[$col]+
                     ($param{"linespace"}->[$col]*$requestedlines)+
                     ($param{"fontsize"}->[$col]*($requestedlines+1));
            if ($cury+$param{"padding-bottom"}->[$col]>$ymax-$pagebreakspace){
               my $newmax=int(($ymax-$pagebreakspace-$y0-
                               $param{"padding-top"}->[$col]-
                               $param{"padding-bottom"}->[$col]-
                               $param{"margin-bottom"}-
                               $param{"fontsize"}->[$col])/
                              ($param{"fontsize"}->[$col]+
                               $param{"linespace"}->[$col]));
               if ($newmax>$requestedlines){
                  $newmax=$requestedlines;
               }
               $lineend[$col]=$linestart[$col]+$newmax;
               $cury=$ymax-$pagebreakspace-$param{"padding-bottom"}->[$col]-
                     $param{"margin-bottom"};
               $pagebreaked=1;
               $pagecount++;
            }
            if ($maxy<($cury+$param{"padding-bottom"}->[$col])){
               $maxy=$cury+$param{"padding-bottom"}->[$col];
            }
         }
      }
      #
      # draw borders and background
      #
      for(my $col=0;$col<=$maxcol;$col++){
         if ($param{"background"}->[$col]){
            $self->Rec($curx,$y0,$curx+$param{"width"}->[$col],$maxy,
                        filled=>1,
                        color=>$param{"background"}->[$col]);
         }
         if ($pagecount==0){
            if ($param{"border-top"}->[$col]){
               $self->Line($curx,$y0,$curx+$param{"width"}->[$col],$y0,
                           width=>$param{"border-top"}->[$col],
                           color=>$param{"bordercolor"}->[$col]);
            }
         }
         if ($param{"border-left"}->[$col]){
            $self->Line($curx,$y0,$curx,$maxy,
                        width=>$param{"border-left"}->[$col],
                        color=>$param{"bordercolor"}->[$col]);
         }
         if ($param{"border-right"}->[$col]){
            $self->Line($curx+$param{"width"}->[$col],$y0,
                        $curx+$param{"width"}->[$col],$maxy,
                        width=>$param{"border-right"}->[$col],
                        color=>$param{"bordercolor"}->[$col]);
         }
         if (!$pagebreaked){
            if ($param{"border-bottom"}->[$col]){
               $self->Line($curx,$maxy,$curx+$param{"width"}->[$col],$maxy,
                           width=>$param{"border-bottom"}->[$col],
                           color=>$param{"bordercolor"}->[$col]);
            }
            $pagebreaked=0;
         }
         $curx+=$param{"width"}->[$col];
      }
      #
      # write the text
      #
      my $curx=$x0;
      for(my $col=0;$col<=$maxcol;$col++){
         for(my $line=$linestart[$col];$line<=$lineend[$col];$line++){
            next if (!defined($text->[$col]->[$line]));
            my $cury=$y0+$param{"padding-top"}->[$col]+
                     ($param{"linespace"}->[$col]*($line-$linestart[$col]))+
                     ($param{"fontsize"}->[$col]*(($line-$linestart[$col])+1));
            my $alignoffset=0;
            if (lc($param{"align"}->[$col]) eq 'center'){
               $alignoffset=($param{"width"}->[$col]-
                             $textwidth[$col]->[$line]-
                             $param{"padding-left"}->[$col]-
                             $param{"padding-right"}->[$col])/2;
            }
            elsif(lc($param{"align"}->[$col]) eq 'right'){
               $alignoffset=($param{"width"}->[$col]-
                             $textwidth[$col]->[$line]-
                             $param{"padding-left"}->[$col]-
                             $param{"padding-right"}->[$col]);
            }
            if (ref($text->[$col]->[$line])){
               $text->[$col]->[$line]->Draw($self,
                                        $curx+$param{"padding-left"}->[$col],
                                        $y0+$param{"padding-top"}->[$col]);
            }
            else{
               $self->TextOut($curx+$param{"padding-left"}->[$col]+$alignoffset,
                              $cury,$text->[$col]->[$line],%{$tp[$col]});
            }
         }
         $linestart[$col]=$lineend[$col]+1;
         $curx+=$param{"width"}->[$col];
      }
      if ($pagebreaked){
         $self->SetPPos($maxy);
         $self->NewPage();
         ($xmin,$ymin,$xmax,$ymax)=$self->Workspace();
      }
      else{
         last;
      }
   }
   $self->SetPPos($maxy+$param{"margin-bottom"});
}

=pod

=over

=item Place()

 $dtp->Place($x,$y,$entity,(
                            height=>10,
                            width=>10,
                            border=>0));

Places on derivation of an DTP::Entity element.
A simple way to place an entity in a DTP object, you can do this like
that:

 $dtp->Place(100,100,new DTP::Entity(border=>1));

=back

=cut

sub Place
{
   my ($self,$x,$y,$e,%param)=@_;
   my ($xmin,$ymin,$xmax,$ymax)=$self->Workspace();
   my $ppos=$self->GetPPos();
   my %pparam=%param;

   if (!defined($pparam{"margin-left"}) && !defined($pparam{width})){
      $pparam{"margin-left"}=5;
   }
   if (!defined($pparam{"margin-right"}) && !defined($pparam{margin})){
      $pparam{"margin-right"}=5;
   }
   if (!defined($pparam{"margin-top"}) && !defined($pparam{margin})){
      $pparam{"margin-top"}=3;
   }
   if (!defined($pparam{"margin-bottom"}) && !defined($pparam{margin})){
      $pparam{"margin-bottom"}=3;
   }
   if (!defined($pparam{"margin"})){
      $pparam{"margin"}=0;
   }
   if (defined($pparam{'margin'})){
      foreach my $direct (qw(top left right bottom)){
         next if (defined($pparam{"margin-$direct"}));
         $pparam{"margin-$direct"}=$pparam{'margin'};
      }
   }

   foreach my $v (qw(width height margin margin-left margin-top margin-bottom
                     margin-right)){
      delete($param{$v});
   }
   $ppos+=$pparam{"margin-top"};
   $y=$ppos                                 if (!defined($y));
   $x=$xmin+$pparam{"margin-right"}         if (!defined($x));
   if (!defined($pparam{width})){
      $pparam{width}=$xmax-$pparam{"margin-left"}-$x;
   }
   if (!defined($pparam{height})){
      $pparam{height}=$ymax-$pparam{"margin-bottom"}-$y;
   }

   $e->_setDimension($pparam{width},$pparam{height});

   my $bak=$e->Draw($self,$x,$y,%param);
   $self->SetPPos($y+$pparam{height}+$pparam{"margin-bottom"});
   return($bak);
}

=pod

=over

=item Workspace()

 my ($xmin,$ymin,$xmax,$ymax)=$dtp->Workspace();

Returns ($xmin,$ymin,$xmax,$ymax) considering the border handling of
the page layout.

=back

=cut

sub Workspace
{
  my ($self,%param)=@_;
  my ($xmin,$ymin,$xmax,$ymax);
  if ($self->{_Layout}->{width}<$self->{_Layout}->{height}){
     # portrait
     $xmin=$self->{_Layout}->{punchborder};
     $ymin=$self->{_Layout}->{border};
  }
  else{
     # landscape
     $ymin=$self->{_Layout}->{punchborder};
     $xmin=$self->{_Layout}->{border};
  }
  $xmax=$self->{_Layout}->{width}-$self->{_Layout}->{border};
  $ymax=$self->{_Layout}->{height}-$self->{_Layout}->{border};

  return($xmin,$ymin,$xmax,$ymax);
}

=pod

=head1 COPYRIGHT

Copyright (C) 2007 Holm Basedow. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
