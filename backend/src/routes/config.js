/**
 * 配置/公告路由（config.js）
 * 提供：获取前端运行配置（广告 ID、金币比例、公告等）、获取公告列表
 * 无需登录，供客户端初始化时调用
 */

const express = require('express');
const { query } = require('../models');
const { success } = require('../utils/response');

const router = express.Router();

/**
 * GET /api/config
 * 获取前端配置：广告 ID、金币兑换比例、提现门槛等
 */
router.get('/', async (req, res) => {
  // 查询所有配置项
  const configRows = await query(`SELECT \`key\`, value FROM configs`);
  const configs = {};
  for (const row of configRows) {
    configs[row.key] = row.value;
  }

  // 组装前端需要的配置对象
  const result = {
    // 广告相关（示例值，实际应替换为真实广告位 ID）
    ad: {
      tencent_app_id: configs.tencent_app_id || '1000000',
      tencent_reward_id: configs.tencent_reward_id || 'demo_reward',
      huawei_app_id: configs.huawei_app_id || 'huawei_demo',
      huawei_reward_id: configs.huawei_reward_id || 'huawei_demo_reward',
      test_mode: configs.ad_test_mode || '1' // 1=测试模式，0=正式模式
    },
    // 金币相关
    gold: {
      to_rmb: parseInt(configs.gold_to_rmb || '10000', 10), // 10000 金币 = 1 元
      per_round: parseInt(configs.game_gold_per_round || '10', 10),
      daily_cap: parseInt(configs.game_gold_daily_cap || '1000', 10),
      ad_reward: parseInt(configs.ad_gold_reward || '500', 10),
      record_reward: parseInt(configs.record_gold_reward || '2000', 10),
      sign_in_base: parseInt(configs.sign_in_base || '50', 10)
    },
    // 提现相关
    withdraw: {
      min: parseInt(configs.withdraw_min || '10000', 10), // 最低 10000 金币 = 1 元
      max: parseInt(configs.withdraw_max || '50000', 10), // 单笔最高 5 元
      daily_limit: parseInt(configs.withdraw_daily_limit || '3', 10) // 每日最多 3 次
    }
  };

  return success(res, result);
});

/**
 * GET /api/announcements
 * 获取当前有效的公告列表
 */
router.get('/announcements', async (req, res) => {
  const rows = await query(
    `SELECT id, title, content, created_at
     FROM announcements
     WHERE is_active = 1
     ORDER BY created_at DESC
     LIMIT 10`
  );

  return success(res, rows);
});

module.exports = router;
