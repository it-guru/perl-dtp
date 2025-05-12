package DTP::Entity;
#  Parent class for entities for the DTP package
#
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
use UNIVERSAL;
use vars(qw(@ISA));
use POSIX;
use Data::Dumper;

@ISA=qw(UNIVERSAL);


=pod

=head1 NAME

DTP::Entity - Base Class for DTP Entities

=head1 DESCRIPTION

Entity base class

=head1 CONSTRUCTOR

=over

=item new()

 my $e=new DTP::Entity();

B<Constructor to create the DTP object.>

=back

=cut

sub new
{
   my $type=shift;
   my $self={@_};
   bless($self,$type);
   $self->{_Dim}=[50,50];
   $self->{_PPos}=0;
   return($self);
}


sub _setDimension   # sets the default dimension from the parent
{
   my $self=shift;
   my $width=shift;
   my $height=shift;
   $self->{_Dim}->[0]=$width  if (defined($width));
   $self->{_Dim}->[1]=$height if (defined($height));

   return($self);
}

sub _getDimension   # call for the parent to get the final dimension
{
   my $self=shift;
   return($self->{_Dim}->[0],$self->{_Dim}->[1]);
}

sub Workspace
{
  my ($self,%param)=@_;

  my $xmin=$self->{_Layout}->{x0};
  my $ymin=$self->{_Layout}->{y0};

  my $xmax=$xmin+$self->{_Dim}->[0];
  my $ymax=$ymin+$self->{_Dim}->[1];

  return($xmin,$ymin,$xmax,$ymax);
}



sub Draw
{
   my $self=shift;
   my $dtp=shift;
   my $x0=shift;
   my $y0=shift;

   $self->{_Layout}->{x0}=$x0;
   $self->{_Layout}->{y0}=$y0;
   $self->{_DTP}=$dtp;

   $self->onDraw(@_);
}


######################################################################
# call on parent

sub Line
{
   my $self=shift;
   return($self->{_DTP}->Line(@_));
}

sub Rec
{
   my $self=shift;
   return($self->{_DTP}->Rec(@_));
}

sub TextDimension
{
   my $self=shift;
   return($self->{_DTP}->TextDimension(@_));
}


sub TextOut
{
   my $self=shift;
   return($self->{_DTP}->TextOut(@_));
}

sub SetPPos
{
   my $self=shift;
   my $newy=shift;
   $self->{_PPos}=$newy-$self->{_Layout}->{y0};
   return($self->{_PPos});
}

sub GetPPos
{
   my $self=shift;
   return($self->{_Layout}->{y0}+$self->{_PPos});
}

sub NewPage
{
   my $self=shift;
   return($self->{_DTP}->NewPage(@_));
}
######################################################################





sub onDraw
{
   my $self=shift;
   my ($xmin,$ymin,$xmax,$ymax)=$self->Workspace();
 
#   my $dtp=$self->{_DTP};
#   my $x0=$self->{_Layout}->{x0};
#   my $y0=$self->{_Layout}->{y0};

   if ($self->{border}){
      $self->Line($xmin,$ymin,$xmax,$ymin);
      $self->Line($xmin,$ymin,$xmin,$ymax);
      $self->Line($xmax,$ymax,$xmax,$ymin);
      $self->Line($xmax,$ymax,$xmin,$ymax);
   }
   $self->Line($xmax,$ymax,$xmin,$ymin);

   $self->Line($xmin,$ymax,$xmax,$ymin);

   return($self);
}


=pod

=head1 COPYRIGHT

Copyright (C) 2007 Vogler Hartmut. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#
# help function for graph scaling
#

sub calcScaleMax
{
   my $b=shift;

   my $smax=1;
   $smax=calcLogScaleMax($b) if ($b>0);
   my $max2=300;
   $max2=calcLogScaleMax($b*2) if ($b>0);
   $smax=$smax/2 if ($smax==$max2);
   my $mainstep=$smax/10;
   my $substep=$smax/20;
   return($smax,$mainstep,$substep);
}

sub calcLogScaleMax
{
   my $b=shift;

   my $max=10**(POSIX::ceil(log(abs($b))/log(10)));
   $max=$max*-1 if ($b<0);
   return($max);
}



1;
