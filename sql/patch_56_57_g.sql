# patch_56_57_g.sql
#
# title: rename_experimental_set_tables
#
# description:
# Change experimental_(sub)set table names


# Redefine experimental_subset table

CREATE TABLE `input_subset` (
  `input_subset_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `input_set_id` int(10) unsigned NOT NULL,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`input_subset_id`),
  UNIQUE KEY `set_name_dx` (`input_set_id`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=30; 




insert into input_subset select * from experimental_subset;

# drop the old table
DROP table experimental_subset;

CREATE TABLE `input_set` (
  `input_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `experiment_id` int(10) unsigned DEFAULT NULL,
  `feature_type_id` int(10) unsigned DEFAULT NULL,
  `cell_type_id` int(10) unsigned DEFAULT NULL,
  `format` varchar(20) DEFAULT NULL,
  `vendor` varchar(40) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`input_set_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `experiment_idx` (`experiment_id`),
  KEY `feature_type_idx` (`feature_type_id`),
  KEY `cell_type_idx` (`cell_type_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=30;


insert into input_set select * from experimental_set;

# drop the old table
DROP table experimental_set;

# Now update supporting_set accordingly

ALTER TABLE supporting_set modify `type` enum('result','feature','experimental', 'input') DEFAULT NULL;
update supporting_set set type='input' where type='experimental';
ALTER TABLE supporting_set modify `type` enum('result','feature','input') DEFAULT NULL;


# patch identifier
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_56_57_g.sql|rename_experimentalset_tables');


 