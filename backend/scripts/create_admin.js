require('dotenv').config();

const bcrypt = require('bcryptjs');
const { execute } = require('../src/models');
const { pool, testConnection } = require('../src/config/db');

async function main() {
  const username = process.env.ADMIN_USERNAME;
  const password = process.env.ADMIN_INITIAL_PASSWORD;

  if (!username) {
    throw new Error('请设置 ADMIN_USERNAME');
  }
  if (!password || password.length < 12) {
    throw new Error('ADMIN_INITIAL_PASSWORD 至少需要 12 个字符');
  }
  if (!(await testConnection())) {
    throw new Error('数据库连接失败');
  }

  const passwordHash = await bcrypt.hash(password, 12);
  await execute(
    `INSERT INTO users (phone, nickname, password_hash, is_guest, gold, hints)
     VALUES (?, '管理员', ?, 0, 0, 0)
     ON DUPLICATE KEY UPDATE nickname = VALUES(nickname), password_hash = VALUES(password_hash), is_guest = 0`,
    [username, passwordHash]
  );
  console.log(`管理员账号 ${username} 已创建或更新`);
}

main()
  .catch((err) => {
    console.error(err.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
