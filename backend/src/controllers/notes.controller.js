const NotesModel = require('../models/notes.model');

const NotesController = {
  async create(req, res, next) {
    try {
      const { title, content } = req.body;

      if (!title || !title.trim()) {
        return res.status(400).json({
          success: false,
          message: 'Title is required',
        });
      }

      if (!content || !content.trim()) {
        return res.status(400).json({
          success: false,
          message: 'Content is required',
        });
      }

      const note = await NotesModel.create(title.trim(), content.trim());

      return res.status(201).json({
        success: true,
        message: 'Note created successfully',
        data: note,
      });
    } catch (error) {
      next(error);
    }
  },

  async getAll(req, res, next) {
    try {
      const notes = await NotesModel.findAll();

      return res.status(200).json({
        success: true,
        message: 'Notes retrieved successfully',
        data: notes,
      });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const { id } = req.params;
      const note = await NotesModel.findById(id);

      if (!note) {
        return res.status(404).json({
          success: false,
          message: 'Note not found',
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Note retrieved successfully',
        data: note,
      });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const { id } = req.params;
      const { title, content } = req.body;

      if (!title || !title.trim()) {
        return res.status(400).json({
          success: false,
          message: 'Title is required',
        });
      }

      if (!content || !content.trim()) {
        return res.status(400).json({
          success: false,
          message: 'Content is required',
        });
      }

      const note = await NotesModel.update(id, title.trim(), content.trim());

      if (!note) {
        return res.status(404).json({
          success: false,
          message: 'Note not found',
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Note updated successfully',
        data: note,
      });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      const { id } = req.params;
      const deleted = await NotesModel.delete(id);

      if (!deleted) {
        return res.status(404).json({
          success: false,
          message: 'Note not found',
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Note deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  },
};

module.exports = NotesController;
