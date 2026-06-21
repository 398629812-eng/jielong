/**
 * 统一响应格式工具模块
 * 所有 API 返回统一使用 { code, message, data } 结构
 * code: 0 表示成功，非 0 表示各类错误
 */

/**
 * 成功响应
 * @param {object} res - Express response 对象
 * @param {any} data - 响应数据
 * @param {string} message - 成功提示信息
 * @param {number} statusCode - HTTP 状态码（默认 200）
 */
function success(res, data = null, message = 'ok', statusCode = 200) {
  res.status(statusCode).json({
    code: 0,
    message,
    data
  });
}

/**
 * 错误响应
 * @param {object} res - Express response 对象
 * @param {string} message - 错误提示信息
 * @param {number} code - 业务错误码（默认 1）
 * @param {number} statusCode - HTTP 状态码（默认 400）
 */
function error(res, message = '操作失败', code = 1, statusCode = 400) {
  res.status(statusCode).json({
    code,
    message,
    data: null
  });
}

/**
 * 服务器内部错误响应
 * @param {object} res - Express response 对象
 * @param {string} message - 错误提示信息
 */
function serverError(res, message = '服务器内部错误') {
  res.status(500).json({
    code: 500,
    message,
    data: null
  });
}

/**
 * 未授权响应（401）
 * @param {object} res - Express response 对象
 * @param {string} message - 提示信息
 */
function unauthorized(res, message = '未登录或登录已过期') {
  res.status(401).json({
    code: 401,
    message,
    data: null
  });
}

/**
 * 禁止访问响应（403）
 * @param {object} res - Express response 对象
 * @param {string} message - 提示信息
 */
function forbidden(res, message = '权限不足') {
  res.status(403).json({
    code: 403,
    message,
    data: null
  });
}

module.exports = {
  success,
  error,
  serverError,
  unauthorized,
  forbidden
};
