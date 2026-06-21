/**
 * 认证路由（auth.js）
 * 提供：发送验证码、手机号登录、微信登录、游客登录、绑定手机、刷新 Token
 * 其中短信验证码和微信登录使用模拟接口（实际需接入第三方 SDK）
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { query, execute, queryOne } = require('../models');
const { signUserToken } = require('../utils/jwt');
const { success, error } = require('../utils/response');
const { strictLimiter } = require('../middleware/rateLimiter');
const authMiddleware = require('../middleware/auth');
const dayjs = require('dayjs');

const router = express.Router();

// 内存存储验证码（模拟，生产环境应使用 Redis）
const smsCodeStore = new Map();

/**
 * POST /api/auth/send-sms
 * 发送手机验证码（模拟实现：直接打印验证码到控制台，实际生产需接入 SMS 网关）
 */
router.post('/send-sms',
  strictLimiter,
  body('phone').isMobilePhone('zh-CN').withMessage('请输入有效的手机号'),
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { phone } = req.body;
    // 生成 4 位数字验证码
    const code = Math.floor(1000 + Math.random() * 9000).toString();
    // 存储验证码，5 分钟有效
    smsCodeStore.set(phone, { code, expires: Date.now() + 5 * 60 * 1000 });

    console.log(`📱 [模拟短信] 手机号 ${phone} 的验证码是: ${code}`);
    const data = process.env.NODE_ENV === 'production' ? null : { test_code: code };
    return success(res, data, process.env.NODE_ENV === 'production'
      ? '验证码已发送'
      : '测试验证码已生成');
  }
);

/**
 * POST /api/auth/phone-login
 * 手机号 + 验证码登录
 * 如果用户不存在，自动创建新用户（游客转正或新注册）
 */
router.post('/phone-login',
  strictLimiter,
  body('phone').isMobilePhone('zh-CN').withMessage('请输入有效的手机号'),
  body('code').isLength({ min: 4, max: 4 }).isNumeric().withMessage('验证码格式错误'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { phone, code } = req.body;

    // 验证验证码
    const stored = smsCodeStore.get(phone);
    if (!stored || stored.code !== code || Date.now() > stored.expires) {
      return error(res, '验证码错误或已过期', 1001);
    }

    // 清除已使用的验证码
    smsCodeStore.delete(phone);

    // 查询用户是否存在
    let user = await queryOne(`SELECT * FROM users WHERE phone = ?`, [phone]);

    if (!user) {
      // 自动创建新用户
      const result = await execute(
        `INSERT INTO users (phone, nickname, is_guest, gold, hints)
         VALUES (?, ?, 0, 0, 3)`,
        [phone, `用户${phone.slice(-4)}`]
      );
      user = {
        id: result.insertId,
        phone,
        nickname: `用户${phone.slice(-4)}`,
        gold: 0,
        hints: 3,
        is_guest: 0
      };
    }

    // 检查是否被封禁
    if (user.is_banned) {
      return error(res, '账号已被封禁，请联系客服', 1003);
    }

    // 签发 JWT
    const token = signUserToken({ userId: user.id, phone: user.phone });

    return success(res, {
      token,
      user: {
        id: user.id,
        phone: user.phone,
        nickname: user.nickname,
        avatar: user.avatar,
        gold: user.gold,
        hints: user.hints,
        is_guest: user.is_guest
      }
    }, '登录成功');
  }
);

/**
 * POST /api/auth/wechat-login
 * 微信授权登录（模拟接口，实际需接入微信开放平台）
 */
router.post('/wechat-login', async (req, res) => {
  const { code, openid } = req.body;

  // 模拟：如果没有 openid，则根据 code 生成一个模拟 openid
  const mockOpenid = openid || `mock_${code || uuidv4()}`;

  let user = await queryOne(`SELECT * FROM users WHERE openid = ?`, [mockOpenid]);

  if (!user) {
    const result = await execute(
      `INSERT INTO users (openid, nickname, is_guest, gold, hints)
       VALUES (?, ?, 0, 0, 3)`,
      [mockOpenid, `微信用户${mockOpenid.slice(-6)}`]
    );
    user = {
      id: result.insertId,
      openid: mockOpenid,
      nickname: `微信用户${mockOpenid.slice(-6)}`,
      gold: 0,
      hints: 3,
      is_guest: 0
    };
  }

  if (user.is_banned) {
    return error(res, '账号已被封禁，请联系客服', 1003);
  }

  const token = signUserToken({ userId: user.id, openid: user.openid });

  return success(res, {
    token,
    user: {
      id: user.id,
      nickname: user.nickname,
      avatar: user.avatar,
      gold: user.gold,
      hints: user.hints,
      is_guest: user.is_guest
    }
  }, '登录成功');
});

/**
 * POST /api/auth/guest-login
 * 游客登录：生成临时唯一 ID，创建游客账号
 */
router.post('/guest-login', async (req, res) => {
  const guestId = uuidv4();

  const result = await execute(
    `INSERT INTO users (nickname, is_guest, gold, hints)
     VALUES (?, 1, 0, 3)`,
    [`游客${guestId.slice(0, 8)}`]
  );

  const user = {
    id: result.insertId,
    nickname: `游客${guestId.slice(0, 8)}`,
    gold: 0,
    hints: 3,
    is_guest: 1
  };

  const token = signUserToken({ userId: user.id, isGuest: true });

  return success(res, {
    token,
    user: {
      id: user.id,
      nickname: user.nickname,
      gold: user.gold,
      hints: user.hints,
      is_guest: 1
    }
  }, '游客登录成功');
});

/**
 * POST /api/auth/bind-phone
 * 游客绑定手机号：将游客账号与手机号关联
 */
router.post('/bind-phone',
  authMiddleware,
  body('phone').isMobilePhone('zh-CN').withMessage('请输入有效的手机号'),
  body('code').isLength({ min: 4, max: 4 }).isNumeric().withMessage('验证码格式错误'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { phone, code } = req.body;
    const userId = req.user.userId;

    // 验证验证码
    const stored = smsCodeStore.get(phone);
    if (!stored || stored.code !== code || Date.now() > stored.expires) {
      return error(res, '验证码错误或已过期', 1001);
    }
    smsCodeStore.delete(phone);

    // 检查手机号是否已被其他账号绑定
    const existing = await queryOne(`SELECT id FROM users WHERE phone = ? AND id != ?`, [phone, userId]);
    if (existing) {
      return error(res, '该手机号已被绑定，请直接登录', 1002);
    }

    // 更新当前用户
    await execute(
      `UPDATE users SET phone = ?, is_guest = 0, updated_at = NOW() WHERE id = ?`,
      [phone, userId]
    );

    return success(res, null, '手机号绑定成功');
  }
);

/**
 * GET /api/auth/refresh
 * 刷新 JWT Token：延长登录有效期
 */
router.get('/refresh', authMiddleware, async (req, res) => {
  const userId = req.user.userId;
  const user = await queryOne(`SELECT id, phone, openid FROM users WHERE id = ?`, [userId]);

  if (!user) {
    return error(res, '用户不存在', 1004);
  }

  const newToken = signUserToken({ userId: user.id, phone: user.phone, openid: user.openid });
  return success(res, { token: newToken }, 'Token 刷新成功');
});

module.exports = router;
