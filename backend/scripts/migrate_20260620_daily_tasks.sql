-- Daily task claims migration (2026-06-20)
-- Safe to run repeatedly on MySQL 8.0+.

CREATE TABLE IF NOT EXISTS task_claims (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  task_key VARCHAR(50) NOT NULL,
  reward INT NOT NULL,
  claim_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_task_claim_daily (user_id, task_key, claim_date),
  INDEX idx_task_claim_user_date (user_id, claim_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
