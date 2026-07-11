/* ============================================================
   app.js - Application Initialization and Event Handlers
   ============================================================ */

(function () {
  "use strict";

  // ============================================================
  // State
  // ============================================================

  /** @type {Array} All notes loaded from the API */
  let allNotes = [];

  /** @type {string} Current search query */
  let searchQuery = "";

  /** @type {number|null} ID of the note being deleted */
  let deletingNoteId = null;

  // ============================================================
  // DOM References
  // ============================================================

  const elements = {
    form: document.getElementById("note-form"),
    titleInput: document.getElementById("note-title"),
    contentInput: document.getElementById("note-content"),
    saveBtn: document.getElementById("save-btn"),
    cancelEditBtn: document.getElementById("cancel-edit-btn"),
    searchInput: document.getElementById("search-input"),
    notesGrid: document.getElementById("notes-grid"),
    retryBtn: document.getElementById("retry-btn"),
    emptyCreateBtn: document.getElementById("empty-create-btn"),
    sidebar: document.getElementById("sidebar"),
    sidebarToggle: document.getElementById("sidebar-toggle"),
    sidebarClose: document.getElementById("sidebar-close-btn"),
    sidebarOverlay: document.getElementById("sidebar-overlay"),
    themeToggle: document.getElementById("theme-toggle"),
    themeLabel: document.getElementById("theme-label"),
    navNewNote: document.getElementById("nav-new-note"),
    navAllNotes: document.getElementById("nav-all-notes"),
  };

  // ============================================================
  // Theme Management
  // ============================================================

  /**
   * Get the current theme from localStorage or system preference.
   * @returns {'light'|'dark'}
   */
  function getPreferredTheme() {
    const stored = localStorage.getItem("notesapp-theme");
    if (stored === "light" || stored === "dark") {
      return stored;
    }
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  }

  /**
   * Apply the given theme to the document.
   * @param {'light'|'dark'} theme
   */
  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("notesapp-theme", theme);

    // Update toggle label
    elements.themeLabel.textContent =
      theme === "dark" ? "Light Mode" : "Dark Mode";
  }

  /**
   * Toggle between light and dark theme.
   */
  function toggleTheme() {
    const current =
      document.documentElement.getAttribute("data-theme") || "light";
    const next = current === "light" ? "dark" : "light";
    applyTheme(next);
  }

  // ============================================================
  // Sidebar Management (Mobile)
  // ============================================================

  function openSidebar() {
    elements.sidebar.classList.add("open");
    elements.sidebarOverlay.classList.add("active");
    document.body.style.overflow = "hidden";
  }

  function closeSidebar() {
    elements.sidebar.classList.remove("open");
    elements.sidebarOverlay.classList.remove("active");
    document.body.style.overflow = "";
  }

  // ============================================================
  // Navigation
  // ============================================================

  /**
   * Navigate to the new note form.
   */
  function navigateToNewNote() {
    setFormToCreateMode();
    showView("form-view");
    elements.navNewNote.classList.add("active");
    elements.navAllNotes.classList.remove("active");
    elements.titleInput.focus();
    closeSidebar();
  }

  /**
   * Navigate to the all notes list.
   */
  function navigateToAllNotes() {
    showView("list-view");
    elements.navAllNotes.classList.add("active");
    elements.navNewNote.classList.remove("active");
    closeSidebar();
    loadNotes();
  }

  /**
   * Navigate to edit a specific note.
   * @param {number|string} noteId
   */
  async function navigateToEditNote(noteId) {
    try {
      const note = await NotesAPI.getById(noteId);
      if (!note) {
        showToast("Note not found.", "error");
        return;
      }
      setFormToEditMode(note);
      showView("form-view");
      elements.navNewNote.classList.add("active");
      elements.navAllNotes.classList.remove("active");
      elements.titleInput.focus();
      closeSidebar();
    } catch (error) {
      showToast(error.message || "Failed to load note for editing.", "error");
    }
  }

  // ============================================================
  // Notes CRUD Operations
  // ============================================================

  /**
   * Load all notes from the API and update the UI.
   */
  async function loadNotes() {
    showLoadingState();

    try {
      allNotes = await NotesAPI.getAll();
      handleNotesLoaded();
    } catch (error) {
      showErrorState(error.message);
    }
  }

  /**
   * Process loaded notes: filter by search query and render.
   */
  function handleNotesLoaded() {
    updateNotesCount(allNotes.length);

    if (allNotes.length === 0) {
      // No notes at all — show the empty state (no notes to search)
      document.getElementById("notes-grid").hidden = true;
      showEmptyState();
      return;
    }

    // Filter by search query
    const filtered = filterNotes(allNotes, searchQuery);

    if (filtered.length === 0) {
      showSearchEmptyState(searchQuery);
    } else {
      // Hide the loading state when showing notes
      document.getElementById('loading-state').hidden = true;
      renderNotes(filtered);
      // Ensure the list view is visible if no other view is active
      if (!document.querySelector(".view.active-view")) {
        showView("list-view");
      }
    }
  }

  /**
   * Filter notes by search query (case-insensitive, title + content).
   * @param {Array} notes - Notes to filter
   * @param {string} query - Search query
   * @returns {Array} Filtered notes
   */
  function filterNotes(notes, query) {
    if (!query || !query.trim()) return notes;

    const q = query.trim().toLowerCase();
    return notes.filter((note) => {
      const title = (note.title || "").toLowerCase();
      const content = (note.content || "").toLowerCase();
      return title.includes(q) || content.includes(q);
    });
  }

  /**
   * Handle form submission (create or update).
   * @param {Event} event - Submit event
   */
  async function handleFormSubmit(event) {
    event.preventDefault();

    const title = elements.titleInput.value;
    const content = elements.contentInput.value;

    // Validate
    const { isValid, errors } = validateNoteForm(title, content);
    showValidationErrors(errors);

    if (!isValid) {
      return;
    }

    // Determine if creating or updating
    const editingId = elements.form.getAttribute("data-editing");
    const isEditing = !!editingId;

    // Set loading state
    setButtonLoading(elements.saveBtn, true);

    try {
      if (isEditing) {
        const updatedNote = await NotesAPI.update(
          editingId,
          title.trim(),
          content.trim(),
        );
        showToast("Note updated successfully!", "success");
        elements.form.removeAttribute("data-editing");
      } else {
        const newNote = await NotesAPI.create(title.trim(), content.trim());
        showToast("Note created successfully!", "success");
      }

      // Reset form and reload
      setFormToCreateMode();
      navigateToAllNotes();
    } catch (error) {
      showToast(error.message || "Failed to save note.", "error");
    } finally {
      setButtonLoading(elements.saveBtn, false);
    }
  }

  /**
   * Handle cancel edit button click.
   */
  function handleCancelEdit() {
    setFormToCreateMode();
    navigateToNewNote();
  }

  /**
   * Handle delete button click on a note card.
   * @param {number|string} noteId
   * @param {string} noteTitle
   */
  async function handleDeleteNote(noteId, noteTitle) {
    if (deletingNoteId !== null) return; // Already deleting

    deletingNoteId = noteId;

    try {
      const confirmed = await showDeleteModal(noteId, noteTitle);

      if (!confirmed) {
        deletingNoteId = null;
        return;
      }

      await NotesAPI.delete(noteId);
      showToast("Note deleted successfully.", "success");
      deletingNoteId = null;

      // Reload the notes list
      await loadNotes();
    } catch (error) {
      showToast(error.message || "Failed to delete note.", "error");
      deletingNoteId = null;
    }
  }

  // ============================================================
  // Event Delegation (for dynamically created note cards)
  // ============================================================

  /**
   * Handle clicks within the notes grid (event delegation).
   * @param {Event} event
   */
  function handleNotesGridClick(event) {
    const target = event.target.closest("button");
    if (!target) return;

    const noteCard = target.closest(".note-card");
    if (!noteCard) return;

    const noteId = noteCard.getAttribute("data-id");
    if (!noteId) return;

    // Edit button
    if (target.classList.contains("edit-btn")) {
      navigateToEditNote(noteId);
      return;
    }

    // Delete button
    if (target.classList.contains("delete-btn")) {
      const titleEl = noteCard.querySelector(".note-card-title");
      const noteTitle = titleEl ? titleEl.textContent : "Untitled";
      handleDeleteNote(noteId, noteTitle);
      return;
    }
  }

  // ============================================================
  // Search
  // ============================================================

  /**
   * Handle search input changes with debounce.
   */
  let searchTimeout = null;

  function handleSearchInput() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
      searchQuery = elements.searchInput.value;
      handleNotesLoaded();
    }, 250);
  }

  // ============================================================
  // Event Listeners Registration
  // ============================================================

  function registerEventListeners() {
    // Form submit
    elements.form.addEventListener("submit", handleFormSubmit);

    // Cancel edit
    elements.cancelEditBtn.addEventListener("click", handleCancelEdit);

    // Real-time character count
    elements.titleInput.addEventListener("input", updateTitleCharCount);

    // Search
    elements.searchInput.addEventListener("input", handleSearchInput);

    // Notes grid (event delegation)
    elements.notesGrid.addEventListener("click", handleNotesGridClick);

    // Retry button
    elements.retryBtn.addEventListener("click", loadNotes);

    // Empty state "Create" button
    elements.emptyCreateBtn.addEventListener("click", navigateToNewNote);

    // Sidebar
    elements.sidebarToggle.addEventListener("click", openSidebar);
    elements.sidebarClose.addEventListener("click", closeSidebar);
    elements.sidebarOverlay.addEventListener("click", closeSidebar);

    // Navigation
    elements.navNewNote.addEventListener("click", navigateToNewNote);
    elements.navAllNotes.addEventListener("click", navigateToAllNotes);

    // Theme toggle
    elements.themeToggle.addEventListener("click", toggleTheme);

    // Keyboard: Escape to close sidebar
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        if (elements.sidebar.classList.contains("open")) {
          closeSidebar();
        }
      }
    });
  }

  // ============================================================
  // Initialization
  // ============================================================

  function init() {
    // Apply saved theme
    applyTheme(getPreferredTheme());

    // Register all event listeners
    registerEventListeners();

    // Start with the list view so users see their notes right away
    showView("list-view");
    elements.navAllNotes.classList.add("active");
    elements.navNewNote.classList.remove("active");

    // Load notes on startup
    loadNotes();
  }

  // Boot the application when DOM is ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
