-- Daily spin limit configuration (2026-06-25)
-- Safe to run repeatedly.

INSERT INTO configs (`key`, value)
VALUES ('spin_daily_limit', '1')
ON DUPLICATE KEY UPDATE value = value;
