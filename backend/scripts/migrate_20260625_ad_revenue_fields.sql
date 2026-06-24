-- Advertising revenue ledger fields (2026-06-25)
-- Safe to run repeatedly on MySQL 8.0+.

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'ad_records'
    AND column_name = 'ad_format'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE ad_records ADD COLUMN ad_format VARCHAR(30) NULL AFTER platform',
  'SELECT ''ad_format already exists'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'ad_records'
    AND column_name = 'placement_id'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE ad_records ADD COLUMN placement_id VARCHAR(80) NULL AFTER ad_format',
  'SELECT ''placement_id already exists'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'ad_records'
    AND column_name = 'callback_id'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE ad_records ADD COLUMN callback_id VARCHAR(255) NULL AFTER transaction_id',
  'SELECT ''callback_id already exists'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'ad_records'
    AND column_name = 'verify_status'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE ad_records ADD COLUMN verify_status VARCHAR(20) DEFAULT ''mock'' AFTER callback_id',
  'SELECT ''verify_status already exists'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'ad_records'
    AND column_name = 'revenue'
);
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE ad_records ADD COLUMN revenue DECIMAL(12,6) DEFAULT 0.000000 AFTER verify_status',
  'SELECT ''revenue already exists'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'ad_records'
    AND index_name = 'idx_platform_created_at'
);
SET @sql = IF(@index_exists = 0,
  'ALTER TABLE ad_records ADD INDEX idx_platform_created_at (platform, created_at)',
  'SELECT ''idx_platform_created_at already exists'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'ad_records'
    AND index_name = 'idx_ad_type_created_at'
);
SET @sql = IF(@index_exists = 0,
  'ALTER TABLE ad_records ADD INDEX idx_ad_type_created_at (ad_type, created_at)',
  'SELECT ''idx_ad_type_created_at already exists'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
