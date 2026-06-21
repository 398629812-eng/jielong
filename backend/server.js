/**
 * 成语接龙游戏后端服务入口文件（server.js）
 * --------------------------------------------------
 * 启动 Express 服务，加载所有路由和中间件，配置跨域、安全头、请求解析等。
 * 依赖 dotenv 加载环境变量，数据库连接池在启动时测试连通性。
 */

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const { testConnection } = require('./src/config/db');
const { generalLimiter } = require('./src/middleware/rateLimiter');
const { success } = require('./src/utils/response');

const app = express();
const PORT = process.env.PORT || 3000;

// 1. 全局中间件
// 解析 JSON 请求体
app.use(express.json());
// 解析 URL 编码表单（兼容部分旧客户端）
app.use(express.urlencoded({ extended: true }));
// 跨域支持（允许所有来源，生产环境可限制为特定域名）
app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'] }));
// 安全头（XSS 过滤、Content-Security-Policy 等）
app.use(helmet({ contentSecurityPolicy: false }));
// 通用频率限制（防止恶意请求）
app.use(generalLimiter);

// 2. 健康检查接口（无需认证，用于部署监控）
app.get('/health', (req, res) => {
  success(res, { status: 'ok', time: new Date().toISOString() }, '服务运行正常');
});

// 3. 加载路由
// 认证相关
app.use('/api/auth', require('./src/routes/auth'));
// 用户相关（内部需要 auth 中间件）
app.use('/api/user', require('./src/routes/user'));
// 金币/广告相关
app.use('/api/gold', require('./src/routes/gold'));
// 游戏相关
app.use('/api/game', require('./src/routes/game'));
// 提现相关
app.use('/api/withdraw', require('./src/routes/withdraw'));
// 配置/公告（无需登录）
app.use('/api/config', require('./src/routes/config'));
// 管理后台（部分接口需要 adminAuth）
app.use('/api/admin', require('./src/routes/admin'));

// 4. 404 处理
app.use((req, res) => {
  res.status(404).json({ code: 404, message: '接口不存在', data: null });
});

// 5. 全局错误处理
app.use((err, req, res, next) => {
  console.error('服务器错误:', err.stack);
  res.status(500).json({ code: 500, message: '服务器内部错误', data: null });
});

// 6. 启动服务
async function startServer() {
  // 先测试数据库连接
  const dbOk = await testConnection();
  if (!dbOk) {
    console.warn('⚠️ 数据库连接失败，服务将继续启动，但数据库功能可能不可用');
  }

  app.listen(PORT, () => {
    console.log(`🚀 成语接龙后端服务已启动，监听端口 ${PORT}`);
    console.log(`📖 API 文档：http://localhost:${PORT}/api/config（获取配置）`);
    console.log(`❤️  健康检查：http://localhost:${PORT}/health`);
  });
}

startServer();
