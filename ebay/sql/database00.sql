DROP TABLE IF EXISTS `ebay_categories`;
CREATE TABLE `ebay_categories` (
  `id` int(10) unsigned NOT NULL default '0',
  `parent_id` int(10) unsigned NOT NULL default '0',
  `level` tinyint(3) unsigned NOT NULL default '0',
  `name` varchar(64) NOT NULL default '',
  `leaf` tinyint(3) unsigned NOT NULL default '0',
  `item_specifics_enabled` tinyint(3) unsigned NOT NULL default '0',
  `catalog_enabled` tinyint(3) unsigned NOT NULL default '0',
  `product_search_page_available` tinyint(3) unsigned NOT NULL default '0',
  `site` tinyint(4) NOT NULL default '0',
  UNIQUE KEY `id` (`id`),
  KEY `parent_id` (`parent_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ebay_category_custom_specifics`;
CREATE TABLE `ebay_category_custom_specifics` (
  `parent_id` int(10) unsigned NOT NULL default '0',
  UNIQUE KEY `parent_id` (`parent_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ebay_category_2_cs`;
CREATE TABLE `ebay_category_2_cs` (
    `category_id` int(10) unsigned NOT NULL default '0',
    `attribute_set_id` int(10) unsigned NOT NULL default '0',
    PRIMARY KEY (`category_id`, `attribute_set_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ebay_attribute_sets`;
CREATE TABLE `ebay_attribute_sets` (
    `id` int(10) unsigned NOT NULL default '0',
    `version` varchar(10) NOT NULL default '',
    `name` varchar(64) NOT NULL default '',
    PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ebay_category_2_product_finder`;
CREATE TABLE `ebay_category_2_product_finder` (
    `category_id` int(10) unsigned NOT NULL default '0',
    `product_finder_id` int(10) unsigned NOT NULL default '0',
    PRIMARY KEY (`category_id`, `product_finder_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ebay_product_finders`;
CREATE TABLE `ebay_product_finders` (
    `id` int(10) unsigned NOT NULL default '0',
    `buy_side` tinyint(3) unsigned NOT NULL default '0',
    `data_present` tinyint(3) unsigned NOT NULL default '0',
    PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ebay_attribute_set_2_attribute`;
CREATE TABLE `ebay_attribute_set_2_attribute` (
    `attribute_set_id` int(10) unsigned NOT NULL default '0',
    `attribute_id` int(10) unsigned NOT NULL default '0',
    PRIMARY KEY (`attribute_set_id`, `attribute_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ebay_attributes`;
CREATE TABLE `ebay_attributes` (
    `id` int(10) unsigned NOT NULL default '0',
    `name` varchar(64) NOT NULL default '',
    `display_sequence` int(10) unsigned NOT NULL default '0',
    `visible` tinyint(3) unsigned NOT NULL default '0',
    PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
