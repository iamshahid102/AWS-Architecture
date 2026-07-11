/* ============================================================
   ui.js - DOM Rendering and UI Updates
   ============================================================ */

/**
 * Format a date string for display.
 * @param {string} dateString - ISO date string from backend
 * @returns {string} Formatted date
 */
function formatDate(dateString) {
  if (!dateString) return '';
  const date = new Date(dateString);
  const options = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  };
  return date.toLocaleDateString('en-US', options);
}

/**
 * Show a specific view (form or list).
 * @param {string} viewId - The view element ID ('form-view' or 'list-view')
 */
function showView(viewId) {
  document.querySelectorAll('.view').forEach((v) => {
    v.classList.remove('active-view');
  });
  const target = document.getElementById(viewId);
  if (target) {
    target.classList.add('active-view');
  }
}

/**
 * Show the loading state in the list view.
 */
function showLoadingState() {
  document.getElementById('loading-state').hidden = false;
  document.getElementById('error-state').hidden = true;
  document.getElementById('empty-state').hidden = true;
  document.getElementById('search-empty-state').hidden = true;
  document.getElementById('notes-grid').hidden = true;
}

/**
 * Show the error state in the list view.
 * @param {string} message - Error message to display
 */
function showErrorState(message) {
  document.getElementById('loading-state').hidden = true;
  document.getElementById('error-state').hidden = false;
  document.getElementById('empty-state').hidden = true;
  document.getElementById('search-empty-state').hidden = true;
  document.getElementById('notes-grid').hidden = true;
  document.getElementById('error-message').textContent = message || 'Unable to load notes. Please try again.';
}

/**
 * Show the empty state (no notes at all).
 */
function showEmptyState() {
  document.getElementById('loading-state').hidden = true;
  document.getElementById('error-state').hidden = true;
  document.getElementById('empty-state').hidden = false;
  document.getElementById('search-empty-state').hidden = true;
  document.getElementById('notes-grid').hidden = true;
}

/**
 * Show the search empty state.
 * @param {string} query - The search query used
 */
function showSearchEmptyState(query) {
  document.getElementById('loading-state').hidden = true;
  document.getElementById('error-state').hidden = true;
  document.getElementById('empty-state').hidden = true;
  document.getElementById('search-empty-state').hidden = false;
  document.getElementById('notes-grid').hidden = true;
  const textEl = document.getElementById('search-empty-text');
  textEl.textContent = query
    ? `No notes match "${query}". Try different keywords.`
    : 'No notes match your search. Try different keywords.';
}

/**
 * Render notes into the grid.
 * @param {Array} notes - Array of note objects
 */
function renderNotes(notes) {
  const grid = document.getElementById('notes-grid');

  if (!notes || notes.length === 0) {
    grid.hidden = true;
    return;
  }

  grid.innerHTML = notes.map((note) => createNoteCardHTML(note)).join('');
  grid.hidden = false;
}

/**
 * Create the HTML for a single note card.
 * @param {object} note - Note object
 * @returns {string} HTML string for the card
 */
function createNoteCardHTML(note) {
  const id = note.id;
  const title = escapeHtml(note.title || 'Untitled');
  const content = escapeHtml(note.content || '');
  const createdAt = formatDate(note.created_at);
  const updatedAt = formatDate(note.updated_at);

  // Use a deterministic animation delay based on note ID
  const delay = (id % 10) * 0.05;

  return `
    <article class="note-card" style="animation-delay: ${delay}s" data-id="${id}">
      <div class="note-card-header">
        <h3 class="note-card-title">${title}</h3>
        <div class="note-card-actions">
          <button
            class="btn-icon edit-btn"
            data-id="${id}"
            aria-label="Edit note: ${title}"
            title="Edit note"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
            </svg>
          </button>
          <button
            class="btn-icon delete-btn"
            data-id="${id}"
            aria-label="Delete note: ${title}"
            title="Delete note"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="3 6 5 6 21 6" />
              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
            </svg>
          </button>
        </div>
      </div>
      <div class="note-card-body">
        <p class="note-card-content">${content}</p>
      </div>
      <div class="note-card-footer">
        <div class="note-card-dates">
          <span class="note-date">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
              <line x1="16" y1="2" x2="16" y2="6" />
              <line x1="8" y1="2" x2="8" y2="6" />
              <line x1="3" y1="10" x2="21" y2="10" />
            </svg>
            Created: ${createdAt}
          </span>
          ${updatedAt !== createdAt
            ? `<span class="note-date">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="23 4 23 10 17 10" />
                  <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" />
                </svg>
                Updated: ${updatedAt}
              </span>`
            : ''
          }
        </div>
      </div>
    </article>
  `;
}

/**
 * Escape HTML special characters to prevent XSS.
 * @param {string} text - Raw text
 * @returns {string} Escaped HTML string
 */
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/**
 * Set the form to create mode (clear fields, change title).
 */
function setFormToCreateMode() {
  document.getElementById('form-title').textContent = 'Create New Note';
  document.getElementById('note-title').value = '';
  document.getElementById('note-content').value = '';
  document.getElementById('save-btn').querySelector('.btn-text').textContent = 'Save Note';
  document.getElementById('cancel-edit-btn').hidden = true;
  clearValidationErrors();
  updateTitleCharCount();

  // Remove data-editing attribute if present
  document.getElementById('note-form').removeAttribute('data-editing');
}

/**
 * Set the form to edit mode (populate fields with note data).
 * @param {object} note - Note object to edit
 */
function setFormToEditMode(note) {
  document.getElementById('form-title').textContent = 'Edit Note';
  document.getElementById('note-title').value = note.title || '';
  document.getElementById('note-content').value = note.content || '';
  document.getElementById('save-btn').querySelector('.btn-text').textContent = 'Update Note';
  document.getElementById('cancel-edit-btn').hidden = false;
  clearValidationErrors();
  updateTitleCharCount();

  // Store the editing note ID
  document.getElementById('note-form').setAttribute('data-editing', note.id);
}

/**
 * Update the notes count badge in the sidebar.
 * @param {number} count - Number of notes
 */
function updateNotesCount(count) {
  const badge = document.getElementById('notes-count-badge');
  badge.textContent = count;
  badge.classList.remove('bounce');
  // Trigger reflow to restart animation
  void badge.offsetWidth;
  badge.classList.add('bounce');
}

/**
 * Set button loading state (disable and show spinner).
 * @param {HTMLButtonElement} button - The button element
 * @param {boolean} isLoading - Whether to show loading state
 */
function setButtonLoading(button, isLoading) {
  button.disabled = isLoading;
  const textSpan = button.querySelector('.btn-text');
  const spinnerSpan = button.querySelector('.btn-spinner');
  if (textSpan) textSpan.hidden = isLoading;
  if (spinnerSpan) spinnerSpan.hidden = !isLoading;
}

// ============================================================
// Toast Notification System
// ============================================================

/**
 * Show a toast notification.
 * @param {string} message - Notification message
 * @param {'success'|'error'|'warning'} type - Toast type
 * @param {number} duration - Auto-dismiss duration in ms (0 = manual close)
 */
function showToast(message, type = 'success', duration = 4000) {
  const container = document.getElementById('toast-container');

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.setAttribute('role', 'alert');

  // Icon
  const icon = document.createElement('span');
  icon.className = 'toast-icon';
  icon.innerHTML = getToastIcon(type);
  toast.appendChild(icon);

  // Message
  const msg = document.createElement('span');
  msg.className = 'toast-message';
  msg.textContent = message;
  toast.appendChild(msg);

  // Close button
  const closeBtn = document.createElement('span');
  closeBtn.className = 'toast-close';
  closeBtn.innerHTML = `
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <line x1="18" y1="6" x2="6" y2="18" />
      <line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  `;
  closeBtn.setAttribute('aria-label', 'Dismiss notification');
  closeBtn.addEventListener('click', () => dismissToast(toast));
  toast.appendChild(closeBtn);

  container.appendChild(toast);

  // Auto-dismiss
  if (duration > 0) {
    setTimeout(() => dismissToast(toast), duration);
  }
}

/**
 * Animate and remove a toast.
 * @param {HTMLElement} toast - Toast element to dismiss
 */
function dismissToast(toast) {
  if (toast.classList.contains('toast-hiding')) return;
  toast.classList.add('toast-hiding');
  setTimeout(() => {
    if (toast.parentElement) {
      toast.parentElement.removeChild(toast);
    }
  }, 300);
}

/**
 * Get the appropriate SVG icon for a toast type.
 * @param {string} type - Toast type
 * @returns {string} SVG markup
 */
function getToastIcon(type) {
  switch (type) {
    case 'success':
      return `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
        <polyline points="22 4 12 14.01 9 11.01" />
      </svg>`;
    case 'error':
      return `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="10" />
        <line x1="15" y1="9" x2="9" y2="15" />
        <line x1="9" y1="9" x2="15" y2="15" />
      </svg>`;
    case 'warning':
      return `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
        <line x1="12" y1="9" x2="12" y2="13" />
        <line x1="12" y1="17" x2="12.01" y2="17" />
      </svg>`;
    default:
      return '';
  }
}

// ============================================================
// Delete Confirmation Modal
// ============================================================

/**
 * Show the delete confirmation modal.
 * @param {number|string} noteId - ID of the note to delete
 * @param {string} noteTitle - Title of the note to delete (for context)
 * @returns {Promise<boolean>} Resolves to true if confirmed, false if cancelled
 */
function showDeleteModal(noteId, noteTitle) {
  return new Promise((resolve) => {
    const modal = document.getElementById('delete-modal');
    const confirmBtn = document.getElementById('modal-confirm-btn');
    const cancelBtn = document.getElementById('modal-cancel-btn');
    const description = document.getElementById('modal-description');

    description.textContent = `Are you sure you want to delete "${noteTitle}"? This action cannot be undone.`;
    modal.hidden = false;

    // Focus the cancel button for safety
    setTimeout(() => cancelBtn.focus(), 100);

    function cleanup() {
      modal.hidden = true;
      confirmBtn.removeEventListener('click', onConfirm);
      cancelBtn.removeEventListener('click', onCancel);
      modal.removeEventListener('click', onOverlayClick);
      document.removeEventListener('keydown', onKeydown);
    }

    function onConfirm() {
      cleanup();
      resolve(true);
    }

    function onCancel() {
      cleanup();
      resolve(false);
    }

    function onOverlayClick(e) {
      if (e.target === modal) onCancel();
    }

    function onKeydown(e) {
      if (e.key === 'Escape') onCancel();
      if (e.key === 'Enter' && e.target === confirmBtn) onConfirm();
    }

    confirmBtn.addEventListener('click', onConfirm);
    cancelBtn.addEventListener('click', onCancel);
    modal.addEventListener('click', onOverlayClick);
    document.addEventListener('keydown', onKeydown);
  });
}
