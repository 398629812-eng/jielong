/**
 * 管理员权限认证中间件
 * 验证 JWT 且用户必须是管理员角色
 * 管理员与普通用户使用不同的 JWT Secret，防止普通用户 Token 冒用
 */

const { verifyAdminToken } = require('../utils/jwt');
const { unauthorized, forbidden } = require('../utils/response');

function adminAuthMiddleware(req, res, next) {
  // 从请求头提取 Token
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return unauthorized(res, '请先登录管理员账号');
  }

  const token = authHeader.substring(7);
  const payload = verifyAdminToken(token);
  if (!payload) {
    return unauthorized(res, '管理员登录已过期，请重新登录');
  }

  // 校验 payload 中是否包含管理员标识
  if (!payload.isAdmin && payload.role !== 'admin') {
    return forbidden(res, '仅限管理员访问');
  }

  req.admin = payload;
  next();
}

module.exports = adminAuthMiddleware;
