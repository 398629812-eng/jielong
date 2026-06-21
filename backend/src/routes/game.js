/**
 * 游戏路由（game.js）
 * 提供：开始游戏、验证接龙、获取提示、结束游戏、排行榜
 * 所有路由需登录
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { queryOne, execute, query } = require('../models');
const { success, error } = require('../utils/response');
const authMiddleware = require('../middleware/auth');
const { validateIdiom, findNextIdioms, getRandomStartIdiom, getIdiomDetail } = require('../services/idiomValidator');
const { checkGameGoldLimit } = require('../services/antiCheat');
const dayjs = require('dayjs');

const router = express.Router();
router.use(authMiddleware);

// 内存存储当前进行中的游戏状态（生产环境应使用 Redis，含过期机制）
const activeGames = new Map();

/**
 * GET /api/game/start
 * 开始新游戏，生成 game_id，返回起始成语
 * Query: difficulty=easy|normal|hard
 */
router.get('/start', async (req, res) => {
  const difficulty = ['easy', 'normal', 'hard'].includes(req.query.difficulty)
    ? req.query.difficulty
    : 'easy';

  const gameId = uuidv4();
  const startIdiom = getRandomStartIdiom();

  if (!startIdiom) {
    return error(res, '成语数据加载失败，请稍后重试');
  }

  // 记录游戏状态到内存
  activeGames.set(gameId, {
    userId: req.user.userId,
    difficulty,
    chain: [startIdiom.idiom],
    usedIdioms: new Set([startIdiom.idiom]),
    startedAt: Date.now(),
    rounds: 0 // 玩家成功接龙的轮数
  });

  // 设置 30 分钟后自动过期清理
  setTimeout(() => {
    activeGames.delete(gameId);
  }, 30 * 60 * 1000);

  return success(res, {
    game_id: gameId,
    difficulty,
    start_idiom: {
      idiom: startIdiom.idiom,
      pinyin: startIdiom.pinyin,
      meaning: startIdiom.meaning,
      last_pinyin: startIdiom.last_pinyin
    }
  }, '游戏开始');
});

/**
 * POST /api/game/validate
 * 验证玩家接龙，返回是否合法 + 下一个系统成语
 * Body: { game_id: string, idiom: string, previous_idiom: string }
 */
router.post('/validate',
  body('game_id').notEmpty().withMessage('缺少游戏 ID'),
  body('idiom').notEmpty().withMessage('请输入成语'),
  body('previous_idiom').notEmpty().withMessage('缺少上一个成语'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { game_id, idiom, previous_idiom } = req.body;
    const game = activeGames.get(game_id);

    if (!game || game.userId !== req.user.userId) {
      return error(res, '游戏不存在或已过期，请重新开始');
    }

    // 验证上一个成语是否匹配当前游戏状态
    if (game.chain[game.chain.length - 1] !== previous_idiom) {
      return error(res, '接龙顺序错误，请刷新后重试');
    }

    // 获取上一个成语的尾字拼音
    const prevDetail = getIdiomDetail(previous_idiom);
    if (!prevDetail) {
      return error(res, '上一个成语无效');
    }

    // 验证玩家输入的成语
    const allowDifferentTone = game.difficulty === 'easy'; // 简单模式允许同音不同调
    const validation = validateIdiom(idiom, prevDetail.last_pinyin_no_tone, game.usedIdioms, allowDifferentTone);

    if (!validation.valid) {
      return success(res, {
        valid: false,
        message: validation.message
      }, '接龙失败');
    }

    // 接龙成功，更新游戏状态
    game.chain.push(idiom);
    game.usedIdioms.add(idiom);
    game.rounds += 1;

    // 查找系统下一个成语（接玩家成语的尾字）
    const playerDetail = validation.detail;
    const nextCandidates = findNextIdioms(
      playerDetail.last_pinyin_no_tone,
      game.usedIdioms,
      allowDifferentTone,
      game.difficulty
    );

    let nextIdiom = null;
    if (nextCandidates.length > 0) {
      // 根据难度选择：困难模式取第一个（已按难度排序），其他模式随机取
      const idx = game.difficulty === 'hard' ? 0 : Math.floor(Math.random() * nextCandidates.length);
      nextIdiom = nextCandidates[idx];
      game.chain.push(nextIdiom.idiom);
      game.usedIdioms.add(nextIdiom.idiom);
    }

    return success(res, {
      valid: true,
      rounds: game.rounds,
      next_idiom: nextIdiom ? {
        idiom: nextIdiom.idiom,
        pinyin: nextIdiom.pinyin,
        meaning: nextIdiom.meaning,
        last_pinyin: nextIdiom.last_pinyin
      } : null,
      message: nextIdiom ? '接龙成功，轮到系统' : '恭喜！系统无法接龙，你赢了！'
    }, '接龙成功');
  }
);

/**
 * POST /api/game/hint
 * 消耗提示次数，返回可接成语
 * Body: { game_id: string, current_idiom: string }
 */
router.post('/hint',
  body('game_id').notEmpty().withMessage('缺少游戏 ID'),
  body('current_idiom').notEmpty().withMessage('缺少当前成语'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { game_id, current_idiom } = req.body;
    const userId = req.user.userId;

    const game = activeGames.get(game_id);
    if (game && game.userId === userId && game.chain[game.chain.length - 1] !== current_idiom) {
      return error(res, '\u5f53\u524d\u6210\u8bed\u4e0e\u6e38\u620f\u8fdb\u5ea6\u4e0d\u4e00\u81f4\uff0c\u8bf7\u5237\u65b0\u540e\u91cd\u8bd5');
    }

    if (!game || game.userId !== userId) {
      return error(res, '游戏不存在或已过期');
    }

    // 检查提示次数
    const user = await queryOne(`SELECT hints FROM users WHERE id = ?`, [userId]);
    if (!user || user.hints <= 0) {
      return error(res, '提示次数不足，可通过观看广告获取');
    }

    const detail = getIdiomDetail(current_idiom);
    if (!detail) {
      return error(res, '当前成语无效');
    }

    const allowDifferentTone = game.difficulty === 'easy';
    const nextIdioms = findNextIdioms(detail.last_pinyin_no_tone, game.usedIdioms, allowDifferentTone, 'easy');

    if (nextIdioms.length === 0) {
      return error(res, '当前成语已无后续可接成语');
    }

    // 扣除提示次数
    const deduction = await execute(
      `UPDATE users SET hints = hints - 1 WHERE id = ? AND hints > 0`,
      [userId]
    );
    if (deduction.affectedRows !== 1) {
      return error(res, '\u63d0\u793a\u6b21\u6570\u4e0d\u8db3\uff0c\u53ef\u901a\u8fc7\u89c2\u770b\u5e7f\u544a\u83b7\u53d6');
    }
    const updatedUser = await queryOne(`SELECT hints FROM users WHERE id = ?`, [userId]);

    const hint = nextIdioms[0]; // 取第一个作为提示

    return success(res, {
      hint: hint.idiom,
      first_pinyin: hint.first_pinyin,
      meaning: hint.meaning,
      remaining_hints: updatedUser.hints
    }, '提示使用成功');
  }
);

/**
 * POST /api/game/end
 * 结束游戏，保存记录，计算金币
 * Body: { game_id: string, rounds: number, chain: string[], reason: string }
 */
router.post('/end',
  body('game_id').notEmpty().withMessage('缺少游戏 ID'),
  body('rounds').isInt({ min: 0 }).withMessage('轮数必须是正整数'),
  body('chain').isArray().withMessage('chain 必须是数组'),
  body('reason').notEmpty().withMessage('请提供结束原因'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg);
    }

    const { game_id, reason } = req.body;
    const userId = req.user.userId;

    const game = activeGames.get(game_id);
    if (!game || game.userId !== userId) {
      return error(res, '游戏不存在或已过期');
    }

    // 结算只能使用服务端维护的游戏状态，不能信任客户端上传的轮数或链条。
    const rounds = game.rounds;
    const chain = game.chain;

    // 删除活跃游戏
    activeGames.delete(game_id);

    // 1. 查询配置
    const configRows = await query(`SELECT \`key\`, value FROM configs WHERE \`key\` IN ('game_gold_per_round', 'record_gold_reward', 'game_gold_daily_cap')`);
    const configs = {};
    for (const row of configRows) {
      configs[row.key] = parseInt(row.value, 10);
    }

    const perRound = configs.game_gold_per_round || 10;
    const recordBonus = configs.record_gold_reward || 2000;
    const dailyCap = configs.game_gold_daily_cap || 1000;

    // 2. 检查玩家历史最高分
    const bestRows = await query(
      `SELECT MAX(rounds) AS best FROM game_records WHERE user_id = ?`,
      [userId]
    );
    const bestRounds = bestRows[0].best || 0;
    const isRecord = rounds > bestRounds;

    // 3. 计算金币
    let gold = rounds * perRound;
    if (isRecord) {
      gold += recordBonus;
    }

    // 4. 检查当日上限
    const limitCheck = await checkGameGoldLimit(userId, { query });
    const actualGold = limitCheck.ok ? Math.min(gold, limitCheck.remaining || gold) : 0;

    // 5. 保存游戏记录
    const idiomChain = JSON.stringify(chain);
    await execute(
      `INSERT INTO game_records (user_id, difficulty, rounds, idiom_chain, is_record, score)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, game.difficulty, rounds, idiomChain, isRecord ? 1 : 0, actualGold]
    );

    // 6. 发放金币（如果有）
    if (actualGold > 0) {
      await execute(
        `UPDATE users SET gold = gold + ? WHERE id = ?`,
        [actualGold, userId]
      );
      await execute(
        `INSERT INTO gold_records (user_id, amount, type, description)
         VALUES (?, ?, 'game', ?)`,
        [userId, actualGold, `游戏结束 ${rounds} 轮${isRecord ? '（破纪录）' : ''} +${actualGold}金币，原因：${reason}`]
      );
    }

    return success(res, {
      rounds,
      is_record: isRecord,
      gold: actualGold,
      reason,
      best_rounds: Math.max(bestRounds, rounds)
    }, '游戏结束');
  }
);

/**
 * GET /api/game/leaderboard
 * 返回轮数排行榜（前50名）
 */
router.get('/leaderboard', async (req, res) => {
  const rows = await query(
    `SELECT gr.user_id, COALESCE(NULLIF(u.nickname, ''), CONCAT('用户', u.id)) AS nickname,
            MAX(gr.rounds) AS rounds
     FROM game_records gr
     JOIN users u ON gr.user_id = u.id
     GROUP BY gr.user_id, u.nickname, u.id
     ORDER BY rounds DESC, gr.user_id ASC
     LIMIT 50`
  );

  return success(res, rows.map((row, index) => ({
    ...row,
    rank: index + 1,
    is_me: row.user_id === req.user.userId
  })));
});

module.exports = router;
