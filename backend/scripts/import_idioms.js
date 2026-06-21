const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { pool } = require('../src/config/db');

const columns = [
  'idiom', 'pinyin', 'pinyin_no_tones', 'first_char', 'first_pinyin',
  'first_pinyin_no_tone', 'last_char', 'last_pinyin', 'last_pinyin_no_tone', 'meaning'
];

async function main() {
  const source = path.resolve(__dirname, '../../shared/data/idioms.json');
  const idioms = JSON.parse(fs.readFileSync(source, 'utf8'));
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const batchSize = 250;
    for (let offset = 0; offset < idioms.length; offset += batchSize) {
      const batch = idioms.slice(offset, offset + batchSize);
      const placeholders = batch.map(() => `(${columns.map(() => '?').join(',')})`).join(',');
      const values = batch.flatMap((item) => columns.map((column) => item[column] ?? null));
      const updates = columns.slice(1).map((column) => `${column}=VALUES(${column})`).join(',');
      await connection.execute(
        `INSERT INTO idioms (${columns.join(',')}) VALUES ${placeholders} ON DUPLICATE KEY UPDATE ${updates}`,
        values
      );
    }
    await connection.commit();
    const [[row]] = await connection.execute('SELECT COUNT(*) AS total FROM idioms');
    console.log(`Imported ${idioms.length} idioms; database total: ${row.total}`);
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
