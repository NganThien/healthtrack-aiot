const { Pool } = require('pg');
require('dotenv').config();

// Ưu tiên DATABASE_URL (connection string Postgres của Supabase, dùng cho bridge
// chạy liên tục nên dùng Session Pooler port 5432, không dùng Transaction Pooler 6543).
// Fallback về các biến DB_* rời rạc để vẫn chạy được với Postgres local khi cần.
const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      options: `-c search_path=public`,
    })
  : new Pool({
      host:     process.env.DB_HOST,
      port:     process.env.DB_PORT,
      database: process.env.DB_NAME,
      user:     process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      options:  `-c search_path=public`,
    });

// Test kết nối khi khởi động
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Kết nối PostgreSQL thất bại:', err.message);
  } else {
    console.log('✅ Kết nối PostgreSQL thành công!');
    release();
  }
});

module.exports = pool;