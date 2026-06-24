const rateLimit = require('express-rate-limit');

const rateLimitResponse = (message) => ({
  code: 429,
  message,
  data: null
});

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  skip: (req) => req.path.startsWith('/api/admin'),
  standardHeaders: true,
  legacyHeaders: false,
  message: rateLimitResponse('请求过于频繁，请稍后再试')
});

const strictLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: rateLimitResponse('操作过于频繁，请 1 小时后再试')
});

const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 600,
  standardHeaders: true,
  legacyHeaders: false,
  message: rateLimitResponse('管理后台请求过于频繁，请稍后再试')
});

const adRewardLimiter = rateLimit({
  windowMs: 5 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: rateLimitResponse('广告请求过于频繁，请稍后再试')
});

module.exports = {
  generalLimiter,
  strictLimiter,
  adminLimiter,
  adRewardLimiter
};
