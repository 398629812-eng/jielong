/**
 * 金币/广告路由（gold.js）
 * 提供：广告奖励、游戏结算、签到、转盘、使用提示等金币相关操作
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const { queryOne, execute, query, transaction } = require('../models');
const { success, error } = require('../utils/response');
const authMiddleware = require('../middleware/auth');
const { grantAdReward } = require('../services/adReward');

const router = express.Router();

router.use(authMiddleware);

const DAILY_TASKS = {
  idioms_10: { title: '接对10个成语', target: 10, reward: 100 },
  ads_3: { title: '观看3个广告', target: 3, reward: 200 },
  rounds_5: { title: '单局达到5轮', target: 5, reward: 300 },
  new_record: { title: '刷新个人纪录', target: 1, reward: 500 }
};

async function getTaskProgress(userId, taskKey, db = query) {
  let sql;
  switch (taskKey) {
    case 'idioms_10':
      sql = `SELECT COALESCE(SUM(rounds), 0) AS current
             FROM game_records WHERE user_id = ? AND DATE(created_at) = CURDATE()`;
      break;
    case 'ads_3':
      sql = `SELECT COUNT(*) AS current
             FROM ad_records WHERE user_id = ? AND DATE(created_at) = CURDATE()`;
      break;
    case 'rounds_5':
      sql = `SELECT COALESCE(MAX(rounds), 0) AS current
             FROM game_records WHERE user_id = ? AND DATE(created_at) = CURDATE()`;
      break;
    case 'new_record':
      sql = `SELECT COUNT(*) AS current FROM game_records
             WHERE user_id = ? AND is_record = 1 AND DATE(created_at) = CURDATE()`;
      break;
    default:
      return null;
  }
  const rows = await db(sql, [userId]);
  return parseInt(rows[0].current, 10) || 0;
}

async function buildTaskList(userId) {
  const claimedRows = await query(
    `SELECT task_key FROM task_claims WHERE user_id = ? AND claim_date = CURDATE()`,
    [userId]
  );
  const claimedKeys = new Set(claimedRows.map(row => row.task_key));

  return Promise.all(Object.entries(DAILY_TASKS).map(async ([key, task]) => {
    const rawCurrent = await getTaskProgress(userId, key);
    const current = Math.min(rawCurrent, task.target);
    const claimed = claimedKeys.has(key);
    return {
      key,
      title: task.title,
      target: task.target,
      current,
      reward: task.reward,
      claimed,
      claimable: !claimed && rawCurrent >= task.target
    };
  }));
}

const SPIN_PRIZES = [0, 10, 20, 50, 100, 200, 500, 1000];
const SPIN_WEIGHTS = [30, 25, 20, 15, 5, 3, 1.5, 0.5];
const DEFAULT_DAILY_SPIN_LIMIT = 1;

function drawSpinPrize() {
  const totalWeight = SPIN_WEIGHTS.reduce((a, b) => a + b, 0);
  let random = Math.random() * totalWeight;

  for (let i = 0; i < SPIN_PRIZES.length; i++) {
    random -= SPIN_WEIGHTS[i];
    if (random <= 0) {
      return SPIN_PRIZES[i];
    }
  }

  return 0;
}

async function getDailySpinLimit(db = query) {
  const rows = await db(
    `SELECT value FROM configs WHERE \`key\` = 'spin_daily_limit' LIMIT 1`
  );
  const value = rows.length > 0 ? parseInt(rows[0].value, 10) : NaN;
  return Number.isInteger(value) && value >= 0 ? value : DEFAULT_DAILY_SPIN_LIMIT;
}

async function getTodaySpinCount(userId, db = query) {
  const rows = await db(
    `SELECT COUNT(*) AS cnt
     FROM gold_records
     WHERE user_id = ? AND type = 'spin' AND DATE(created_at) = CURDATE()`,
    [userId]
  );
  return parseInt(rows[0].cnt, 10) || 0;
}

/**
 * POST /api/gold/ad-reward
 * 广告观看完成奖励
 * Body: { ad_type: string, transaction_id?: string, platform?: string }
 */
router.post('/ad-reward',
  body('ad_type').isIn(['hint', 'continue', 'sign_in_double', 'spin', 'task']).withMessage('无效的广告类型'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { ad_type, transaction_id, platform } = req.body;
    const userId = req.user.userId;
    const ip = req.ip || req.headers['x-forwarded-for'] || 'unknown';

    const result = await grantAdReward(userId, ad_type, transaction_id, platform, { query, execute, queryOne, transaction: require('../models').transaction }, ip);

    if (!result.ok) {
      return error(res, result.message);
    }

    return success(res, { gold: result.gold, hints: result.hints }, result.message);
  }
);

// 旧客户端兼容门：游戏奖励必须由 /game/end 根据服务端局内状态结算。
router.post('/game-reward', (req, res) => error(
  res,
  '该接口已停用，请通过 /api/game/end 结算游戏奖励',
  410,
  410
));

/**
 * POST /api/gold/sign-in
 * 每日签到
 * 返回签到获得的金币，及是否连续签到
 */
router.post('/sign-in', async (req, res) => {
  const userId = req.user.userId;

  const result = await transaction(async (conn) => {
    const [users] = await conn.execute(
      `SELECT DATE_FORMAT(last_sign_in_date, '%Y-%m-%d') AS last_sign_in_date,
              consecutive_sign_in,
              DATE_FORMAT(CURDATE(), '%Y-%m-%d') AS today,
              DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m-%d') AS yesterday
       FROM users WHERE id = ? FOR UPDATE`,
      [userId]
    );
    const user = users[0];
    if (!user) {
      return { missing: true };
    }
    if (user.last_sign_in_date === user.today) {
      return { alreadySigned: true };
    }

    const [configRows] = await conn.execute(
      `SELECT value FROM configs WHERE \`key\` = 'sign_in_base'`
    );
    const baseGold = configRows.length > 0
      ? parseInt(configRows[0].value, 10)
      : 50;
    const isConsecutive = user.last_sign_in_date === user.yesterday;
    const consecutive = isConsecutive
      ? (user.consecutive_sign_in || 0) + 1
      : 1;
    const bonus = consecutive % 7 === 0 ? Math.floor(baseGold * 0.5) : 0;
    const totalGold = baseGold + bonus;

    await conn.execute(
      `UPDATE users
       SET gold = gold + ?, last_sign_in_date = CURDATE(), consecutive_sign_in = ?
       WHERE id = ?`,
      [totalGold, consecutive, userId]
    );
    await conn.execute(
      `INSERT INTO gold_records (user_id, amount, type, description)
       VALUES (?, ?, 'sign_in', ?)`,
      [userId, totalGold, `每日签到第${consecutive}天 +${totalGold}金币`]
    );

    return { totalGold, consecutive, isConsecutive, bonus };
  });

  if (result.missing) {
    return error(res, '用户不存在，请重新登录');
  }
  if (result.alreadySigned) {
    return error(res, '今日已经签到过了');
  }

  return success(res, {
    gold: result.totalGold,
    consecutive: result.consecutive,
    isConsecutive: result.isConsecutive,
    bonus: result.bonus
  }, '签到成功');
});

/**
 * POST /api/gold/spin
 * 转盘抽奖
 * 返回随机奖励金币（0-1000 之间随机）
 */
router.get('/spin-status', async (req, res) => {
  const userId = req.user.userId;
  const dailyLimit = await getDailySpinLimit();
  const used = await getTodaySpinCount(userId);
  const remaining = Math.max(dailyLimit - used, 0);

  return success(res, {
    daily_limit: dailyLimit,
    used,
    remaining
  });
});

router.post('/spin', async (req, res) => {
  const userId = req.user.userId;

  try {
    const result = await transaction(async (conn) => {
      const withConn = (sql, params) => conn.execute(sql, params).then(([rows]) => rows);
      await conn.execute('SELECT id FROM users WHERE id = ? FOR UPDATE', [userId]);
      const dailyLimit = await getDailySpinLimit(withConn);
      const used = await getTodaySpinCount(userId, withConn);

      if (used >= dailyLimit) {
        return { limited: true };
      }

      const gold = drawSpinPrize();
      if (gold > 0) {
        await conn.execute(
          `UPDATE users SET gold = gold + ? WHERE id = ?`,
          [gold, userId]
        );
      }
      await conn.execute(
        `INSERT INTO gold_records (user_id, amount, type, description)
         VALUES (?, ?, 'spin', ?)`,
        [userId, gold, gold > 0 ? `\u8f6c\u76d8\u62bd\u5956 +${gold}\u91d1\u5e01` : '\u8f6c\u76d8\u62bd\u5956 \u8c22\u8c22\u53c2\u4e0e']
      );

      return {
        gold,
        dailyLimit,
        used: used + 1,
        remaining: Math.max(dailyLimit - used - 1, 0)
      };
    });

    if (result.limited) {
      return error(res, '\u4eca\u65e5\u8f6c\u76d8\u6b21\u6570\u5df2\u7528\u5b8c\uff0c\u660e\u5929\u518d\u6765\u8bd5\u8bd5');
    }

    return success(res, {
      gold: result.gold,
      prize: result.gold > 0 ? `\u83b7\u5f97 ${result.gold} \u91d1\u5e01` : '\u8c22\u8c22\u53c2\u4e0e',
      daily_limit: result.dailyLimit,
      used: result.used,
      remaining: result.remaining
    }, '\u8f6c\u76d8\u62bd\u5956\u5b8c\u6210');
  } catch (err) {
    console.error('\u8f6c\u76d8\u62bd\u5956\u5931\u8d25:', err.message);
    return error(res, '\u8f6c\u76d8\u62bd\u5956\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5');
  }
});

// 旧客户端兼容门：提示必须校验服务端 active game 状态。
router.post('/use-hint', (req, res) => error(
  res,
  '该接口已停用，请使用 /api/game/hint',
  410,
  410
));

/**
 * GET /api/gold/tasks
 * 返回当前用户今日任务进度与领取状态。
 */
router.get('/tasks', async (req, res) => {
  const tasks = await buildTaskList(req.user.userId);
  return success(res, tasks);
});

/**
 * POST /api/gold/tasks/:taskKey/claim
 * 服务端复核进度，并以唯一键保证同一任务每日只发放一次。
 */
router.post('/tasks/:taskKey/claim', async (req, res) => {
  const userId = req.user.userId;
  const taskKey = req.params.taskKey;
  const task = DAILY_TASKS[taskKey];
  if (!task) {
    return error(res, '未知的任务类型');
  }

  const current = await getTaskProgress(userId, taskKey);
  if (current < task.target) {
    return error(res, `任务尚未完成（${Math.min(current, task.target)}/${task.target}）`);
  }

  try {
    await transaction(async (conn) => {
      await conn.execute(
        `INSERT INTO task_claims (user_id, task_key, reward, claim_date)
         VALUES (?, ?, ?, CURDATE())`,
        [userId, taskKey, task.reward]
      );
      await conn.execute(
        `UPDATE users SET gold = gold + ? WHERE id = ?`,
        [task.reward, userId]
      );
      await conn.execute(
        `INSERT INTO gold_records (user_id, amount, type, description)
         VALUES (?, ?, 'task', ?)`,
        [userId, task.reward, `完成每日任务「${task.title}」 +${task.reward}金币`]
      );
    });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return error(res, '今日该任务奖励已经领取');
    }
    console.error('任务奖励领取失败:', err.message);
    return error(res, '任务奖励领取失败，请稍后重试');
  }

  return success(res, { task_key: taskKey, gold: task.reward }, '任务奖励领取成功');
});

module.exports = router;
