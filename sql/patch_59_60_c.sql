# patch_59_60_b.sql
#
# title: add motif_feature and binding_matrix
#
# description:
# Add motif_feature table, and associated link table

DROP TABLE IF EXISTS `motif_feature`;
CREATE TABLE `motif_feature` (
  `motif_feature_id` int(10) unsigned NOT NULL auto_increment,
  `binding_matrix_id` INT(10) unsigned NOT NULL,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(10) unsigned NOT NULL,
  `seq_region_end` int(10) unsigned NOT NULL,
  `seq_region_strand` tinyint(1) NOT NULL,
  `display_label` varchar(60) default NULL,
  `score` double default NULL,
  PRIMARY KEY  (`motif_feature_id`),
  KEY `seq_region_idx` (`seq_region_id`,`seq_region_start`),
  KEY `binding_matrix_idx` (`binding_matrix_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


-- Add motif_id/binding_matrix_id here
-- move/replicate feature_type_id to binding_matrix

-- analysis or type for pwm should be in the binding_matrix table
-- should we capture analysis here to i.e. MOODS?

DROP TABLE IF EXISTS `associated_motif_feature`;
CREATE TABLE `associated_motif_feature` (
   `annotated_feature_id` int(10) unsigned NOT NULL,
   `motif_feature_id` int(10) unsigned NOT NULL,
   PRIMARY KEY  (`annotated_feature_id`, `motif_feature_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- also load pwm_features as reg_attrs to avoid more queries when drawing reg_feat track?
-- Or store the precomputed start stop structure as a BLOB for display?



-- pwm_feature to feature_set/cell_type may be 1 to many relationship
-- pwm_feature to annotated_feature may be many to 1 relationship
-- remove feature_set_id or change to cell_type_id?
-- cell_type style query will have to be done via query extension to feature_set using cell_type_id.

DROP TABLE IF EXISTS `binding_matrix`;
CREATE  TABLE `binding_matrix` (
 `binding_matrix_id` INT(10) unsigned NOT NULL auto_increment,
 `name` VARCHAR(45) NOT NULL,
 `type` VARCHAR(45) NOT NULL,
 `feature_type_id` int(10) unsigned NOT NULL,
 `frequencies` TEXT NOT NULL,
 `description` VARCHAR(255) NULL,
 PRIMARY KEY (`binding_matrix_id`) ,
 KEY `name_type_idx` (`name`, `type`),
 KEY `feature_type_idx` (`feature_type_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- Need to add AVG_ROW_LENGTH here for free text/blob field.
-- frequencies to be recast as blob
-- change type to enum?


-- update associated_feature_type to handle binding_matrix
ALTER table associated_feature_type MODIFY `feature_table` enum('annotated','external','regulatory', 'binding_matrix');


# patch identifier
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_59_60_b.sql|motif_feature_binding_matrix');

