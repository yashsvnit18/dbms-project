// =============================================================================
// DATABASE CONNECTION POOL (MySQL with mysql2 Promise API)
// =============================================================================

const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'hostel_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  multipleStatements: true
});

async function testConnection() {
  try {
    const conn = await pool.getConnection();
    console.log('[MySQL] Connected to database: ' + (process.env.DB_NAME || 'hostel_db'));
    conn.release();
    return true;
  } catch (err) {
    console.error('[MySQL Error] Could not connect:', err.message);
    return false;
  }
}

module.exports = {
  pool,
  testConnection
};

