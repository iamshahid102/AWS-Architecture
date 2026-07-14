const { Pool } = require('pg');

// Database configuration - REQUIRED in production (set via Terraform/userdata)
// Defaults are ONLY for local development
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'your_password',
  database: process.env.DB_NAME || 'notes_db',
  // Production: SSL required for RDS
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  // Connection pool settings
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle database client', err);
  process.exit(-1);
});

// Test connection on startup (helps catch config issues early)
if (process.env.NODE_ENV === 'production') {
  pool.query('SELECT NOW()', (err) => {
    if (err) {
      console.error('Database connection test failed:', err.message);
    } else {
      console.log('Database connection verified');
    }
  });
}

module.exports = pool;
