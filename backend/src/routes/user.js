/**
 * 用户路由（user.js）
 * 提供：获取个人资料、更新资料、金币流水、游戏历史、提现记录
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const { queryOne, query, paginate } = require('../models');
const { success, error } = require('../utils/response');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// 所有用户路由需要登录
router.use(authMiddleware);

/**
 * GET /api/user/profile
 * 获取个人资料（金币、提示、昵称、签到信息等）
 */
router.get('/profile', async (req, res) => {
  const userId = req.user.userId;
  const user = await queryOne(
    `SELECT id, phone, nickname, avatar, gold, total_withdrawn, hints,
            is_guest, last_sign_in_date, consecutive_sign_in, created_at
     FROM users WHERE id = ?`,
    [userId]
  );

  if (!user) {
    return error(res, '用户不存在', 404);
  }

  return success(res, user);
});

/**
 * PUT /api/user/profile
 * 更新昵称/头像
 */
router.put('/profile',
  body('nickname').optional().isLength({ min: 1, max: 20 }).withMessage('昵称长度为 1-20 个字符'),
  body('avatar').optional().isURL().withMessage('头像必须是有效 URL'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const userId = req.user.userId;
    const { nickname, avatar } = req.body;

    const updates = [];
    const params = [];
    if (nickname !== undefined) {
      updates.push('nickname = ?');
      params.push(nickname);
    }
    if (avatar !== undefined) {
      updates.push('avatar = ?');
      params.push(avatar);
    }

    if (updates.length === 0) {
      return error(res, '没有可更新的字段');
    }

    params.push(userId);
    await queryOne(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, params);

    return success(res, null, '资料更新成功');
  }
);

/**
 * GET /api/user/gold-history
 * 金币流水记录（分页）
 */
router.get('/gold-history', async (req, res) => {
  const userId = req.user.userId;
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);

  const result = await paginate(
    `SELECT id, amount, type, description, created_at
     FROM gold_records WHERE user_id = ? ORDER BY created_at DESC`,
    [userId],
    page,
    pageSize
  );

  return success(res, result);
});

/**
 * GET /api/user/game-history
 * 游戏历史记录（分页）
 */
router.get('/game-history', async (req, res) => {
  const userId = req.user.userId;
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);

  const result = await paginate(
    `SELECT id, difficulty, rounds, is_record, score, created_at
     FROM game_records WHERE user_id = ? ORDER BY created_at DESC`,
    [userId],
    page,
    pageSize
  );

  return success(res, result);
});

/**
 * GET /api/user/withdraw-history
 * 提现记录
 */
router.get('/withdraw-history', async (req, res) => {
  const userId = req.user.userId;
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);

  const result = await paginate(
    `SELECT id, gold_amount, rmb_amount, method, account_info, status, reject_reason, created_at, updated_at
     FROM withdrawals WHERE user_id = ? ORDER BY created_at DESC`,
    [userId],
    page,
    pageSize
  );

  return success(res, result);
});

module.exports = router;
