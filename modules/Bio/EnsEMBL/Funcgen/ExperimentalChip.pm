#
# Ensembl module for Bio::EnsEMBL::Funcgen::ExperimentalChip
#
# You may distribute this module under the same terms as Perl itself

=head1 NAME

Bio::EnsEMBL::Funcgen::ExperimentalChip - A module to represent a physical unique experimental chip.

=head1 SYNOPSIS

use Bio::EnsEMBL::Funcgen::ExperimentalChip;

my $ec = Bio::EnsEMBL::Funcgen::ExperimentalChip->new(
							 -dbID           => $ec_id,
							 -unique_id => $c_uid,
						         -experiment_id  => $exp_id,
	                                                 -array_chip_id  => $ac_id,
							 -description    => $desc,
							 );


=head1 DESCRIPTION

An ExperimentalChip object represent a physical array chip/slide used in an experiment. The data
(currently the unique_id, experiment_id, array_chip_id, and description) are stored
in the experimental_chip table.



=head1 AUTHOR

This module was created by Nathan Johnson.

This module is part of the Ensembl project: http://www.ensembl.org/

=head1 CONTACT

Post comments or questions to the Ensembl development list: ensembl-dev@ebi.ac.uk

=head1 METHODS

=cut

use strict;
use warnings;


package Bio::EnsEMBL::Funcgen::ExperimentalChip;


use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Bio::EnsEMBL::Utils::Exception qw( throw warning );
use Bio::EnsEMBL::Storable;

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::Storable);


=head2 new

  Arg [-unique_id]: int - the unique id of this individual experimental chip
  Arg [-experiment_id]:  int - the experiment dbID
  Arg [-array_chip_id]:  int - the dbID or the array_chip
  Arg [-description]:  strin - the description of this experimental chip


  Example    : my $array = Bio::EnsEMBL::Funcgen::ExperimentalChip->new(
									-dbID           => $ec_id,
									-unique_id => $c_uid,
									-experiment_id  => $exp_id,
									-array_chip_id  => $ac_id,
									-description    => $desc,
								       );
  Description: Creates a new Bio::EnsEMBL::Funcgen::ExperimentalChip object.
  Returntype : Bio::EnsEMBL::Funcgen::ExperimentalChip
  Exceptions : None ? should throw if mandaotry params not set
  Caller     : General
  Status     : Medium Risk

=cut

sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;

  my $self = $class->SUPER::new(@_);

  #can we lc these?
  my ($c_uid, $exp_dbid, $ac_id, $desc)
    = rearrange( ['UNIQUE_ID', 'EXPERIMENT_ID', 'ARRAY_CHIP_ID', 'DESCRIPTION'], @_ );
  
  
  #mandatory params all but description
  $self->unique_id($c_uid)          if defined $c_uid;
  $self->experiment_id($exp_dbid)          if defined $exp_dbid;
  $self->array_chip_id($ac_id)    if defined $ac_id;
  $self->description($desc)   if defined $desc;

  return $self;
}

=head2 get_Channels

  Args       : None
  Example    : my $channels = $array->get_Channels();
  Description: Returns all channels on a ExperimentalChip. Needs a database connection.
  Returntype : Listref of Bio::EnsEMBL::Funcgen::Channel objects
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub get_Channels {
  my $self = shift;

  
  if ( $self->dbID() && $self->adaptor() ) {
    foreach my $channel (@{$self->adaptor->db->get_ChannelAdaptor->fetch_all_by_ExperimentalChip($self)}){
      $self->{'channels'}{$channel->dbID()} = $channel;
    }	
  } else {
    warning('Need database connection to retrieve Channels');
  }
  
  return [values %{$self->{'channels'}}];
}




=head2 unique_id

  Arg [1]    : (optional) int - the unique chip id for this ExperimentalChip
  Example    : my $c_uid = $array->unique_id();
  Description: Getter, setter unique_id attribute.
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub unique_id {
  my $self = shift;
  $self->{'unique_id'} = shift if @_;
  return $self->{'unique_id'};
}

=head2 experiment_id

  Arg [1]    : (optional) int - the experiment dbID
  Example    : my $exp_id = $array->experiment_id();
  Description: Getter, setter experiment_id attribute
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub experiment_id {
  my $self = shift;
  $self->{'experiment_id'} = shift if @_;
  return $self->{'experiment_id'};
}

=head2 array_chip_id

  Arg [1]    : (optional) int - the array_chip dbID
  Example    : my $ac_id = $ec->array_chip_id();
  Description: Getter, setter array_chip_id attribute
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub array_chip_id {
  my $self = shift;
  $self->{'array_chip_id'} = shift if @_; 
  return $self->{'array_chip_id'};
}


=head2 description

  Arg [1]    : (optional) string - the description of the ExperimentalChip
  Example    : my $desc = $ec->description();
  Description: Getter, setter of description attribute
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub description {
  my $self = shift;
  $self->{'description'} = shift if @_;
  return $self->{'description'};
}


1;

