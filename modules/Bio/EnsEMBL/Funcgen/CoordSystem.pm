#
# EnsEMBL module for Bio::EnsEMBL::Funcgen::CoordSystem
#

=head1 NAME

Bio::EnsEMBL::Funcgen::CoordSystem

=head1 SYNOPSIS

  my $db = Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor->new(...);

  my $csa = $db->get_CoordSystemAdaptor();

  #
  # Get default chromosome coord system for the 39_36a DB:
  #
  my $cs = $csa->fetch_by_name_schema_build_version('chromosome', '39_36a');
  my $str = join ':', $cs->name(),$cs->version(),$cs->dbID();
  print "$str\n";


=head1 DESCRIPTION

This has been adapted from the core CoordSystem object to accomodate the multi-assembly
aspects of the eFG schema, namely hadnling the schema_build of the referenced core DB.

This is a simple object which contains a few coordinate system attributes:
name, internal identifier, version and schema_build.  A coordinate system is 
uniquely defined by its name and version and which DB it came from i.e. schema_build.  
A version of a coordinate system applies to all sequences within a coordinate system.  
This should not be confused with individual sequence versions.

Take for example the Human assembly.  The version 'NCBI33' applies to
to all chromosomes in the NCBI33 assembly (that is the entire 'chromosome'
coordinate system).  The 'clone' coordinate system in the same database would
have no version however.  Although the clone sequences have their own sequence
versions, there is no version which applies to the entire set of clones.

Coordinate system objects are immutable. Their name and version, and other
attributes may not be altered after they are created.

=head1 AUTHOR

This module was written by Nathan Johnson, but was based heavily on the core module
authored by Graham McVicker.

=head1 CONTACT

Post questions to the EnsEMBL development list ensembl-dev@ebi.ac.uk

=head1 METHODS

=cut


use strict;
use warnings;

package Bio::EnsEMBL::Funcgen::CoordSystem;

use Bio::EnsEMBL::Storable;

use Bio::EnsEMBL::Utils::Argument  qw(rearrange);
use Bio::EnsEMBL::Utils::Exception qw(throw);

use vars qw(@ISA);

@ISA = qw(Bio::EnsEMBL::Storable);


=head2 new

  Arg [..]   : List of named arguments:
               -NAME      - The name of the coordinate system
               -VERSION   - (optional) The version of the coordinate system.
                            Note that if the version passed in is undefined,
                            it will be set to the empty string in the
                            resulting CoordSystem object.
               -RANK      - The rank of the coordinate system. The highest
                            level coordinate system should have rank 1, the
                            second highest rank 2 and so on.  An example of
                            a high level coordinate system is 'chromosome' an
                            example of a lower level coordinate system is
                            'clone'.
               -SCHEMA_BUILD - The schema and data build version of the DB of
                               origin.
               -TOP_LEVEL - (optional) Sets whether this is a top-level coord
                            system. Default = 0. This should only be set to
                            true if you are creating an artificial toplevel
                            coordsystem by the name of 'toplevel'
               -SEQUENCE_LEVEL - (optional) Sets whether this is a sequence
                                 level coordinate system. Default = 0
               -DEFAULT      - (optional)
                               Whether this is the default version of the 
                               coordinate systems of this name. Default = 0
               -DBID         - (optional) The internal identifier of this
                                coordinate system
               -ADAPTOR      - (optional) The adaptor which provides database
                               interaction for this object
  Example    : $cs = Bio::EnsEMBL::CoordSystem->new(-NAME    => 'chromosome',
                                                    -VERSION => 'NCBI33',
                                                    -RANK    => 1,
                                                    -DBID    => 1,
                                                    -SCHEMA_BUILD => '39_36a',
                                                    -ADAPTOR => adaptor,
                                                    -DEFAULT => 1,
                                                    -SEQUENCE_LEVEL => 0);
  Description: Creates a new CoordSystem object representing a coordinate
               system.
  Returntype : Bio::EnsEMBL::Funcgen::CoordSystem
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my $self = $class->SUPER::new(@_);


  #Can we just hadnle schema_build here and call super->new for the rest.
  #We will also have to handle the top/default levels issues with multiple DBs


  my ($name, $version, $sbuild, $top_level, $sequence_level, $default, $rank) =
    rearrange(['NAME','VERSION', 'SCHEMA_BUILD','TOP_LEVEL', 'SEQUENCE_LEVEL',
               'DEFAULT', 'RANK'], @_);

  throw('A name and schema_build argument are required') if(!$name || ! $sbuild);
  

  $version = '' if(!defined($version));

  $top_level       = ($top_level)      ? 1 : 0;
  $sequence_level  = ($sequence_level) ? 1 : 0;
  $default         = ($default)        ? 1 : 0;
  $rank ||= 0;

  if($top_level) {
    if($rank) {
      throw('RANK argument must be 0 if TOP_LEVEL is 1');
    }

    if($name) {
      if($name ne 'toplevel') {
        throw('The NAME argument must be "toplevel" if TOP_LEVEL is 1')
      }
    } else {
      $name = 'toplevel';
    }

    if($sequence_level) {
      throw("SEQUENCE_LEVEL argument must be 0 if TOP_LEVEL is 1");
    }

    $default = 0;

  } else {
    if(!$rank) {
      throw("RANK argument must be non-zero if not toplevel CoordSystem");
    }
    if($name eq 'toplevel') {
      throw("Cannot name coord system 'toplevel' unless TOP_LEVEL is 1");
    }
  }

  if($rank !~ /^\d+$/) {
    throw('The RANK argument must be a positive integer');
  }

  $self->{'version'} = $version;
  $self->{'name'} = $name;
  $self->{'schema_build'} = $sbuild;
  $self->{'top_level'} = $top_level;
  $self->{'sequence_level'} = $sequence_level;
  $self->{'default'} = $default;
  $self->{'rank'}    = $rank;

  return $self;
}


#remove all but schema_buil and equals?
#depends on how we handle levels

=head2 name

  Arg [1]    : (optional) string $name
  Example    : print $coord_system->name();
  Description: Getter for the name of this coordinate system
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub name {
  my $self = shift;
  return $self->{'name'};
}


=head2 schema_build

  Example    : print $coord_system->schema_build();
  Description: Getter for the schema_build of this coordinate system
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub schema_build {
  my $self = shift;
  return $self->{'schema_build'};
}



=head2 version

  Arg [1]    : none
  Example    : print $coord->version();
  Description: Getter for the version of this coordinate system.  This
               will return an empty string if no version is defined for this
               coordinate system.
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub version {
  my $self = shift;
  return $self->{'version'};
}




=head2 equals

  Arg [1]    : Bio::EnsEMBL::Funcgen::CoordSystem $cs
               The coord system to compare to for equality.
  Example    : if($coord_sys->equals($other_coord_sys)) { ... }
  Description: Compares 2 coordinate systems and returns true if they are
               equivalent.  The definition of equivalent is sharing the same
               name and version.
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : At risk

=cut

sub equals {
  my $self = shift;
  my $cs = shift;

  if(!$cs || !ref($cs) || 
	 (!$cs->isa('Bio::EnsEMBL::Funcgen::CoordSystem')  && !$cs->isa('Bio::EnsEMBL::CoordSystem'))){
	  throw('Argument must be a Bio::EnsEMBL(::Funcgen)::CoordSystem');
  }
  
  
  #need to add check on schema_build here

  #print $self->{'version'}." eq ".$cs->version()." && ".$self->{'name'}." eq ".$cs->name()." && ".$self->adaptor->db->_get_schema_build($cs->adaptor())." eq ".$self->schema_build()."\n"; 

 
  
  if($self->{'version'} eq $cs->version() && $self->{'name'} eq $cs->name() && $self->adaptor->db->_get_schema_build($cs->adaptor()) eq $self->schema_build()) {
    return 1;
  }

  return 0;
}




=head2 is_top_level

  Arg [1]    : none
  Example    : if($coord_sys->is_top_level()) { ... }
  Description: Returns true if this is the toplevel pseudo coordinate system.
               The toplevel coordinate system is not a real coordinate system
               which is stored in the database, but it is a placeholder that
               can be used to request transformations or retrievals to/from
               the highest defined coordinate system in a given region.
  Returntype : 0 or 1
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_top_level {
  my $self = shift;
  return $self->{'top_level'};
}


=head2 is_sequence_level

  Arg [1]    : none
  Example    : if($coord_sys->is_sequence_level()) { ... }
  Description: Returns true if this is a sequence level coordinate system
  Returntype : 0 or 1
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_sequence_level {
  my $self = shift;
  return $self->{'sequence_level'};
}


=head2 is_default

  Arg [1]    : none
  Example    : if($coord_sys->is_default()) { ... }
  Description: Returns true if this coordinate system is the default
               version of the coordinate system of this name.
  Returntype : 0 or 1
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_default {
  my $self = shift;
  return $self->{'default'};
}




=head2 rank

  Arg [1]    : none
  Example    : if($cs1->rank() < $cs2->rank()) {
                 print $cs1->name(), " is a higher level coord system than",
                       $cs2->name(), "\n";
               }
  Description: Returns the rank of this coordinate system.  A lower number
               is a higher coordinate system.  The highest level coordinate
               system has a rank of 1 (e.g. 'chromosome').  The toplevel
               pseudo coordinate system has a rank of 0.
  Returntype : int
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub rank {
  my $self = shift;
  return $self->{'rank'};
}

1;
