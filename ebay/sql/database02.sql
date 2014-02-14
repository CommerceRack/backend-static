ALTER TABLE `ebay_categories` ADD COLUMN (
  `create_timestamp` TIMESTAMP NULL
);

ALTER TABLE `ebay_category_custom_specifics` ADD COLUMN (
  `create_timestamp` TIMESTAMP NULL
);

ALTER TABLE `ebay_category_2_cs` ADD COLUMN (
  `create_timestamp` TIMESTAMP NULL
);

ALTER TABLE `ebay_attribute_sets` ADD COLUMN (
  `create_timestamp` TIMESTAMP NULL
);

ALTER TABLE `ebay_category_2_product_finder` ADD COLUMN (
  `create_timestamp` TIMESTAMP NULL
);

ALTER TABLE `ebay_product_finders` ADD COLUMN (
  `create_timestamp` TIMESTAMP NULL
);

ALTER TABLE `ebay_attribute_set_2_attribute` ADD COLUMN (
  `create_timestamp` TIMESTAMP NULL
);

ALTER TABLE `ebay_attributes` ADD COLUMN (
  `create_timestamp` TIMESTAMP NULL
);
