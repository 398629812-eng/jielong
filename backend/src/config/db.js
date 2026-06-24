/**
 * MySQL 数据库连接配置模块
 * 使用 mysql2 的 Promise 封装，支持 async/await 语法
 * 提供数据库连接池，自动管理连接复用
 */

const mysql = require('mysql2/promise');

// 从环境变量读取数据库配置，提供默认值方便本地开发
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD ?? '',
  database: process.env.DB_NAME || 'jielong',
  // 连接池配置：最多同时保持 10 个连接
  connectionLimit: 10,
  // 队列限制：当所有连接都在使用中时，最多排队 0 个请求（立即拒绝）
  queueLimit: 0,
  // 连接超时时间（毫秒）
  connectTimeout: 10000
});

/**
 * 测试数据库连接是否可用
 * 在应用启动时调用，提前发现配置错误
 */
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ MySQL 数据库连接成功');
    connection.release();
    return true;
  } catch (err) {
    console.error('❌ MySQL 数据库连接失败:', err.message);
    return false;
  }
}

module.exports = {
  pool,
  testConnection
};
