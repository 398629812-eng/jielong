/**
 * 数据库模型封装层（Promise-based）
 * 所有数据库操作统一通过此模块进行，便于维护和替换底层驱动
 * 提供常用 CRUD 辅助函数和事务支持
 */

const { pool } = require('../config/db');

/**
 * 执行单条 SQL 查询，返回结果数组
 * @param {string} sql - SQL 语句
 * @param {array} params - 参数数组（用于防止 SQL 注入）
 * @returns {Promise<Array>} 查询结果数组
 */
async function query(sql, params = []) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

/**
 * 执行单条 SQL 查询，返回单条记录（第一条）
 * @param {string} sql - SQL 语句
 * @param {array} params - 参数数组
 * @returns {Promise<object|null>} 单条记录或 null
 */
async function queryOne(sql, params = []) {
  const rows = await query(sql, params);
  return rows.length > 0 ? rows[0] : null;
}

/**
 * 执行 INSERT / UPDATE / DELETE 语句，返回受影响行数
 * @param {string} sql - SQL 语句
 * @param {array} params - 参数数组
 * @returns {Promise<object>} 包含 affectedRows, insertId 的结果对象
 */
async function execute(sql, params = []) {
  const [result] = await pool.execute(sql, params);
  return {
    affectedRows: result.affectedRows,
    insertId: result.insertId
  };
}

/**
 * 开启事务，执行多个操作后统一提交或回滚
 * @param {Function} callback - 接收 connection 参数的回掉函数，内部使用 connection.execute
 * @returns {Promise<any>} callback 的返回值
 */
async function transaction(callback) {
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
}

/**
 * 分页查询辅助函数
 * @param {string} baseSql - 不带 LIMIT 的 SQL（可包含 ORDER BY）
 * @param {array} params - SQL 参数
 * @param {number} page - 页码（从 1 开始）
 * @param {number} pageSize - 每页条数
 * @returns {Promise<{list: Array, total: number, page: number, pageSize: number, totalPages: number}>}
 */
async function paginate(baseSql, params, page = 1, pageSize = 20) {
  const offset = (page - 1) * pageSize;
  // 查询总数
  const countSql = `SELECT COUNT(*) AS total FROM (${baseSql}) AS t`;
  const countRows = await query(countSql, params);
  const total = countRows[0].total;
  // 查询分页数据
  // 注意：MySQL2 在某些版本中对 LIMIT/OFFSET 使用数字参数会报错，
  // 这里转换为字符串避免 "Incorrect arguments to mysqld_stmt_execute"
  const dataSql = `${baseSql} LIMIT ? OFFSET ?`;
  const list = await query(dataSql, [...params, String(pageSize), String(offset)]);
  return {
    list,
    total,
    page: parseInt(page, 10),
    pageSize: parseInt(pageSize, 10),
    totalPages: Math.ceil(total / pageSize)
  };
}

module.exports = {
  query,
  queryOne,
  execute,
  transaction,
  paginate
};
