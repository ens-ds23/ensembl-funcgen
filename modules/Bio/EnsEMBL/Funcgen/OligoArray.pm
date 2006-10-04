#
# Ensembl module for Bio::EnsEMBL::Funcgen::OligoArray
#
# You may distribute this module under the same terms as Perl itself

=head1 NAME

Bio::EnsEMBL::Funcgen::OligoArray - A module to represent an oligonucleotide microarray.

=head1 SYNOPSIS

use Bio::EnsEMBL::Funcgen::OligoArray;

my $array = Bio::EnsEMBL::Funcgen::OligoArray->new(
	    -NAME        => 'Array-1',
        -FORMAT      => 'Tiled',
        -SIZE        => '1',
        -SPECIES     => 'Mus_musculus',
	    -VENDOR      => 'Nimblegen',
        -DESCRIPTION => $desc,
);

my $db_adaptor = Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor->new(...);
my $array_adaptor = $db_adaptor->get_ArrayAdaptor();
my $array = $array_adaptor->fetch_by_name($array_name)

=head1 DESCRIPTION

An OligoArray object represents an oligonucleotide microarray. The data
(currently the name, format, size, species, vendor and description) are stored
in the array table.



=head1 AUTHOR

This module was created by Nathan Johnson, but is based on the
OligoArray module written by Ian Sealy.

This module is part of the Ensembl project: http://www.ensembl.org/

=head1 CONTACT

Post comments or questions to the Ensembl development list: ensembl-dev@ebi.ac.uk

=head1 METHODS

=cut

use strict;
use warnings;


package Bio::EnsEMBL::Funcgen::OligoArray;


use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Bio::EnsEMBL::Utils::Exception qw( throw warning );
use Bio::EnsEMBL::Storable;

use vars qw(@ISA);# %VALID_TYPE);
@ISA = qw(Bio::EnsEMBL::Storable);


# Possible types for OligoArray objects
#This should match the vendor enum values?
#%VALID_TYPE = (
#	'AFFY'  => 1,
#	'OLIGO' => 1,
#);


=head2 new

  Arg [-NAME]: string - the name of this array
  Arg [-TYPE]: string - the vendor of this array (AFFY, NIMBLEGEN etc)
  Arg [-FORMAT]: string - the format of this array (TILED, TARGETTED, GENE etc)

#array_chips is array of hashes or design_id and name, dbID will be populated on store, this should be a simple object!

  Example    : my $array = Bio::EnsEMBL::Funcgen::OligoArray->new(
								  -NAME        => 'Array-1',
								  -FORMAT      => 'Tiled',
								  -SIZE        => '1',
								  -SPECIES     => 'Mus_musculus',
								  -VENDOR      => 'Nimblegen',
                                  -ARRAY_CHIPS => \@array_chips,
								  -DESCRIPTION => $desc,
								 );
  Description: Creates a new Bio::EnsEMBL::Funcgen::OligoArray object.
  Returntype : Bio::EnsEMBL::Funcgen::OligoArray
  Exceptions : None ? should throw if mandatort params not set/valid
  Caller     : General
  Status     : At risk

=cut

sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;

  my $self = $class->SUPER::new(@_);
  
  my ($name, $format, $size, $species, $vendor, $ac_hash, $desc)
    = rearrange( ['NAME', 'FORMAT', 'SIZE', 'SPECIES', 'VENDOR', 'ARRAY_CHIPS', 'DESCRIPTION'], @_ );
  
  #mandatory params?
  #name, format, vendor
  #enum on format?

  
  $self->name($name)          if defined $name;
  $self->format($format)      if defined $format;
  $self->size($size)          if defined $size;
  $self->species($species)    if defined $species;
  $self->vendor($vendor)      if defined $vendor;
  $self->array_chips($ac_hash) if defined $ac_hash;
  $self->description($desc)   if defined $desc;
  
  return $self;
}

=head2 get_all_Probes

  Args       : None
  Example    : my $probes = $array->get_all_Probes();
  Description: Returns all probes on an array. Needs a database connection.
  Returntype : Listref of Bio::EnsEMBL::Funcgen::OligoProbe objects
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub get_all_Probes {
	my $self = shift;

	if ( $self->dbID() && $self->adaptor() ) {
		my $opa = $self->adaptor()->db()->get_OligoProbeAdaptor();
		my $probes = $opa->fetch_all_by_Array($self);
		return $probes;
	} else {
		warning('Need database connection to retrieve Probes');
		return [];
	}
}


#Nath new get methods

=head2 get_all_ProbeSets

  Args       : None
  Example    : my $probesets = $array->get_all_ProbeSets();
  Description: Returns all probesets on an array. Needs a database connection.
  Returntype : Listref of Bio::EnsEMBL::Funcgen::OligoProbeSets objects
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub get_all_ProbeSets {
	my $self = shift;

	if ( $self->dbID() && $self->adaptor() ) {
		my $opsa = $self->adaptor()->db()->get_OligoProbeSetAdaptor();
		my $probesets = $opsa->fetch_all_by_Array($self);
		return $probesets;
	} else {
		warning('Need database connection to retrieve ProbeSets');
		return [];
	}
}


#All the array_chip methods will be migrated to ArrayChip.pm

=head2 get_array_chip_ids

  Example    : my @ac_ids = @{$array->get_array_chip_ids()};
  Description: Returns all array_chip_ids for this array.
  Returntype : Listref of array_chip ids
  Exceptions : Throws if none retrieved
  Caller     : General
  Status     : At Risk

=cut

sub get_array_chip_ids {
  my $self = shift;

  my @ac_ids;

  #can we not just return the values?
  foreach my $ac_hash(@{$self->array_chips()}){
    push @ac_ids, $$ac_hash{'dbID'};
  }

  if(! @ac_ids){
    throw("No array_chip_ids available"); # should this be warn?
  }
  
  return \@ac_ids;
}

=head2 get_design_ids

  Example    : my @design_ids = @{$array->get_design_ids()};
  Description: Returns a the design_ids for each array_chip contained within this array
  Returntype : list
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut



sub get_design_ids{
  my ($self) = @_;
  return [keys %{$self->{'array_chips'}}];
}



=head2 name

  Arg [1]    : (optional) string - the name of this array
  Example    : my $name = $array->name();
  Description: Getter, setter of the name attribute for OligoArray
               objects.
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub name {
  my $self = shift;
  $self->{'name'} = shift if @_;

  #do we need this?
  #if ( !exists $self->{'name'} && $self->dbID() && $self->adaptor() ) {
  #  $self->adaptor->fetch_attributes($self);
  #}

  return $self->{'name'};
}

=head2 format

  Arg [1]    : (optional) string - the format of the array
  Example    : my $format = $array->format();
  Description: Getter, setter of format attribute for
               OligoArray objects e.g. Tiled, Targetted etc...
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub format {
  my $self = shift;
  
  $self->{'format'} = shift if @_;
  
  #do we need this?
  #if ( !exists $self->{'format'} && $self->dbID() && $self->adaptor() ) {
  #  $self->adaptor->fetch_attributes($self);
  #}

  return $self->{'format'};
}


=head2 size

  Arg [1]    : (optional) int - the number of ? in the array
  Example    : my $size = $array->size();
  Description: Getter, setter and lazy loader of size attribute for
               OligoArray objects. The size is the number of ? in this array. 
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub size {
  my $self = shift;
  #$self->{'size'} = shift if @_;
  #if ( !exists $self->{'size'} && $self->dbID() && $self->adaptor() ) {
  #	$self->adaptor->fetch_attributes($self);
  #}

  #how are we going to discern between size of array and size of array in experimental context?
  #array_chips does not update from DB if passed an arg!!
  

  return scalar(keys %{$self->array_chips()});
}

=head2 species

  Arg [1]    : (optional) string - the species of the array (e.g. Mus_musculus)
  Example    : my $species = $array->species();
  Description: Getter, setter of species attribute for OligoArray
               objects.
  Returntype : string
  Exceptions : Throws if argument cannot be mapped to a valid registry species alias
  Caller     : General
  Status     : Medium Risk

=cut

sub species {
  my $self = shift;
  my $species = shift;
  
  if ($species) {
    #check for registry_register here?
    #$species = $reg->get_alias($self->species()));
    $self->{'species'} = $species;
  }
  
  #do we need this?
  #if ( !exists $self->{'species'} && $self->dbID() && $self->adaptor() ) {
  #  $self->adaptor->fetch_attributes($self);
  #}

  return $self->{'species'};
}

=head2 vendor

  Arg [1]    : (optional) string - the name of the array vendor
  Example    : my $vendor = $array->vendor();
  Description: Getter, setter of vendor attribute for
               OligoArray objects.
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub vendor {
  my $self = shift;
  $self->{'vendor'} = shift if @_;
  
  #do we need this?
  #if ( !exists $self->{'vendor'} && $self->dbID() && $self->adaptor() ) {
  #  $self->adaptor->fetch_attributes($self);
  #}

  return $self->{'vendor'};
}

=head2 description

  Arg [1]    : (optional) string - the description of the array
  Example    : my $size = $array->description();
  Description: Getter, setter of description attribute for
               OligoArray objects. 
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub description {
  my $self = shift;
  $self->{'description'} = shift if @_;
  
  #do we need this?
  #if ( !exists $self->{'description'} && $self->dbID() && $self->adaptor() ) {
  #  $self->adaptor->fetch_attributes($self);
  #}

  return $self->{'description'};
}

=head2 array_chips

  Arg [1]    : (optional) arrayref of hashes - array_chips hashes (keys == dbid, design_id & name)
  Example    : $array->array_chips(%array_chips);
  Description: Getter, setter and lazy loader of array_chip hashes
  Returntype : Hashe of design_id keys and values of name and array_chip
  Exceptions : Throws exception if none found for array_id
  Caller     : General
  Status     : High Risk - migrate to ArrayChip.pm

=cut

sub array_chips {
  my $self = shift;
  my $achips = shift;
  
  if($achips){
    %{$self->{'array_chips'}} = %{$achips};
  }
	

  #lazy loaded as we won't want this for light DB
  #should do meta check and want here

  if ( ! exists $self->{'array_chips'}){
    if( $self->dbID() && $self->adaptor() ) {
      #$self->adaptor->fetch_attributes($self);
      #need to do this differently as we're accessing a different table
      $self->{'array_chips'} = {};
      %{$self->{'array_chips'}} = %{$self->adaptor->db->get_OligoArrayAdaptor->_fetch_array_chips_by_array_dbID($self->dbID())};
    }
    else{
      warn("Need array dbID and DB connection to retrieve array_chips");
    }
    
    
  }

  #throw here?	
  return $self->{'array_chips'};
}

=head2 get_array_chip_by_design_id

  Arg [1]    : (mandatory) int - design_id
  Example    : my %ac = %{$array->get_array_chip_by_design_id('1234')};
  Description: Getter for array_chip hashes
  Returntype : Hashref
  Exceptions : Throws exception if no design_id defined
  Caller     : General
  Status     : High Risk - migrate to ArrayChip.pm

=cut

sub get_array_chip_by_design_id{
  my ($self, $design_id) = @_;

  throw("Must supply a valid array chip design_id") if (! defined $design_id);

  return (defined $self->{'array_chips'}{$design_id}) ? $self->{'array_chips'}{$design_id} : undef;
  
}

=head2 add_array_chip

  Arg [1]    : (mandatory) int - design_id
  Arg [2]    : (mandatory) hashref - array chip hash
  Example    : $array->add_array_chip('1234', \%ac_hash);
  Description: Setter for array chips
  Returntype : None
  Exceptions : Throws exception if no design_id or array chip hashref defined
               Warns if already exists
  Caller     : General
  Status     : High Risk - migrate to ArrayChip.pm

=cut


sub add_array_chip{
  my ($self, $design_id, $ac_ref) = @_;

  $self->{'array_chips'} = {} if (! $self->{'array_chips'});

  throw("You must supply a valid design_id and array_chip hash") if(! defined $design_id && ! defined $ac_ref);
  
  if(exists $self->{'array_chips'}{$design_id}){
    warn("Array chip for $design_id already exists, using previous stored array chip\n");
  }else{
    %{$self->{'array_chips'}{$design_id}} = %{$ac_ref};#will this work?
  }

  return;
}

=head2 get_achip_status

  Arg [1]    : (mandatory) int - design_id
  Arg [2]    : (mandatory) hashref - array chip hash
  Example    : $array->add_array_chip('1234', \%ac_hash);
  Description: Setter for array chips
  Returntype : None
  Exceptions : Throws exception if no design_id defined or not part of this array
  Caller     : General
  Status     : High Risk - migrate to ArrayChip.pm, rename? accomodate multiple states

=cut

sub get_achip_status{
  my ($self, $design_id, $state) = @_;
	
  throw("Need to supply a design_id for the array_chip") if ! $design_id;

  #Need to accomodate multiple states!!

  if(exists $self->{'array_chips'}{"$design_id"}){
    #should we do a test for ac dbid here?

    if(! exists $self->{'array_chips'}{"$design_id"}{'status'}){
      my $ac_dbid = $self->{'array_chips'}{"$design_id"}{'dbID'};
      $self->{'array_chips'}{"$design_id"}{'status'} = $self->adaptor->db->fetch_status_by_name('array_chip', $ac_dbid, $state);
    }

  }else{
    #should be warn?
    throw("The design_id you have specified is not associated with this array ".$self->name());
  }

  return $self->{'array_chips'}{"$design_id"}{'status'};
}


1;

