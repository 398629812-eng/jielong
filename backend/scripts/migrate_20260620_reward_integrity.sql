-- Reward and withdrawal integrity migration (2026-06-20)
-- Safe to run repeatedly on MySQL 8.0+.

SET @index_exists = (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'ad_records'
    AND index_name = 'uq_ad_records_transaction_id'
);

SET @migration_sql = IF(
  @index_exists = 0,
  'ALTER TABLE ad_records ADD UNIQUE KEY uq_ad_records_transaction_id (transaction_id)',
  'SELECT ''uq_ad_records_transaction_id already exists'' AS message'
);

PREPARE migration_statement FROM @migration_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;
