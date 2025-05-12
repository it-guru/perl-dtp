package DTP::Entity::Table;
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
   my $text=shift;
   my %INParam=@_;
   my $self={};
   $self=bless($type->SUPER::new(%$self),$type);
   $self->{_text}=$text;
   $self->{_INparam}=\%INParam;
   return($self);
}



sub onDraw
{
   my ($self)=@_;
   my $text=$self->{_text};
   my %INparam=%{$self->{_INparam}};

   $self->DTP::WriteLine($text,%INparam);
   return($self);
}


=pod

=head1 COPYRIGHT

Copyright (C) 2007 Vogler Hartmut. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
