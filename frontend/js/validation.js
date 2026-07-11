/* ============================================================
   validation.js - Form Validation Logic
   ============================================================ */

/**
 * Maximum allowed characters for the title field.
 */
const TITLE_MAX_LENGTH = 100;

/**
 * Validation result object.
 * @typedef {object} ValidationResult
 * @property {boolean} isValid - Whether validation passed
 * @property {object} errors - Field-specific error messages
 */

/**
 * Validate note form fields.
 * @param {string} title - The note title
 * @param {string} content - The note content
 * @returns {ValidationResult} Validation result with errors
 */
function validateNoteForm(title, content) {
  const errors = {
    title: '',
    content: '',
  };

  // Validate title
  const trimmedTitle = title ? title.trim() : '';
  if (!trimmedTitle) {
    errors.title = 'Title is required.';
  } else if (trimmedTitle.length > TITLE_MAX_LENGTH) {
    errors.title = `Title must not exceed ${TITLE_MAX_LENGTH} characters.`;
  }

  // Validate content
  const trimmedContent = content ? content.trim() : '';
  if (!trimmedContent) {
    errors.content = 'Content is required.';
  }

  const isValid = !errors.title && !errors.content;

  return { isValid, errors };
}

/**
 * Display field-level validation errors in the UI.
 * @param {object} errors - Object with field error messages
 */
function showValidationErrors(errors) {
  const titleInput = document.getElementById('note-title');
  const contentInput = document.getElementById('note-content');
  const titleError = document.getElementById('title-error');
  const contentError = document.getElementById('content-error');

  // Title
  if (errors.title) {
    titleInput.classList.add('error');
    titleError.textContent = errors.title;
  } else {
    titleInput.classList.remove('error');
    titleError.textContent = '';
  }

  // Content
  if (errors.content) {
    contentInput.classList.add('error');
    contentError.textContent = errors.content;
  } else {
    contentInput.classList.remove('error');
    contentError.textContent = '';
  }
}

/**
 * Clear all validation error indicators.
 */
function clearValidationErrors() {
  const titleInput = document.getElementById('note-title');
  const contentInput = document.getElementById('note-content');
  const titleError = document.getElementById('title-error');
  const contentError = document.getElementById('content-error');

  titleInput.classList.remove('error');
  contentInput.classList.remove('error');
  titleError.textContent = '';
  contentError.textContent = '';
}

/**
 * Update the character count display for the title field.
 */
function updateTitleCharCount() {
  const titleInput = document.getElementById('note-title');
  const countDisplay = document.getElementById('title-count');
  const currentLength = titleInput.value.length;
  countDisplay.textContent = currentLength;

  // Visual feedback near the limit
  if (currentLength >= TITLE_MAX_LENGTH) {
    countDisplay.style.color = 'var(--color-danger)';
  } else if (currentLength >= TITLE_MAX_LENGTH * 0.85) {
    countDisplay.style.color = 'var(--color-warning)';
  } else {
    countDisplay.style.color = 'var(--color-text-muted)';
  }
}
