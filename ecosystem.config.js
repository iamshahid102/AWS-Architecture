module.exports = {
  apps: [
    {
      name: 'notes-crud-backend',
      cwd: '/home/ubuntu/notes-crud/backend',
      script: 'src/server.js',
      instances: 1,
      exec_mode: 'cluster',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        DB_HOST: process.env.DB_HOST || 'localhost',
        DB_PORT: parseInt(process.env.DB_PORT, '10') || 5432,
        DB_USER: process.env.DB_USER || 'notesadmin',
        DB_PASSWORD: process.env.DB_PASSWORD || '',
        DB_NAME: process.env.DB_NAME || 'notesdb'
      },
      error_file: '/home/ubuntu/notes-crud/logs/error.log',
      out_file: '/home/ubuntu/notes-crud/logs/out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true
    }
  ]
};
