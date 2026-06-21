/**
 * JWT 工具模块
 * 封装 jsonwebtoken 的签发与验证操作，供认证中间件使用
 */

const jwt = require('jsonwebtoken');

function requireSecret(name) {
  const value = process.env[name];
  if (!value || value.length < 32) {
    throw new Error(`${name} must be configured with at least 32 characters`);
  }
  return value;
}

const JWT_SECRET = requireSecret('JWT_SECRET');
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const ADMIN_JWT_SECRET = requireSecret('ADMIN_JWT_SECRET');

if (JWT_SECRET === ADMIN_JWT_SECRET) {
  throw new Error('JWT_SECRET and ADMIN_JWT_SECRET must be different');
}

/**
 * 签发普通用户 JWT Token
 * @param {object} payload - 要编码进 Token 的数据（如 { userId, phone }）
 * @returns {string} JWT 字符串
 */
function signUserToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

/**
 * 签发管理员 JWT Token
 * 使用独立的密钥，防止普通用户 Token 被冒用于管理员接口
 * @param {object} payload - 要编码进 Token 的数据（如 { adminId, username }）
 * @returns {string} JWT 字符串
 */
function signAdminToken(payload) {
  return jwt.sign(payload, ADMIN_JWT_SECRET, { expiresIn: '1d' });
}

/**
 * 验证普通用户 Token
 * @param {string} token - 从请求头中提取的 JWT 字符串
 * @returns {object|null} 解码后的 payload，验证失败返回 null
 */
function verifyUserToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (err) {
    return null;
  }
}

/**
 * 验证管理员 Token
 * @param {string} token - 从请求头中提取的 JWT 字符串
 * @returns {object|null} 解码后的 payload，验证失败返回 null
 */
function verifyAdminToken(token) {
  try {
    return jwt.verify(token, ADMIN_JWT_SECRET);
  } catch (err) {
    return null;
  }
}

module.exports = {
  signUserToken,
  signAdminToken,
  verifyUserToken,
  verifyAdminToken
};
