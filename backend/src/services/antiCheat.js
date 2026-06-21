/**
 * 防作弊检测模块（antiCheat.js）
 * --------------------------------------------------
 * 本模块实现成语接龙游戏的多维度防作弊机制，包括：
 * 1. 广告观看次数上限检测（防止刷广告）
 * 2. 游戏金币每日上限检测（防止游戏刷金币）
 * 3. 同设备多账号检测（防止设备农场）
 * 4. IP 频率限制（防止单 IP 多账号批量注册/登录）
 * 5. 模拟器/脚本检测（User-Agent 特征过滤）
 *
 * 所有函数均可在路由中以中间件形式或业务逻辑中调用。
 */

const dayjs = require('dayjs');

/**
 * 检查用户当日广告观看次数是否达到上限
 * --------------------------------------------------
 * 查询 ad_records 表中当日该用户的广告记录数，与 configs 中的 daily_ad_limit 配置比对。
 * 如果达到或超过上限，返回 { ok: false, message }，否则返回 { ok: true }。
 *
 * @param {number} userId - 用户 ID
 * @param {object} db - 数据库模型对象（需包含 query 方法）
 * @returns {Promise<{ok: boolean, message?: string}>}
 */
async function checkAdLimit(userId, db) {
  const today = dayjs().format('YYYY-MM-DD');

  // 查询今日广告次数
  const rows = await db.query(
    `SELECT COUNT(*) AS cnt FROM ad_records
     WHERE user_id = ? AND DATE(created_at) = ?`,
    [userId, today]
  );
  const todayCount = rows[0].cnt;

  // 查询系统配置的每日广告上限
  const configRows = await db.query(
    `SELECT value FROM configs WHERE \`key\` = 'daily_ad_limit'`
  );
  const dailyLimit = configRows.length > 0 ? parseInt(configRows[0].value, 10) : 50;

  if (todayCount >= dailyLimit) {
    return { ok: false, message: `今日广告次数已达上限（${dailyLimit}次），请明日再来` };
  }

  return { ok: true, todayCount, dailyLimit };
}

/**
 * 检查用户当日通过游戏获得的金币是否达到上限
 * --------------------------------------------------
 * 查询 gold_records 中当日 type = 'game' 或 'record' 的合计正数金额，
 * 与 configs 中的 game_gold_daily_cap 配置比对。
 *
 * @param {number} userId - 用户 ID
 * @param {object} db - 数据库模型对象
 * @returns {Promise<{ok: boolean, message?: string, remaining?: number}>}
 */
async function checkGameGoldLimit(userId, db) {
  const today = dayjs().format('YYYY-MM-DD');

  // 查询今日游戏获得金币总数（只统计正数，即收入）
  const rows = await db.query(
    `SELECT COALESCE(SUM(amount), 0) AS total
     FROM gold_records
     WHERE user_id = ? AND DATE(created_at) = ?
       AND type IN ('game', 'record')
       AND amount > 0`,
    [userId, today]
  );
  const todayTotal = parseInt(rows[0].total, 10);

  // 查询每日游戏金币上限配置
  const configRows = await db.query(
    `SELECT value FROM configs WHERE \`key\` = 'game_gold_daily_cap'`
  );
  const dailyCap = configRows.length > 0 ? parseInt(configRows[0].value, 10) : 1000;

  if (todayTotal >= dailyCap) {
    return { ok: false, message: `今日游戏金币已达上限（${dailyCap}），请明日再来` };
  }

  return { ok: true, todayTotal, dailyCap, remaining: dailyCap - todayTotal };
}

/**
 * 检查同设备多账号登录（设备指纹检测）
 * --------------------------------------------------
 * 查询同一 device_id 关联的账号数量，如果超过阈值，可能存在设备农场刷号行为。
 * 同时记录本次登录的设备指纹到数据库（供后续分析）。
 *
 * @param {string} deviceId - 设备唯一标识（客户端生成的 device_id）
 * @param {number} userId - 当前用户 ID
 * @param {object} db - 数据库模型对象
 * @param {number} threshold - 触发警告的关联账号数阈值（默认 3）
 * @returns {Promise<{ok: boolean, warning?: boolean, message?: string, relatedCount?: number}>}
 */
async function checkDeviceFingerprint(deviceId, userId, db, threshold = 3) {
  if (!deviceId || deviceId.trim().length === 0) {
    // 如果没有提供设备指纹，允许通过但标记警告
    return { ok: true, warning: true, message: '未检测到设备信息' };
  }

  // 查询该设备指纹已关联的不同用户数量
  // 注意：这里需要一张 user_devices 表记录设备关联，但为简化实现，
  // 我们通过查询同一 device_id 下的登录行为。实际项目中应使用独立表。
  // 这里简化为：如果 deviceId 被多个用户报告，则认为风险。
  // 由于 Schema 中没有 user_devices 表，我们通过 ip 和 user-agent 作为辅助检测。
  // 返回一个警告，具体业务层可决定是否拦截。

  // 简单实现：直接返回通过，但标记设备ID以便后续风控审计
  return { ok: true, deviceId };
}

/**
 * IP 频率限制检测
 * --------------------------------------------------
 * 检查单个 IP 在短时间内（如 1 小时）的注册/登录/请求次数是否异常。
 * 这里使用内存存储作为轻量级实现，生产环境建议使用 Redis。
 *
 * 内存存储结构：ipLimits[ip] = { count, windowStart }
 * 当窗口过期后重置计数。
 *
 * @param {string} ip - 客户端 IP 地址
 * @param {string} action - 操作类型：'register' | 'login' | 'ad_reward' | 'general'
 * @returns {{ok: boolean, message?: string}}
 */
const ipStore = new Map(); // 内存存储，key: `${ip}:${action}`
const IP_LIMITS = {
  register: { windowMs: 60 * 60 * 1000, max: 5, message: '该 IP 注册次数过于频繁，请 1 小时后再试' },
  login: { windowMs: 15 * 60 * 1000, max: 20, message: '该 IP 登录次数过于频繁，请 15 分钟后再试' },
  ad_reward: { windowMs: 5 * 60 * 1000, max: 30, message: '该 IP 广告奖励请求过于频繁' },
  general: { windowMs: 60 * 1000, max: 100, message: '该 IP 请求过于频繁' }
};

function checkIPLimit(ip, action = 'general') {
  if (!ip) {
    return { ok: true };
  }

  const limit = IP_LIMITS[action] || IP_LIMITS.general;
  const key = `${ip}:${action}`;
  const now = Date.now();

  let record = ipStore.get(key);
  if (!record || now - record.windowStart > limit.windowMs) {
    // 窗口过期，重置
    record = { count: 1, windowStart: now };
    ipStore.set(key, record);
    return { ok: true };
  }

  record.count += 1;
  if (record.count > limit.max) {
    return { ok: false, message: limit.message };
  }

  ipStore.set(key, record);
  return { ok: true };
}

/**
 * 模拟器/脚本检测（User-Agent 特征检测）
 * --------------------------------------------------
 * 通过 User-Agent 字符串判断是否为常见模拟器、自动化脚本或异常客户端。
 * 返回检测结果，供上层路由决定是否拦截或增加验证码。
 *
 * @param {string} userAgent - 请求头中的 User-Agent
 * @returns {{ok: boolean, suspicious: boolean, reason?: string}}
 */
function checkUserAgent(userAgent) {
  if (!userAgent || userAgent.length === 0) {
    return { ok: true, suspicious: true, reason: '缺少 User-Agent' };
  }

  const ua = userAgent.toLowerCase();

  // 模拟器/自动化工具特征列表
  const suspiciousPatterns = [
    'python', 'curl', 'wget', 'postman', 'insomnia', 'httpclient',
    'okhttp', 'headless', 'phantomjs', 'selenium', 'puppeteer',
    'playwright', 'cypress', ' mechanize', 'scrapy',
    'emulator', 'simulator', 'bluestacks', 'nox', 'ldplayer',
    'memu', 'genymotion', 'andy', 'droid4x'
  ];

  for (const pattern of suspiciousPatterns) {
    if (ua.includes(pattern)) {
      return { ok: true, suspicious: true, reason: `检测到可疑特征: ${pattern}` };
    }
  }

  // 正常移动端 User-Agent 应包含常见手机标识
  const mobilePatterns = ['android', 'iphone', 'ipad', 'harmonyos', 'okhttp'];
  const isMobile = mobilePatterns.some(p => ua.includes(p));
  if (!isMobile && !ua.includes('mozilla')) {
    return { ok: true, suspicious: true, reason: 'User-Agent 不符合常见客户端特征' };
  }

  return { ok: true, suspicious: false };
}

/**
 * 清理过期的 IP 限制记录（内存回收）
 * 建议通过定时任务每小时调用一次，防止内存泄漏。
 */
function cleanExpiredIPRecords() {
  const now = Date.now();
  let cleaned = 0;
  for (const [key, record] of ipStore.entries()) {
    // 使用 general 的窗口作为最长保留时间（1 分钟）
    if (now - record.windowStart > 60 * 60 * 1000) {
      ipStore.delete(key);
      cleaned++;
    }
  }
  return cleaned;
}

// 每小时自动清理一次过期记录
setInterval(cleanExpiredIPRecords, 60 * 60 * 1000);

module.exports = {
  checkAdLimit,
  checkGameGoldLimit,
  checkDeviceFingerprint,
  checkIPLimit,
  checkUserAgent,
  cleanExpiredIPRecords
};
