-- ============================================================
-- 成语接龙游戏数据库初始化脚本（init_db.sql）
-- --------------------------------------------------
-- 使用前请先创建数据库：CREATE DATABASE jielong CHARACTER SET utf8mb4;
-- 然后执行：USE jielong; SOURCE init_db.sql;
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- 1. 用户表 users
-- ------------------------------------------------------------
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  phone VARCHAR(20) UNIQUE,
  openid VARCHAR(64) UNIQUE,
  nickname VARCHAR(50),
  avatar VARCHAR(255),
  password_hash VARCHAR(255),           -- 密码哈希（bcrypt），普通用户可空，admin 需设置
  gold INT DEFAULT 0,
  total_withdrawn INT DEFAULT 0,
  hints INT DEFAULT 3,
  is_guest TINYINT DEFAULT 1,
  is_banned TINYINT DEFAULT 0,
  last_sign_in_date DATE,
  consecutive_sign_in INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 2. 金币流水表 gold_records
-- ------------------------------------------------------------
DROP TABLE IF EXISTS gold_records;
CREATE TABLE gold_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  amount INT NOT NULL,
  type ENUM('ad_watch','game','record','sign_in','spin','task','withdraw','hint') NOT NULL,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 3. 提现记录表 withdrawals
-- ------------------------------------------------------------
DROP TABLE IF EXISTS withdrawals;
CREATE TABLE withdrawals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  gold_amount INT NOT NULL,
  rmb_amount DECIMAL(10,2) NOT NULL,
  method ENUM('wechat','alipay') NOT NULL,
  account_info VARCHAR(100),
  status ENUM('pending','approved','rejected','paid') DEFAULT 'pending',
  reject_reason VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 4. 广告观看记录表 ad_records
-- ------------------------------------------------------------
DROP TABLE IF EXISTS ad_records;
CREATE TABLE ad_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  ad_type VARCHAR(20) NOT NULL,
  platform VARCHAR(20),
  transaction_id VARCHAR(255),
  UNIQUE KEY uq_ad_records_transaction_id (transaction_id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 5. 游戏记录表 game_records
-- ------------------------------------------------------------
DROP TABLE IF EXISTS game_records;
CREATE TABLE game_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  difficulty ENUM('easy','normal','hard') NOT NULL,
  rounds INT NOT NULL,
  idiom_chain JSON NOT NULL,
  is_record TINYINT DEFAULT 0,
  score INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_rounds (rounds)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 6. 每日任务领取记录表 task_claims
-- ------------------------------------------------------------
DROP TABLE IF EXISTS task_claims;
CREATE TABLE task_claims (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  task_key VARCHAR(50) NOT NULL,
  reward INT NOT NULL,
  claim_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_task_claim_daily (user_id, task_key, claim_date),
  INDEX idx_task_claim_user_date (user_id, claim_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 6. 系统配置表 configs
-- ------------------------------------------------------------
DROP TABLE IF EXISTS configs;
CREATE TABLE configs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  `key` VARCHAR(50) UNIQUE NOT NULL,
  value TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 7. 系统公告表 announcements
-- ------------------------------------------------------------
DROP TABLE IF EXISTS announcements;
CREATE TABLE announcements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  content TEXT NOT NULL,
  is_active TINYINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 8. 成语表 idioms（供管理后台管理，与内存加载的 JSON 独立）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS idioms;
CREATE TABLE idioms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  idiom VARCHAR(50) NOT NULL,
  pinyin VARCHAR(100),
  pinyin_no_tones VARCHAR(100),
  first_char VARCHAR(10),
  first_pinyin VARCHAR(50),
  first_pinyin_no_tone VARCHAR(50),
  last_char VARCHAR(10),
  last_pinyin VARCHAR(50),
  last_pinyin_no_tone VARCHAR(50),
  meaning TEXT,
  UNIQUE KEY uk_idiom (idiom)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 插入初始数据
-- ============================================================

-- ------------------------------------------------------------
-- 1. 初始配置 configs
-- ------------------------------------------------------------
INSERT INTO configs (`key`, value) VALUES
('ad_gold_reward', '500'),
('gold_to_rmb', '10000'),
('withdraw_min', '10000'),
('withdraw_max', '50000'),
('daily_ad_limit', '50'),
('game_gold_per_round', '10'),
('game_gold_daily_cap', '1000'),
('record_gold_reward', '2000'),
('sign_in_base', '50'),
('withdraw_daily_limit', '3'),
('ad_test_mode', '1'),
('tencent_app_id', '1000000'),
('tencent_reward_id', 'demo_reward'),
('huawei_app_id', 'huawei_demo'),
('huawei_reward_id', 'huawei_demo_reward');

-- 管理员和测试用户不得使用仓库内固定凭据。
-- 部署后请通过受控初始化流程生成 bcrypt 哈希并创建管理员。

-- ------------------------------------------------------------
-- 4. 测试公告
-- ------------------------------------------------------------
INSERT INTO announcements (title, content, is_active) VALUES
('欢迎来到成语接龙', '恭喜您发现了一款有趣的休闲益智游戏！通过接龙成语赢取金币，金币可提现到微信或支付宝。每日签到、观看广告、刷新游戏记录均可获得丰厚奖励。祝您游戏愉快！', 1),
('提现规则说明', '金币达到 10000 即可申请提现（1 元）。单笔最高 5 元，每日最多 3 次。提现申请将在 1-3 个工作日内审核完成。', 1),
('防作弊公告', '系统已启用多维度防作弊检测，包括但不限于广告次数上限、设备指纹、IP 监控等。请文明游戏，违规账号将被封禁。', 1),
('版本更新 v1.0', '成语接龙测试版已更新，包含常用成语库和简单、普通、困难三种难度。', 1);

-- ============================================================
-- 初始化完成
-- ============================================================
