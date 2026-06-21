/**
 * 提现路由（withdraw.js）
 * 提供：提交提现申请、获取提现配置
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const { queryOne, execute, query } = require('../models');
const { success, error } = require('../utils/response');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// 用户接口需登录
router.use('/apply', authMiddleware);
router.use('/config', authMiddleware);

/**
 * POST /api/withdraw/apply
 * 提交提现申请
 * Body: { amount: number, method: 'wechat'|'alipay', account_info: string }
 * 校验：余额充足、达到最低门槛、不超过单笔上限、金额为整数元
 */
router.post('/apply',
  body('amount').isInt({ min: 1 }).withMessage('提现金额必须是正整数（元）'),
  body('method').isIn(['wechat', 'alipay']).withMessage('提现方式必须是 wechat 或 alipay'),
  body('account_info').notEmpty().withMessage('请填写账号信息'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { amount, method, account_info } = req.body;
    const userId = req.user.userId;

    // 1. 查询用户余额
    const user = await queryOne(
      `SELECT gold, total_withdrawn, is_guest FROM users WHERE id = ?`,
      [userId]
    );
    if (!user) {
      return error(res, '用户不存在');
    }
    if (user.is_guest) {
      return error(res, '游客模式不能提现，请先绑定手机号');
    }

    // 2. 查询提现配置
    const configRows = await query(`SELECT \`key\`, value FROM configs WHERE \`key\` IN ('gold_to_rmb', 'withdraw_min', 'withdraw_max', 'withdraw_daily_limit')`);
    const configs = {};
    for (const row of configRows) {
      configs[row.key] = parseInt(row.value, 10);
    }

    const goldToRmb = configs.gold_to_rmb || 10000; // 10000 金币 = 1 元
    const withdrawMin = configs.withdraw_min || 10000; // 最低 1 元
    const withdrawMax = configs.withdraw_max || 50000; // 最高 5 元
    const dailyLimit = configs.withdraw_daily_limit || 3; // 每日最多 3 次

    // 3. 校验：金额必须是整数元（即金币数为 gold_to_rmb 的整数倍）
    const goldAmount = amount * goldToRmb;
    if (goldAmount % goldToRmb !== 0) {
      return error(res, '提现金额必须是整数元');
    }

    // 4. 校验：余额是否充足
    if (user.gold < goldAmount) {
      return error(res, '金币余额不足');
    }

    // 5. 校验：最低门槛
    if (goldAmount < withdrawMin) {
      return error(res, `最低提现金额为 ${withdrawMin / goldToRmb} 元`);
    }

    // 6. 校验：单笔上限
    if (goldAmount > withdrawMax) {
      return error(res, `单笔提现上限为 ${withdrawMax / goldToRmb} 元`);
    }

    // 7. 校验：每日次数限制
    const today = new Date().toISOString().slice(0, 10);
    const todayCountRows = await query(
      `SELECT COUNT(*) AS cnt FROM withdrawals
       WHERE user_id = ? AND DATE(created_at) = ? AND status IN ('pending', 'approved', 'paid')`,
      [userId, today]
    );
    if (todayCountRows[0].cnt >= dailyLimit) {
      return error(res, `今日提现次数已达上限（${dailyLimit}次）`);
    }

    // 8. 扣除金币并创建提现记录（使用事务）
    const rmbAmount = amount; // 1 元 = 1 RMB
    const { transaction } = require('../models');
    try {
      await transaction(async (conn) => {
        // 扣除金币
        const [balanceResult] = await conn.execute(
          `UPDATE users SET gold = gold - ? WHERE id = ? AND gold >= ?`,
          [goldAmount, userId, goldAmount]
        );
        if (balanceResult.affectedRows !== 1) {
          throw new Error('金币余额不足');
        }

        // 创建提现记录
        await conn.execute(
          `INSERT INTO withdrawals (user_id, gold_amount, rmb_amount, method, account_info, status)
           VALUES (?, ?, ?, ?, ?, 'pending')`,
          [userId, goldAmount, rmbAmount, method, account_info]
        );
      });

      return success(res, null, '提现申请已提交，请等待审核');
    } catch (err) {
      console.error('提现申请失败:', err.message);
      return error(res, '提现申请失败，请稍后重试');
    }
  }
);

/**
 * GET /api/withdraw/config
 * 返回提现配置（门槛、比例、上限、次数限制）
 */
router.get('/config', async (req, res) => {
  const configRows = await query(`SELECT \`key\`, value FROM configs WHERE \`key\` IN ('gold_to_rmb', 'withdraw_min', 'withdraw_max', 'withdraw_daily_limit')`);
  const configs = {};
  for (const row of configRows) {
    configs[row.key] = parseInt(row.value, 10);
  }

  const goldToRmb = configs.gold_to_rmb || 10000;

  return success(res, {
    gold_to_rmb: goldToRmb,
    min_rmb: (configs.withdraw_min || 10000) / goldToRmb,
    max_rmb: (configs.withdraw_max || 50000) / goldToRmb,
    daily_limit: configs.withdraw_daily_limit || 3,
    withdraw_min: configs.withdraw_min || 10000,
    withdraw_max: configs.withdraw_max || 50000
  });
});

module.exports = router;
