/**
 * 请求频率限制中间件
 * 使用 express-rate-limit 限制单个 IP 的请求频率，防止暴力破解和 DDoS
 */

const rateLimit = require('express-rate-limit');

/**
 * 通用 API 频率限制：每 IP 15 分钟内最多 100 次请求
 * 适用于普通接口，不影响正常用户操作
 */
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 分钟
  max: 100, // 每个 IP 最多 100 次请求
  standardHeaders: true, // 返回 RateLimit-* 响应头
  legacyHeaders: false, // 不返回 X-RateLimit-* 响应头
  message: {
    code: 429,
    message: '请求过于频繁，请稍后再试',
    data: null
  }
});

/**
 * 严格频率限制：每 IP 1 小时内最多 10 次请求
 * 适用于敏感操作：登录、注册、发送验证码等
 */
const strictLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 小时
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    code: 429,
    message: '操作过于频繁，请 1 小时后再试',
    data: null
  }
});

/**
 * 广告奖励频率限制：每 IP 5 分钟内最多 20 次
 * 广告观看理论上需要时间间隔，过于频繁可能是脚本刷取
 */
const adRewardLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 分钟
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    code: 429,
    message: '广告请求过于频繁，请稍后再试',
    data: null
  }
});

module.exports = {
  generalLimiter,
  strictLimiter,
  adRewardLimiter
};
