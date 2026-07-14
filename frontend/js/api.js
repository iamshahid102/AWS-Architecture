/* ============================================================
   api.js - All Fetch API Calls for Notes CRUD
   ============================================================ */

/**
 * API configuration
 * Using relative path '/api' since Nginx proxies from same origin.
 * No hardcoded domain/port needed - works on any domain/IP.
 */
const API_BASE_URL = '/api';

/**
 * Generic request handler with error normalization.
 * @param {string} endpoint - API endpoint (e.g., '/notes')
 * @param {object} [options] - Fetch options
 * @returns {Promise<object>} Parsed response JSON
 * @throws {Error} On network failure or non-OK status
 */
async function apiRequest(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`;

  const config = {
    headers: {
      'Content-Type': 'application/json',
    },
    ...options,
  };

  let response;
  try {
    response = await fetch(url, config);
  } catch (error) {
    // Network error (offline, DNS failure, CORS, etc.)
    throw new Error('Network error. Please check your connection and try again.');
  }

  let data;
  try {
    data = await response.json();
  } catch (error) {
    throw new Error('Invalid response from server. Please try again.');
  }

  if (!response.ok) {
    const message = data && data.message
      ? data.message
      : getDefaultErrorMessage(response.status);
    throw new Error(message);
  }

  return data;
}

/**
 * Get a user-friendly default error message based on HTTP status code.
 * @param {number} status - HTTP status code
 * @returns {string} Error message
 */
function getDefaultErrorMessage(status) {
  switch (status) {
    case 400: return 'Invalid request. Please check your input.';
    case 404: return 'The requested resource was not found.';
    case 500: return 'Server error. Please try again later.';
    default: return `Request failed (${status}). Please try again.`;
  }
}

// ============================================================
// Notes API
// ============================================================

const NotesAPI = {

  /**
   * Create a new note.
   * @param {string} title - Note title
   * @param {string} content - Note content
   * @returns {Promise<object>} Created note data
   */
  async create(title, content) {
    const data = await apiRequest('/notes', {
      method: 'POST',
      body: JSON.stringify({ title, content }),
    });
    return data.data;
  },

  /**
   * Fetch all notes.
   * @returns {Promise<Array>} Array of notes
   */
  async getAll() {
    const data = await apiRequest('/notes');
    return data.data;
  },

  /**
   * Fetch a single note by ID.
   * @param {number|string} id - Note ID
   * @returns {Promise<object>} Note data
   */
  async getById(id) {
    const data = await apiRequest(`/notes/${id}`);
    return data.data;
  },

  /**
   * Update an existing note.
   * @param {number|string} id - Note ID
   * @param {string} title - Updated title
   * @param {string} content - Updated content
   * @returns {Promise<object>} Updated note data
   */
  async update(id, title, content) {
    const data = await apiRequest(`/notes/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ title, content }),
    });
    return data.data;
  },

  /**
   * Delete a note by ID.
   * @param {number|string} id - Note ID
   * @returns {Promise<void>}
   */
  async delete(id) {
    await apiRequest(`/notes/${id}`, {
      method: 'DELETE',
    });
  },
};
