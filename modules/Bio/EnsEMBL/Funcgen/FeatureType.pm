#
# Ensembl module for Bio::EnsEMBL::Funcgen::FeatureType
#
# You may distribute this module under the same terms as Perl itself

=head1 NAME

Bio::EnsEMBL::Funcgen::FeatureType - A module to represent a FeatureType. i.e. the target of an experiment.

=head1 SYNOPSIS

use Bio::EnsEMBL::Funcgen::FeatureType;



=head1 DESCRIPTION

This is a simple class to represent information about a FeatureType, containing the name i.e Brno nomenclature or other controlled/validated name relevant to the class (HISTONE, PROMOTER etc), and description. This module is part of the Ensembl project: http://www.ensembl.org/


=head1 AUTHOR

This module was written by Nathan Johnson.

=head1 CONTACT

Post comments or questions to the Ensembl development list: ensembl-dev@ebi.ac.uk

=head1 METHODS

=cut

use strict;
use warnings;

package Bio::EnsEMBL::Funcgen::FeatureType;

use Bio::EnsEMBL::Utils::Argument qw( rearrange ) ;
use Bio::EnsEMBL::Utils::Exception qw( throw warning );
use Bio::EnsEMBL::Storable;

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::Storable);


=head2 new

  Arg [-name]: string - name of FeatureType
  Arg [-class]: string - class of FeatureType
  Arg [-description]: string - descriptiom of FeatureType
  Example    : my $ft = Bio::EnsEMBL::Funcgen::FeatureType->new(
                                                               -name  => "H3K9Me",
                                                               -class => "HISTONE",
                                                               -description => "Generalised methylation of Histone 3 Lysine 9",
                                                                );
  Description: Constructor method for FeatureType class
  Returntype : Bio::EnsEMBL::Funcgen::FeatureType
  Exceptions : Throws if name not defined ? and class
  Caller     : General
  Status     : Medium risk

=cut

sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;

  my $self = $class->SUPER::new(@_);
  
  
  my (
      $name,
      $desc,
      $cclass,
     ) = rearrange([
		    'NAME', 'DESCRIPTION', 'CLASS',
		   ], @_);
  
  
  if($name){
    $self->name($name);
  }else{
    throw("Must supply a FeatureType name\n");
  }


  #add test for class and enum? Validate names against Brno etc?
  $self->class($cclass) if $cclass;
  $self->description($desc) if $desc;

  return $self;
}



=head2 name

  Arg [1]    : string - name
  Example    : my $name = $ft->name();
  Description: Getter and setter of name attribute for FeatureType
               objects
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Low Risk

=cut

sub name {
    my $self = shift;
    $self->{'name'} = shift if @_;
    return $self->{'name'};
}

=head2 description

  Arg [1]    : (optional) string - description
  Example    : my $desc = $ft->description();
  Description: Getter and setter of description attribute for FeatureType
               objects.
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Low Risk

=cut

sub description {
    my $self = shift;
    $self->{'description'} = shift if @_;
    return $self->{'description'};
}


=head2 class

  Arg [1]    : (optional) string - class
  Example    : $ft->class('HISTONE');
  Description: Getter and setter of description attribute for FeatureType
               objects.
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Low Risk

=cut

sub class{
  my $self = shift;
  $self->{'class'} = shift if @_;
  return $self->{'class'};
}
1;

