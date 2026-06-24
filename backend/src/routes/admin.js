/**
 * 管理后台路由（admin.js）
 * 所有接口前缀 /api/admin，需管理员权限
 * 提供：仪表盘、用户管理、金币流水、提现审核、配置管理、成语库管理、公告管理、管理员登录
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const { query, queryOne, execute, paginate, transaction } = require('../models');
const { success, error, forbidden } = require('../utils/response');
const adminAuthMiddleware = require('../middleware/adminAuth');
const { adminLimiter, strictLimiter } = require('../middleware/rateLimiter');
const { signAdminToken } = require('../utils/jwt');
const dayjs = require('dayjs');

const router = express.Router();

const AD_PLATFORM_LABELS = {
  tencent: '优量汇',
  youlianghui: '优量汇',
  pangolin: '穿山甲',
  chuanshanjia: '穿山甲',
  kuaishou: '快手',
  baidu: '百度',
  huawei: '华为',
  mock: '测试平台',
  unknown: '未知ADN'
};

const AD_TYPE_LABELS = {
  hint: '激励视频',
  continue: '激励视频',
  sign_in_double: '激励视频',
  spin: '激励视频',
  task: '激励视频',
  splash: '开屏',
  interstitial: '插屏全屏',
  feed: '信息流'
};

function normalizePlatform(platform) {
  return (platform || 'unknown').toString().trim().toLowerCase() || 'unknown';
}

function platformLabel(platform) {
  const key = normalizePlatform(platform);
  return AD_PLATFORM_LABELS[key] || platform || '未知ADN';
}

function adTypeLabel(adType, adFormat) {
  if (adFormat) {
    return adFormat;
  }
  return AD_TYPE_LABELS[adType] || adType || '未知类型';
}

function asNumber(value) {
  return Number(value || 0);
}

/**
 * POST /api/admin/login
 * 管理员登录（独立接口，无需 adminAuth）
 */
router.post('/login',
  strictLimiter,
  body('username').notEmpty().withMessage('请输入用户名'),
  body('password').notEmpty().withMessage('请输入密码'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { username, password } = req.body;

    const adminUsername = process.env.ADMIN_USERNAME || 'admin';
    if (username !== adminUsername) {
      return error(res, '用户名或密码错误');
    }

    const user = await queryOne(
      'SELECT id, password_hash FROM users WHERE phone = ?',
      [adminUsername]
    );

    if (!user || !user.password_hash) {
      return error(res, '用户名或密码错误');
    }

    const isValid = await bcrypt.compare(password, user.password_hash);

    if (!isValid) {
      return error(res, '用户名或密码错误');
    }

    const token = signAdminToken({ adminId: user.id, username: adminUsername, isAdmin: true });
    return success(res, { token, username: adminUsername }, '管理员登录成功');
  }
);

// 以下所有接口需要管理员权限
router.use(adminAuthMiddleware);
router.use(adminLimiter);

/**
 * GET /api/admin/dashboard
 * 仪表盘：今日活跃、新增用户、广告观看、金币发放、提现申请
 */
router.get('/dashboard', async (req, res) => {
  const today = dayjs().format('YYYY-MM-DD');

  // 今日活跃用户（有金币记录或游戏记录的用户数）
  const activeRows = await query(
    `SELECT COUNT(DISTINCT user_id) AS cnt FROM gold_records
     WHERE DATE(created_at) = ?`,
    [today]
  );

  // 今日新增用户
  const newUserRows = await query(
    `SELECT COUNT(*) AS cnt FROM users WHERE DATE(created_at) = ?`,
    [today]
  );

  // 今日广告观看次数
  const adRows = await query(
    `SELECT COUNT(*) AS cnt FROM ad_records WHERE DATE(created_at) = ?`,
    [today]
  );

  // 今日金币发放（正数合计）
  const goldRows = await query(
    `SELECT COALESCE(SUM(amount), 0) AS total FROM gold_records
     WHERE DATE(created_at) = ? AND amount > 0`,
    [today]
  );

  // 今日提现申请数和金额
  const withdrawRows = await query(
    `SELECT COUNT(*) AS cnt, COALESCE(SUM(rmb_amount), 0) AS total
     FROM withdrawals WHERE DATE(created_at) = ?`,
    [today]
  );

  // 总用户数、总金币、待审核提现数
  const totalUsers = await queryOne(`SELECT COUNT(*) AS cnt FROM users`);
  const pendingWithdrawals = await queryOne(
    `SELECT COUNT(*) AS cnt FROM withdrawals WHERE status = 'pending'`
  );
  const totalGold = await queryOne(`SELECT COALESCE(SUM(gold), 0) AS total FROM users`);

  const trendStart = dayjs().subtract(6, 'day').format('YYYY-MM-DD');
  const activeTrendRows = await query(
    `SELECT DATE(created_at) AS date, COUNT(DISTINCT user_id) AS value
     FROM gold_records WHERE created_at >= ? GROUP BY DATE(created_at)`,
    [trendStart]
  );
  const adTrendRows = await query(
    `SELECT DATE(created_at) AS date, COUNT(*) AS value
     FROM ad_records WHERE created_at >= ? GROUP BY DATE(created_at)`,
    [trendStart]
  );
  const toTrend = (rows) => {
    const values = new Map(rows.map((row) => [dayjs(row.date).format('YYYY-MM-DD'), Number(row.value)]));
    return Array.from({ length: 7 }, (_, index) => {
      const date = dayjs().subtract(6 - index, 'day').format('YYYY-MM-DD');
      return { date, value: values.get(date) || 0 };
    });
  };
  const recentGold = await query(
    `SELECT gr.id, COALESCE(NULLIF(u.nickname, ''), u.phone, CONCAT('用户', u.id)) AS nickname,
            gr.amount, gr.type, gr.created_at
     FROM gold_records gr JOIN users u ON u.id = gr.user_id
     ORDER BY gr.created_at DESC LIMIT 10`
  );
  const recentWithdrawals = await query(
    `SELECT w.id, COALESCE(NULLIF(u.nickname, ''), u.phone, CONCAT('用户', u.id)) AS nickname,
            w.rmb_amount, w.status, w.created_at
     FROM withdrawals w JOIN users u ON u.id = w.user_id
     ORDER BY w.created_at DESC LIMIT 10`
  );

  return success(res, {
    today: {
      active_users: activeRows[0].cnt,
      new_users: newUserRows[0].cnt,
      ad_count: adRows[0].cnt,
      gold_total: goldRows[0].total,
      withdraw_count: withdrawRows[0].cnt,
      withdraw_amount: withdrawRows[0].total
    },
    total: {
      users: totalUsers.cnt,
      pending_withdrawals: pendingWithdrawals.cnt,
      total_gold: totalGold.total
    },
    trends: {
      active_users: toTrend(activeTrendRows),
      ad_views: toTrend(adTrendRows)
    },
    recent_gold: recentGold,
    recent_withdrawals: recentWithdrawals
  });
});

/**
 * GET /api/admin/users
 * 用户列表 + 搜索（分页）
 * Query: page, pageSize, keyword（搜索手机号/昵称）
 */
router.get('/users', async (req, res) => {
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);
  const keyword = req.query.keyword || '';

  let baseSql = `SELECT id, phone, nickname, gold, total_withdrawn, hints, is_guest, is_banned, created_at FROM users WHERE 1=1`;
  const params = [];

  if (keyword) {
    baseSql += ` AND (phone LIKE ? OR nickname LIKE ?)`;
    params.push(`%${keyword}%`, `%${keyword}%`);
  }

  baseSql += ` ORDER BY created_at DESC`;

  const result = await paginate(baseSql, params, page, pageSize);
  return success(res, result);
});

/**
 * PUT /api/admin/users/:id/ban
 * 封禁/解封用户
 * Body: { is_banned: 0|1 }
 */
router.put('/users/:id/ban',
  body('is_banned').isInt({ min: 0, max: 1 }).withMessage('is_banned 必须是 0 或 1'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const userId = req.params.id;
    const { is_banned } = req.body;

    await execute(
      `UPDATE users SET is_banned = ? WHERE id = ?`,
      [is_banned, userId]
    );

    return success(res, null, is_banned ? '用户已封禁' : '用户已解封');
  }
);

/**
 * GET /api/admin/gold-records
 * 金币流水查询（按用户分页）
 */
router.get('/gold-records', async (req, res) => {
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);
  const userId = req.query.user_id;

  let baseSql = `SELECT gr.*, u.nickname FROM gold_records gr JOIN users u ON gr.user_id = u.id WHERE 1=1`;
  const params = [];

  if (userId) {
    baseSql += ` AND gr.user_id = ?`;
    params.push(userId);
  }

  baseSql += ` ORDER BY gr.created_at DESC`;

  const result = await paginate(baseSql, params, page, pageSize);
  return success(res, result);
});

router.get('/user-ledger', async (req, res) => {
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);
  const keyword = req.query.keyword || '';

  let baseSql = `
    SELECT
      u.id,
      u.phone,
      u.nickname,
      u.gold,
      u.total_withdrawn,
      u.hints,
      u.is_guest,
      u.is_banned,
      u.created_at,
      latest.amount AS latest_amount,
      latest.type AS latest_type,
      latest.description AS latest_description,
      latest.created_at AS latest_time,
      COALESCE(today_gold.today_gold_income, 0) AS today_gold_income,
      COALESCE(today_ads.today_ad_count, 0) AS today_ad_count,
      COALESCE(pending_withdrawals.pending_withdraw_count, 0) AS pending_withdraw_count
    FROM users u
    LEFT JOIN (
      SELECT gr.*
      FROM gold_records gr
      JOIN (
        SELECT user_id, MAX(id) AS latest_id
        FROM gold_records
        GROUP BY user_id
      ) t ON t.latest_id = gr.id
    ) latest ON latest.user_id = u.id
    LEFT JOIN (
      SELECT user_id, SUM(amount) AS today_gold_income
      FROM gold_records
      WHERE amount > 0 AND DATE(created_at) = CURDATE()
      GROUP BY user_id
    ) today_gold ON today_gold.user_id = u.id
    LEFT JOIN (
      SELECT user_id, COUNT(*) AS today_ad_count
      FROM ad_records
      WHERE DATE(created_at) = CURDATE()
      GROUP BY user_id
    ) today_ads ON today_ads.user_id = u.id
    LEFT JOIN (
      SELECT user_id, COUNT(*) AS pending_withdraw_count
      FROM withdrawals
      WHERE status = 'pending'
      GROUP BY user_id
    ) pending_withdrawals ON pending_withdrawals.user_id = u.id
    WHERE 1=1`;
  const params = [];

  if (keyword) {
    baseSql += ` AND (u.phone LIKE ? OR u.nickname LIKE ? OR CAST(u.id AS CHAR) = ?)`;
    params.push(`%${keyword}%`, `%${keyword}%`, keyword);
  }

  baseSql += ` ORDER BY u.created_at DESC`;

  const result = await paginate(baseSql, params, page, pageSize);
  return success(res, result);
});

router.get('/user-ledger/:id', async (req, res) => {
  const userId = req.params.id;
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);

  const user = await queryOne(
    `SELECT id, phone, nickname, gold, total_withdrawn, hints, is_guest, is_banned, created_at
     FROM users WHERE id = ?`,
    [userId]
  );
  if (!user) {
    return error(res, '用户不存在', 404, 404);
  }

  const records = await paginate(
    `SELECT id, user_id, amount, type, description, created_at
     FROM gold_records
     WHERE user_id = ?
     ORDER BY created_at DESC, id DESC`,
    [userId],
    page,
    pageSize
  );

  return success(res, { user, records });
});

router.get('/ad-revenue', async (req, res) => {
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);
  const platform = req.query.platform || '';
  const adType = req.query.ad_type || '';

  let baseSql = `
    SELECT
      ar.id,
      ar.user_id,
      COALESCE(NULLIF(u.nickname, ''), u.phone, CONCAT('用户', u.id)) AS username,
      u.phone,
      ar.platform,
      ar.ad_type,
      ar.ad_format,
      ar.placement_id,
      ar.transaction_id,
      ar.verify_status,
      COALESCE(ar.revenue, 0) AS revenue,
      ar.created_at
    FROM ad_records ar
    JOIN users u ON u.id = ar.user_id
    WHERE 1=1`;
  const params = [];

  if (platform) {
    baseSql += ` AND ar.platform = ?`;
    params.push(platform);
  }
  if (adType) {
    baseSql += ` AND ar.ad_type = ?`;
    params.push(adType);
  }

  baseSql += ` ORDER BY ar.created_at DESC, ar.id DESC`;

  const result = await paginate(baseSql, params, page, pageSize);
  result.list = result.list.map((row) => ({
    ...row,
    platform_label: platformLabel(row.platform),
    ad_type_label: adTypeLabel(row.ad_type, row.ad_format),
    revenue: asNumber(row.revenue)
  }));

  const summaryRows = await query(
    `SELECT
       COALESCE(SUM(revenue), 0) AS total_revenue,
       COUNT(*) AS total_count
     FROM ad_records`
  );
  const platformRows = await query(
    `SELECT COALESCE(platform, 'unknown') AS platform,
            COALESCE(SUM(revenue), 0) AS revenue,
            COUNT(*) AS count
     FROM ad_records
     GROUP BY COALESCE(platform, 'unknown')`
  );

  const byPlatform = {};
  for (const row of platformRows) {
    const key = normalizePlatform(row.platform);
    byPlatform[key] = {
      platform: key,
      label: platformLabel(row.platform),
      revenue: asNumber(row.revenue),
      count: Number(row.count || 0)
    };
  }

  return success(res, {
    summary: {
      total_revenue: asNumber(summaryRows[0]?.total_revenue),
      total_count: Number(summaryRows[0]?.total_count || 0),
      by_platform: byPlatform
    },
    records: result
  });
});

/**
 * GET /api/admin/withdrawals
 * 提现列表（按状态分页）
 */
router.get('/withdrawals', async (req, res) => {
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);
  const status = req.query.status;

  let baseSql = `SELECT w.*, u.nickname, u.phone FROM withdrawals w JOIN users u ON w.user_id = u.id WHERE 1=1`;
  const params = [];

  if (status) {
    baseSql += ` AND w.status = ?`;
    params.push(status);
  }

  baseSql += ` ORDER BY w.created_at DESC`;

  const result = await paginate(baseSql, params, page, pageSize);
  return success(res, result);
});

/**
 * PUT /api/admin/withdrawals/:id/approve
 * 通过提现：status -> paid
 */
router.put('/withdrawals/:id/approve', async (req, res) => {
  const withdrawId = req.params.id;

  try {
    await transaction(async (conn) => {
      const [rows] = await conn.execute(
        `SELECT user_id, gold_amount FROM withdrawals
         WHERE id = ? AND status = 'pending' FOR UPDATE`,
        [withdrawId]
      );
      if (rows.length === 0) {
        throw new Error('提现记录不存在或已处理');
      }

      await conn.execute(
        `UPDATE withdrawals SET status = 'paid', updated_at = NOW() WHERE id = ?`,
        [withdrawId]
      );
      await conn.execute(
        `UPDATE users SET total_withdrawn = total_withdrawn + ? WHERE id = ?`,
        [rows[0].gold_amount, rows[0].user_id]
      );
    });
    return success(res, null, '提现已通过');
  } catch (err) {
    return error(res, err.message || '提现审核失败');
  }
});

/**
 * PUT /api/admin/withdrawals/:id/reject
 * 拒绝提现：status -> rejected，需 body.reason
 */
router.put('/withdrawals/:id/reject',
  body('reason').notEmpty().withMessage('请填写拒绝原因'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const withdrawId = req.params.id;
    const { reason } = req.body;

    try {
      await transaction(async (conn) => {
        const [rows] = await conn.execute(
          `SELECT user_id, gold_amount FROM withdrawals
           WHERE id = ? AND status = 'pending' FOR UPDATE`,
          [withdrawId]
        );
        if (rows.length === 0) {
          throw new Error('提现记录不存在或已处理');
        }
        const record = rows[0];

        await conn.execute(
          `UPDATE withdrawals
           SET status = 'rejected', reject_reason = ?, updated_at = NOW()
           WHERE id = ?`,
          [reason, withdrawId]
        );
        await conn.execute(
          `UPDATE users SET gold = gold + ? WHERE id = ?`,
          [record.gold_amount, record.user_id]
        );
        await conn.execute(
          `INSERT INTO gold_records (user_id, amount, type, description)
           VALUES (?, ?, 'withdraw', ?)`,
          [record.user_id, record.gold_amount, `提现拒绝退回 +${record.gold_amount}金币，原因：${reason}`]
        );
      });

      return success(res, null, '提现已拒绝，金币已退回');
    } catch (err) {
      return error(res, err.message || '提现拒绝失败');
    }
  }
);

/**
 * GET /api/admin/configs
 * 读取所有配置
 */
router.get('/configs', async (req, res) => {
  const rows = await query(`SELECT \`key\`, value, updated_at FROM configs`);
  const configs = {};
  for (const row of rows) {
    configs[row.key] = row.value;
  }
  return success(res, configs);
});

/**
 * PUT /api/admin/configs
 * 更新配置（批量）
 * Body: { key1: value1, key2: value2, ... }
 */
router.put('/configs', async (req, res) => {
  const updates = req.body;
  if (!updates || typeof updates !== 'object') {
    return error(res, '配置参数错误');
  }

  for (const [key, value] of Object.entries(updates)) {
    await execute(
      `INSERT INTO configs (\`key\`, value) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE value = ?, updated_at = NOW()`,
      [key, String(value), String(value)]
    );
  }

  return success(res, null, '配置更新成功');
});

/**
 * GET /api/admin/idioms
 * 成语列表（搜索+分页）
 */
router.get('/idioms', async (req, res) => {
  const page = parseInt(req.query.page || '1', 10);
  const pageSize = parseInt(req.query.pageSize || '20', 10);
  const keyword = req.query.keyword || '';

  let baseSql = `SELECT * FROM idioms WHERE 1=1`;
  const params = [];

  if (keyword) {
    baseSql += ` AND (idiom LIKE ? OR first_char LIKE ? OR last_char LIKE ?)`;
    params.push(`%${keyword}%`, `%${keyword}%`, `%${keyword}%`);
  }

  baseSql += ` ORDER BY id ASC`;

  const result = await paginate(baseSql, params, page, pageSize);
  return success(res, result);
});

/**
 * POST /api/admin/idioms
 * 新增成语
 */
router.post('/idioms',
  body('idiom').notEmpty().withMessage('成语不能为空'),
  body('pinyin').notEmpty().withMessage('拼音不能为空'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { idiom, pinyin, pinyin_no_tones, first_char, first_pinyin, first_pinyin_no_tone,
            last_char, last_pinyin, last_pinyin_no_tone, meaning } = req.body;

    await execute(
      `INSERT INTO idioms (idiom, pinyin, pinyin_no_tones, first_char, first_pinyin,
        first_pinyin_no_tone, last_char, last_pinyin, last_pinyin_no_tone, meaning)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [idiom, pinyin, pinyin_no_tones, first_char, first_pinyin, first_pinyin_no_tone,
       last_char, last_pinyin, last_pinyin_no_tone, meaning]
    );

    return success(res, null, '成语新增成功');
  }
);

/**
 * PUT /api/admin/idioms/:id
 * 修改成语
 */
router.put('/idioms/:id', async (req, res) => {
  const id = req.params.id;
  const { idiom, pinyin, pinyin_no_tones, first_char, first_pinyin, first_pinyin_no_tone,
          last_char, last_pinyin, last_pinyin_no_tone, meaning } = req.body;

  await execute(
    `UPDATE idioms SET
       idiom = ?, pinyin = ?, pinyin_no_tones = ?, first_char = ?, first_pinyin = ?,
       first_pinyin_no_tone = ?, last_char = ?, last_pinyin = ?,
       last_pinyin_no_tone = ?, meaning = ?
     WHERE id = ?`,
    [idiom, pinyin, pinyin_no_tones, first_char, first_pinyin, first_pinyin_no_tone,
     last_char, last_pinyin, last_pinyin_no_tone, meaning, id]
  );

  return success(res, null, '成语更新成功');
});

/**
 * DELETE /api/admin/idioms/:id
 * 删除成语
 */
router.delete('/idioms/:id', async (req, res) => {
  const id = req.params.id;
  await execute(`DELETE FROM idioms WHERE id = ?`, [id]);
  return success(res, null, '成语删除成功');
});

/**
 * POST /api/admin/idioms/import
 * 导入 JSON（解析 body 数组批量插入）
 */
router.post('/idioms/import', async (req, res) => {
  const { idioms } = req.body;
  if (!Array.isArray(idioms) || idioms.length === 0) {
    return error(res, '请提供成语数组');
  }

  const { transaction } = require('../models');
  try {
    await transaction(async (conn) => {
      for (const item of idioms) {
        await conn.execute(
          `INSERT INTO idioms (idiom, pinyin, pinyin_no_tones, first_char, first_pinyin,
            first_pinyin_no_tone, last_char, last_pinyin, last_pinyin_no_tone, meaning)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON DUPLICATE KEY UPDATE
             pinyin = VALUES(pinyin),
             pinyin_no_tones = VALUES(pinyin_no_tones),
             first_char = VALUES(first_char),
             first_pinyin = VALUES(first_pinyin),
             first_pinyin_no_tone = VALUES(first_pinyin_no_tone),
             last_char = VALUES(last_char),
             last_pinyin = VALUES(last_pinyin),
             last_pinyin_no_tone = VALUES(last_pinyin_no_tone),
             meaning = VALUES(meaning)`,
          [item.idiom, item.pinyin, item.pinyin_no_tones, item.first_char, item.first_pinyin,
           item.first_pinyin_no_tone, item.last_char, item.last_pinyin,
           item.last_pinyin_no_tone, item.meaning]
        );
      }
    });

    return success(res, { count: idioms.length }, `成功导入 ${idioms.length} 条成语`);
  } catch (err) {
    console.error('成语导入失败:', err.message);
    return error(res, '导入失败：' + err.message);
  }
});

/**
 * POST /api/admin/idioms/export
 * 导出 JSON（返回所有成语数据）
 */
router.post('/idioms/export', async (req, res) => {
  const rows = await query(`SELECT * FROM idioms ORDER BY id ASC`);
  return success(res, { idioms: rows, total: rows.length }, '导出成功');
});

/**
 * GET /api/admin/announcements
 * 公告列表
 */
router.get('/announcements', async (req, res) => {
  const rows = await query(
    `SELECT id, title, content, is_active, created_at FROM announcements ORDER BY created_at DESC`
  );
  return success(res, rows);
});

/**
 * POST /api/admin/announcements
 * 发布公告
 */
router.post('/announcements',
  body('title').notEmpty().withMessage('标题不能为空').isLength({ max: 100 }).withMessage('标题最多 100 字'),
  body('content').notEmpty().withMessage('内容不能为空'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { title, content } = req.body;
    await execute(
      `INSERT INTO announcements (title, content) VALUES (?, ?)`,
      [title, content]
    );
    return success(res, null, '公告发布成功');
  }
);

/**
 * DELETE /api/admin/announcements/:id
 * 删除公告
 */
router.delete('/announcements/:id', async (req, res) => {
  const id = req.params.id;
  await execute(`DELETE FROM announcements WHERE id = ?`, [id]);
  return success(res, null, '公告删除成功');
});

module.exports = router;
