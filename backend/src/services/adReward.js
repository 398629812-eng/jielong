/**
 * 广告奖励发放逻辑模块（adReward.js）
 * --------------------------------------------------
 * 本模块处理广告观看完成后的奖励发放流程，包括：
 * 1. 校验广告次数上限（防刷）
 * 2. 校验 transaction_id 不重复（如果广告平台提供回调 ID）
 * 3. 根据 ad_type 发放对应奖励（金币/提示次数）
 * 4. 记录到 gold_records（金币流水）和 ad_records（广告记录）
 *
 * 支持所有 ad_type：hint（提示）、continue（续命）、sign_in_double（签到翻倍）、spin（转盘）、task（任务）
 */

const { checkAdLimit } = require('./antiCheat');
const { checkIPLimit } = require('./antiCheat');
const dayjs = require('dayjs');

/**
 * 广告类型与奖励映射配置
 * 每种广告类型对应奖励内容，奖励可以是金币或提示次数
 */
const AD_TYPE_REWARDS = {
  hint: { gold: 0, hints: 1, description: '观看广告获得提示次数' },
  continue: { gold: 100, hints: 0, description: '观看广告续命获得金币' },
  sign_in_double: { gold: 0, hints: 0, description: '观看广告获得签到翻倍奖励' },
  spin: { gold: 0, hints: 0, description: '转盘抽奖（由转盘逻辑处理，此处仅记录）' },
  task: { gold: 200, hints: 0, description: '完成任务观看广告获得金币' }
};

/**
 * 发放广告奖励
 * --------------------------------------------------
 * 核心入口函数，完成从校验到发放的全流程。
 *
 * @param {number} userId - 用户 ID
 * @param {string} adType - 广告类型（hint / continue / sign_in_double / spin / task）
 * @param {string|null} transactionId - 广告平台回调的交易 ID（可选，用于幂等校验）
 * @param {string} platform - 广告平台（tencent / huawei）
 * @param {object} db - 数据库模型对象
 * @param {string} ip - 客户端 IP（用于 IP 频率限制）
 * @returns {Promise<{ok: boolean, message?: string, gold?: number, hints?: number}>}
 */
async function grantAdReward(userId, adType, transactionId, platform, db, ip) {
  // 1. 参数校验
  if (!userId || !adType) {
    return { ok: false, message: '参数错误：缺少用户ID或广告类型' };
  }

  const rewardConfig = AD_TYPE_REWARDS[adType];
  if (!rewardConfig) {
    return { ok: false, message: `未知的广告类型: ${adType}` };
  }

  // 2. IP 频率限制（额外防护层）
  const ipCheck = checkIPLimit(ip, 'ad_reward');
  if (!ipCheck.ok) {
    return { ok: false, message: ipCheck.message };
  }

  // 3. 校验广告次数上限
  const adLimitCheck = await checkAdLimit(userId, db);
  if (!adLimitCheck.ok) {
    return { ok: false, message: adLimitCheck.message };
  }

  // 4. 校验 transaction_id 不重复（如果提供了）
  if (transactionId && transactionId.trim().length > 0) {
    const existRows = await db.query(
      `SELECT id FROM ad_records WHERE transaction_id = ? LIMIT 1`,
      [transactionId.trim()]
    );
    if (existRows.length > 0) {
      return { ok: false, message: '该广告奖励已发放，请勿重复提交' };
    }
  }

  // 5. 查询当前用户金币和提示次数（用于后续更新）
  const userRows = await db.query(
    `SELECT gold, hints, last_sign_in_date FROM users WHERE id = ? LIMIT 1`,
    [userId]
  );
  if (userRows.length === 0) {
    return { ok: false, message: '用户不存在' };
  }
  const user = userRows[0];

  if (adType === 'sign_in_double') {
    const signedInToday = user.last_sign_in_date &&
      dayjs(user.last_sign_in_date).format('YYYY-MM-DD') === dayjs().format('YYYY-MM-DD');
    if (!signedInToday) {
      return { ok: false, message: '请先完成今日签到' };
    }

    const doubledRows = await db.query(
      `SELECT id FROM ad_records
       WHERE user_id = ? AND ad_type = 'sign_in_double' AND DATE(created_at) = CURDATE()
       LIMIT 1`,
      [userId]
    );
    if (doubledRows.length > 0) {
      return { ok: false, message: '今日签到奖励已经翻倍' };
    }
  }

  // 6. 查询广告金币奖励配置（configs 表可能覆盖默认值）
  let goldReward = rewardConfig.gold;
  if (adType === 'continue' || adType === 'task') {
    const configRows = await db.query(
      `SELECT value FROM configs WHERE \`key\` = 'ad_gold_reward' LIMIT 1`
    );
    if (configRows.length > 0) {
      goldReward = parseInt(configRows[0].value, 10);
    }
  } else if (adType === 'sign_in_double') {
    const configRows = await db.query(
      "SELECT value FROM configs WHERE `key` = 'sign_in_base' LIMIT 1"
    );
    goldReward = configRows.length > 0 ? parseInt(configRows[0].value, 10) : 50;
  }

  // 7. 使用事务执行：更新用户余额 + 插入金币流水 + 插入广告记录
  try {
    await db.transaction(async (conn) => {
      // 7.1 更新用户金币和提示次数
      const newGold = user.gold + goldReward;
      const newHints = user.hints + rewardConfig.hints;
      await conn.execute(
        `UPDATE users SET gold = ?, hints = ? WHERE id = ?`,
        [newGold, newHints, userId]
      );

      // 7.2 插入金币流水记录（如果有金币变动）
      if (goldReward !== 0) {
        await conn.execute(
          `INSERT INTO gold_records (user_id, amount, type, description)
           VALUES (?, ?, 'ad_watch', ?)`,
          [userId, goldReward, `${rewardConfig.description} (+${goldReward}金币)`]
        );
      }

      // 7.3 插入提示次数流水（如果有提示变动，提示次数不计入 gold_records，由业务逻辑决定）
      // 提示次数更新在 users 表中已完成，如果需要独立记录，可另建表。此处简化。

      // 7.4 插入广告观看记录
      await conn.execute(
        `INSERT INTO ad_records (user_id, ad_type, platform, transaction_id)
         VALUES (?, ?, ?, ?)`,
        [userId, adType, platform || 'tencent', transactionId || null]
      );
    });

    return {
      ok: true,
      message: '奖励发放成功',
      gold: goldReward,
      hints: rewardConfig.hints
    };
  } catch (err) {
    console.error('广告奖励发放失败:', err.message);
    return { ok: false, message: '奖励发放失败，请稍后重试' };
  }
}

module.exports = {
  grantAdReward,
  AD_TYPE_REWARDS
};
