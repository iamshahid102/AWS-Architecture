require('dotenv').config();
const express = require('express');
const cors = require('cors');
const notesRoutes = require('./routes/notes.routes');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/notes', notesRoutes);

app.use((err, _req, res, _next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong',
  });
});

module.exports = app;
