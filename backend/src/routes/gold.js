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
const dayjs = require('dayjs');

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
  const user = await queryOne(
    `SELECT last_sign_in_date, consecutive_sign_in, gold FROM users WHERE id = ?`,
    [userId]
  );

  const today = dayjs().format('YYYY-MM-DD');
  const yesterday = dayjs().subtract(1, 'day').format('YYYY-MM-DD');

  // 今天已经签过到
  if (user.last_sign_in_date && dayjs(user.last_sign_in_date).format('YYYY-MM-DD') === today) {
    return error(res, '今日已经签到过了');
  }

  // 查询签到基础金币
  const configRows = await query(`SELECT value FROM configs WHERE \`key\` = 'sign_in_base'`);
  const baseGold = configRows.length > 0 ? parseInt(configRows[0].value, 10) : 50;

  // 是否连续签到
  let isConsecutive = false;
  let consecutive = user.consecutive_sign_in || 0;
  if (user.last_sign_in_date && dayjs(user.last_sign_in_date).format('YYYY-MM-DD') === yesterday) {
    isConsecutive = true;
    consecutive += 1;
  } else {
    consecutive = 1;
  }

  // 连续签到奖励：每连续 7 天额外奖励 50%（简单逻辑）
  let bonus = 0;
  if (consecutive % 7 === 0) {
    bonus = Math.floor(baseGold * 0.5);
  }
  const totalGold = baseGold + bonus;

  // 更新用户签到信息
  await execute(
    `UPDATE users SET gold = gold + ?, last_sign_in_date = ?, consecutive_sign_in = ? WHERE id = ?`,
    [totalGold, today, consecutive, userId]
  );

  await execute(
    `INSERT INTO gold_records (user_id, amount, type, description)
     VALUES (?, ?, 'sign_in', ?)`,
    [userId, totalGold, `每日签到第${consecutive}天 +${totalGold}金币`]
  );

  return success(res, {
    gold: totalGold,
    consecutive,
    isConsecutive,
    bonus
  }, '签到成功');
});

/**
 * POST /api/gold/spin
 * 转盘抽奖
 * 返回随机奖励金币（0-1000 之间随机）
 */
router.post('/spin', async (req, res) => {
  const userId = req.user.userId;

  // 随机生成 0-1000 的金币（模拟转盘）
  // 实际业务中可配置转盘奖品池和概率
  const prizes = [0, 10, 20, 50, 100, 200, 500, 1000];
  const weights = [30, 25, 20, 15, 5, 3, 1.5, 0.5]; // 权重
  const totalWeight = weights.reduce((a, b) => a + b, 0);
  let random = Math.random() * totalWeight;

  let gold = 0;
  for (let i = 0; i < prizes.length; i++) {
    random -= weights[i];
    if (random <= 0) {
      gold = prizes[i];
      break;
    }
  }

  if (gold > 0) {
    await execute(
      `UPDATE users SET gold = gold + ? WHERE id = ?`,
      [gold, userId]
    );
    await execute(
      `INSERT INTO gold_records (user_id, amount, type, description)
       VALUES (?, ?, 'spin', ?)`,
      [userId, gold, `转盘抽奖 +${gold}金币`]
    );
  }

  return success(res, { gold, prize: gold > 0 ? `获得 ${gold} 金币` : '谢谢参与' }, '转盘抽奖完成');
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
