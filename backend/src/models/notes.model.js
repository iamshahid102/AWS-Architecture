const pool = require('../config/database');

const NotesModel = {
  async create(title, content) {
    const query = `
      INSERT INTO notes (title, content)
      VALUES ($1, $2)
      RETURNING id, title, content, created_at, updated_at
    `;
    const values = [title, content];
    const { rows } = await pool.query(query, values);
    return rows[0];
  },

  async findAll() {
    const query = `
      SELECT id, title, content, created_at, updated_at
      FROM notes
      ORDER BY created_at DESC
    `;
    const { rows } = await pool.query(query);
    return rows;
  },

  async findById(id) {
    const query = `
      SELECT id, title, content, created_at, updated_at
      FROM notes
      WHERE id = $1
    `;
    const { rows } = await pool.query(query, [id]);
    return rows[0] || null;
  },

  async update(id, title, content) {
    const query = `
      UPDATE notes
      SET title = $1, content = $2, updated_at = CURRENT_TIMESTAMP
      WHERE id = $3
      RETURNING id, title, content, created_at, updated_at
    `;
    const values = [title, content, id];
    const { rows } = await pool.query(query, values);
    return rows[0] || null;
  },

  async delete(id) {
    const query = 'DELETE FROM notes WHERE id = $1 RETURNING id';
    const { rows } = await pool.query(query, [id]);
    return rows[0] || null;
  },
};

module.exports = NotesModel;
