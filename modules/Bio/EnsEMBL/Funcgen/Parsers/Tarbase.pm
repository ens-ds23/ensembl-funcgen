=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <ensembl-dev@ebi.ac.uk>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=cut

package Bio::EnsEMBL::Funcgen::Parsers::Tarbase;

use strict;
use warnings;
use feature qw(say);
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::Funcgen::FeatureType;
use Bio::EnsEMBL::Utils::Exception qw( throw );
use Bio::EnsEMBL::Funcgen::Utils::EFGUtils  qw(add_external_db);


use parent qw( Bio::EnsEMBL::Funcgen::Parsers::BaseExternalParser );

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;



  my $self = $class->SUPER::new(@_, type => 'Tarbase');
#  say dump_data($self,1,1);die;

  #Set default feature_type and feature_set config
  $self->{static_config}{feature_types} = {(
      'TarBase miRNA target'   => {
        -name        => 'TarBase miRNA target',
        -class       => 'RNA',
        -description => 'TarBase miRNA target predictions',
        },
      )};

  $self->{static_config}{analysis} = {
    TarBase =>  {
      -logic_name    => 'TarBase_v6.0',
      -description   => '<a>TarBase</a> miRNA target predictions (http://diana.imis.athena-innovation.gr/)',
      -display_label => 'TarBase miRNA',
      -displayable   => 1,
    },
  };

  # This is used as the entry point to store/validate
  # So all of the above needs to be referenced in here
  $self->{static_config}{feature_sets} = {
    'TarBase miRNA' =>{
      #Stored in this order

      #Entries here are flexible
      #Can be omited if defined in feature_set
      #top level analysis/feature_types definition required if no DB defaults available
      #These can be a ref to the whole or subset of the top level analysis/feature_types hash
      #A key with an empty hash or undef(with or without a matching key in the top level analysis/feature_types hash

      #analysis      => $self->{static_config}{analysis},
      feature_types => $self->{static_config}{feature_types},

      #feature_type and analysis values must be string key to top level hash
      #This wont work for feature_types as they are not unique by name!!!!!!
      #This is why we have top level hash where we can define a unique compound key name

      feature_set   =>{
        -feature_type      => 'TarBase miRNA target', #feature_types config key name not object
        -display_label     => 'TarBase miRNA target predictions',
        -description       => 'TarBase miRNA target predictions',
        -analysis          => 'TarBase_v6.0', #analysis config key name not object
      },
    }
  };

  #$self->validate_and_store_feature_types;
  $self->validate_and_store_config([keys %{$self->{static_config}{feature_sets}}]);
  $self->set_feature_sets;

  return $self;
}


sub parse_and_load{
  my ($self, $files, $old_assembly, $new_assembly) = @_;

  if (scalar(@$files) != 2) {
    throw('2 files expected, Tarbase data(1) and aliases.txt(2) from miRBase\t'.join(' ', @$files));;
  }
  
  # Set release to the release TarBase used to map their miRNA targets 
  my $external_db_name;
  my $external_db_release;
  
  if($self->species eq 'homo_sapiens'){
    $external_db_name    = 'homo_sapiens_core_Gene';
    $external_db_release = '73_37'; 
  }
  elsif($self->species eq 'mus_musculus'){
    $external_db_name    = 'mus_musculus_core_Gene';
    $external_db_release = '73_38'; 
  }
  elsif($self->species eq 'rattus_norvegicus'){
    $external_db_name    = 'rattus_norvegicus_core_Gene';
    $external_db_release = '73_5'; 
  }
  else{
    throw($self->species . " not implemented. Add here.")
  }
  $self->log_header("Using $external_db_name as external_db.name and $external_db_release as external_db.release");
  
  my $ex_Db = add_external_db(
    $self->db, 
    $external_db_name,
    $external_db_release,
    'EnsemblGene',
    );

  $self->log_header("Parsing miRNA names (only human, mouse and rat) from:\t".$files->[1]);  
  # alias.txt
  # map accession to ID 
  # MI0000063  hsa-let-7bL;hsa-let-7b;
  # The last ID (hsa-let-7b in this case) is always the preferred one
  # Currently we only keep human, mouse and rat

  my $id_lookup = {};
  open(my $fh,'<',$files->[1]) or die "Can't access ". $files->[1];
    while(my $line = <$fh>){
      if($line !~ /^MI\d{7}\t[a-z;0-9]*$/){
        throw("Unexpected format of alias.txt file");
      }
      next if($line !~ /[hsa-|mmu-|rno]/);
      chomp($line);
      my @ids = split(/\t/, $line);
      my @mi_rna_names = split(/;/, $ids[1]);
      if(defined $id_lookup->{$ids[0]}){
        throw("Duplicate record $ids[0] in file " . $files->[1]);
      }
      $id_lookup->{$ids[0]} = $mi_rna_names[-1];
    }
  close($fh);


  my $extfeat_a   = $self->db->get_ExternalFeatureAdaptor;
  my $dbentry_a   = $self->db->get_DBEntryAdaptor;
  my $feattype_a  = $self->db->get_FeatureTypeAdaptor;
  my $gene_a      = $self->db->dnadb->get_GeneAdaptor;
  my $slice_a     = $self->db->dnadb->get_SliceAdaptor;
  
  my $fset_config      = $self->{static_config}{feature_sets}{'TarBase miRNA'};
  my $fset              = $fset_config->{feature_set};
  
  $self->rollback_FeatureSet($fset);
  $self->log_header("Rollback old records in external_features manually");

  # Logging has space for improvement
  my $log  = {};
  my $log2 = {};

  my $species = {
    ENSG    => 'homo_sapiens',
    ENSMUSG => 'mus_musculus',
    ENSRNOG => 'rattus_norvegicus',
  };

  # ENSG    = hsa
  # ENSMUSG = mmu
  # ENSRNOG = rno
  ### Read file
  # yes: MIMAT0000416|ENSG00000101158|
  # no:  MIMAT0004224|C37H5.6|Sequencing|NA|UNKNOWN|
  #next if($line !~ /\d\|ENS/);
  $self->log_header("Parsing and loading TarBase data from:\t" . $files->[0]);

  open($fh,'<',$files->[0]) or die "Can't access ". $files->[0];
  while (my $line = <$fh>) {
    my $species_tarbase;
    
    $line =~ /^MIMAT\d{7}\|(ENSG|ENSMUSG|ENSRNOG])/;

    if($1){
      $species_tarbase = $species->{$1};
    }
    else{
      $line =~ /^MIMAT\d{7}\|(.*)\|/;
      $log->{unrecognised_stableID}->{$1}++;
      $log2->{unrecognised_stableID}++;
      next;
    }
    throw $line if (!$species_tarbase );
    
    if($self->{species} ne $species_tarbase){
      $log->{different_species}->{$species_tarbase}++;
      $log2->{different_species}++;
      next;
    }
    # MIMAT0000416|ENSG00000101158|Proteomics|Computational|57569740_57569768|
    # http://diana.imis.athena-innovation.gr/DianaTools/index.php?r=tarbase/index&mirnas=MIMAT0000416&genes=ENSG00000101158

    chomp($line);

    # 0: MIMAT0000416
    # 1: ENSG00000101158
    # 2: Proteomics
    # 3: Computational
    # 4: 57569740_57569768
    # 5: http://diana.imis.athena-innovation.gr/DianaTools/index.php?r=tarbase/index&mirnas=MIMAT0000416&genes=ENSG00000101158
    
    my @fields = split(/\|/,$line);
    my $mi_rna_id = $fields[0];
    my $ensg      = $fields[1];
    my $method    = $fields[2];
    my $evidence  = $fields[3];
    my $location  = $fields[4];
    my $link      = $fields[5];

    # MI0000060 -> cel-miR-87-3p
    my $mi_rna_name = $id_lookup->{$mi_rna_id};
    if(!$mi_rna_name){
      $log->{miRnaID_not_defined_in_aliases}->{$mi_rna_name}++;
      $log2->{miRnaID_not_defined_in_aliases}++;
      next;
    }

    my $gene = $gene_a->fetch_by_stable_id($ensg);
    if(!$gene){
      $log->{outdated_stableID}->{$ensg}++;
      $log2->{outdated_stableID}++;
      next;
    }
    # Might be possible to BLAT 3UTR, but testing a few examples did not result in usable result
    # as they mapped on the wrong chromosomes
    if($location =~ /^3UTR|UNKNOWN$/){
      $log->{no_coordinates}->{"$mi_rna_id\t$ensg"}++;
      $log2->{no_coordinates}++;
      next;
    }

    my $feature_type = $feattype_a->fetch_by_name($mi_rna_name);
    if(!$feature_type){
      my $ft = Bio::EnsEMBL::Funcgen::FeatureType->new(
      -name         => $mi_rna_name,
      -class        => 'RNA',
      -description  => 'miRNA target site',
      -so_name      => 'SO:0000934',
      -so_accession => 'miRNA_target_site',
      );
      $feattype_a->store($ft);
    }


    # possible scenarios
    # single binding site, no splice junction
    #     39887837_39887865
    # single binding site, splice junction
    #     39882813;39883392_39882824;39883408
    # gene interaction with 2 binding sites (no splice junction)
    #     39887837_39887865@39888473_39888501
    # gene interactions with 2 binding sites (one of them on a splice junction)
    #     39887837_39887865@39882813;39883392_39882824;39883408

    my @locations = split(/@/,$location);
    my @coords;

    for my $coord(@locations) {
      if($coord =~ /^(\d+)_(\d+)$/){
        if($1 > $2){
          $log->{reverse_coordinates}->{"$mi_rna_name\t$ensg\t$location"}++;
          $log2->{reverse_coordinates}++;
          next;
        }
        push @coords, {start => $1, stop => $2};
      }   
      elsif($coord =~ /^(\d+);(\d+)_(\d+);(\d+)$/){
        if( $1 > $3 or $2 > $4){
          $log->{reverse_coordinates}->{"$mi_rna_name\t$ensg\t$location"}++;
          $log2->{reverse_coordinates}++;
          next;
        }
        push @coords, {start => $1, stop => $3};
        push @coords, {start => $2, stop => $4};
      }    
      else{
        $log->{location_format}->{$location}++;
        $log2->{location_format}++;
        next;
      }   
    }
    $log->{stored_miRNA}->{$mi_rna_name}++;
    $log2->{stored_miRNA}++;

   
    for my $sites(@coords) {
      # my $transcript_mi_rna_seq = $transcript->seq->subseq($mi_rna_start, $mi_rna_end);
      #  my @genomic_coords        = $transcript->cdna2genomic($mi_rna_start, $mi_rna_end);
     
      my $feature = Bio::EnsEMBL::Funcgen::ExternalFeature->new (
       -start         => $sites->{start}, 
       -end           => $sites->{stop},  
       -strand        => $gene->strand,
       -feature_type  => $feature_type,
       -slice         => $gene->slice,
       -display_label => $mi_rna_name, 
       -feature_set   => $fset,
       );
       $extfeat_a->store($feature);

      my $dbentry = Bio::EnsEMBL::DBEntry->new(
       -primary_id             => $gene->stable_id,
       -dbname                 => $external_db_name,
       -release                => $external_db_release, 
       -display_id             => $gene->display_xref->display_id,
       -status                 => 'KNOWNXREF',
       -db_display_name        => 'EnsemblGene',
       -type                   => 'MISC',#this is external_db.type
       -info_type              => 'MISC',
       -info_text              => 'GENE',
       -linkage_annotation     => 'TarBase Micro RNA target',
       -analysis               => $fset->analysis,
      );
     $dbentry_a->store($dbentry, $feature->dbID, 'ExternalFeature');#

      $log->{stored_records}->{$mi_rna_name}++;
      $log2->{stored_records}++;
    }
    
  }

  close $fh;
  my $errors = $self->{_default_log_dir} . "/tarbase_import.$$.log";
    open($fh,'>',$errors) or die "Can not access '$errors'\n$!";
    
      foreach my $message (sort keys %{$log}){
        next if($message =~ /stored_records|stored_miRNA/);
        say $fh '::::::  '.$message . "\t[". $log2->{$message} .']'.'  ::::::';
        foreach my $value (sort keys %{$log->{$message}}){
          say $fh $value;
        }
      }
      close($fh);

  my $total = 0;

  $self->log_header("Parsing stats - Unsuccessful");  

  foreach my $key (sort keys %{$log2}){
    next if($key =~ /stored_records|stored_miRNA/);
    $self->log("$key\t".$log2->{$key});
    $total += $log2->{$key};
  }

  $self->log_header("Parsing statistics - Successful");
  $self->log("miRNAs stored: " . $log2->{stored_miRNA});  
  $self->log("Interactions stored: " . $log2->{stored_records});  


  $self->log_header("Failed records: $total");
  $total = $log2->{stored_miRNA} + $log2->{stored_records};
  $self->log_header("Successfully stored: $total");

  #Now set states
  foreach my $status (qw(DISPLAYABLE MART_DISPLAYABLE)) {
   $fset->adaptor->store_status($status, $fset);
  }
  return;

}


1;