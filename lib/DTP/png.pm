package DTP::png;
#  a Perl module for Desktop Publishing in jpg-format
#
#  Copyright (C) 2007  Holm Basedow (it@cwgurublauwaerme.de)
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
use DTP::GD;


@ISA=qw(DTP::GD);

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
  my ($self,$mode)=@_;
  my @res;
  #print Dumper($self->{_GDPage});
  foreach my $doc (@{$self->{_GDPage}}){
     my $filename=$doc->{filename};
     $filename.=".png";
     if (!open(F,">$filename")){
        printf STDERR ("ERROR: can't open $filename\n");
        return(undef);
     }
     print F $doc->{GD}->png();
     close(F);
     push(@res,$filename);
  }
  return(@res);
}


1;
