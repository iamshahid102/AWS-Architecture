require('dotenv').config();
const express = require('express');
const cors = require('cors');
const notesRoutes = require('./routes/notes.routes');

const app = express();

app.use(cors());
app.use(express.json());

// Health check endpoint (for ALB/Nginx health checks)
app.get('/health', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'OK',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api/notes', notesRoutes);

app.use((err, _req, res, _next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong',
  });
});

module.exports = app;
