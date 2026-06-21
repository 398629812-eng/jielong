/**
 * JWT 认证中间件
 * 从请求头 Authorization: Bearer <token> 中提取并验证 JWT
 * 验证通过后将 user 对象挂载到 req.user，供后续路由使用
 */

const { verifyUserToken } = require('../utils/jwt');
const { queryOne } = require('../models');
const { unauthorized, forbidden } = require('../utils/response');

async function authMiddleware(req, res, next) {
  // 从请求头提取 Token，格式：Authorization: Bearer <token>
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return unauthorized(res, '请先登录');
  }

  const token = authHeader.substring(7); // 去掉 "Bearer " 前缀
  const payload = verifyUserToken(token);
  if (!payload) {
    return unauthorized(res, '登录已过期，请重新登录');
  }

  let account;
  try {
    account = await queryOne(
      'SELECT is_guest, is_banned FROM users WHERE id = ?',
      [payload.userId]
    );
  } catch (err) {
    return next(err);
  }
  if (!account) {
    return unauthorized(res, '账号不存在，请重新登录');
  }
  if (account.is_guest) {
    return unauthorized(res, '游客登录已停止，请使用手机号登录');
  }
  if (account.is_banned) {
    return forbidden(res, '账号已被封禁');
  }

  // 仅允许数据库中状态正常的正式账号继续访问。
  req.user = payload;
  next();
}

module.exports = authMiddleware;
