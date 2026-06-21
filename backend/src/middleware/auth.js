/**
 * JWT 认证中间件
 * 从请求头 Authorization: Bearer <token> 中提取并验证 JWT
 * 验证通过后将 user 对象挂载到 req.user，供后续路由使用
 */

const { verifyUserToken } = require('../utils/jwt');
const { unauthorized } = require('../utils/response');

function authMiddleware(req, res, next) {
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

  // 将解码后的用户信息挂载到请求对象，供后续路由读取
  req.user = payload;
  next();
}

module.exports = authMiddleware;
