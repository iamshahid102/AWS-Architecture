const { Router } = require('express');
const NotesController = require('../controllers/notes.controller');

const router = Router();

router.post('/', NotesController.create);
router.get('/', NotesController.getAll);
router.get('/:id', NotesController.getById);
router.put('/:id', NotesController.update);
router.delete('/:id', NotesController.delete);

module.exports = router;
