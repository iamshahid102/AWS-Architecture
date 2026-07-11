# NotesApp - Frontend

A modern, responsive, production-quality **Notes CRUD Application** frontend built with **pure HTML5, CSS3, and Vanilla JavaScript (ES6+)**.

## Tech Stack

- **HTML5** - Semantic markup with ARIA attributes
- **CSS3** - Flexbox, Grid, CSS Variables, Animations, Responsive Design
- **Vanilla JavaScript (ES6+)** - Fetch API, modular architecture, event delegation

## Folder Structure

```
frontend/
│
├── index.html          # Main HTML file with semantic structure
├── css/
│   └── style.css       # Complete stylesheet with CSS variables & responsive design
├── js/
│   ├── api.js          # All Fetch API calls (CRUD operations)
│   ├── validation.js   # Form validation logic
│   ├── ui.js           # DOM rendering, toasts, modals
│   └── app.js          # App initialization, state management, event handlers
├── assets/
│   ├── icons/
│   └── images/
└── README.md           # Project documentation
```

## Features

### CRUD Operations
- **Create** - Add new notes with title and content
- **Read** - View all notes or a single note
- **Update** - Edit existing notes
- **Delete** - Remove notes with confirmation dialog

### User Interface
- **Modern SaaS-style Design** - Clean, professional aesthetic
- **Dark Mode / Light Mode** - Theme toggle with system preference detection
- **Responsive Layout** - Optimized for mobile, tablet, and desktop
- **Sticky Header** - Always accessible navigation
- **Collapsible Sidebar** - Mobile-friendly navigation
- **Smooth Animations** - Card pop-in, toast slide-in, modal scale-in
- **Hover Effects** - Card elevation, button transforms, color transitions

### Search & Filtering
- **Real-time Search** - Filter notes instantly while typing
- **Case-insensitive** - Search by title and content
- **Instant feedback** - Results update as you type

### User Experience
- **Loading States** - Animated spinner while fetching data
- **Empty States** - Friendly messages when no notes exist
- **Error States** - User-friendly error messages with retry option
- **Toast Notifications** - Success, error, and warning alerts
- **Delete Confirmation** - Modal dialog to prevent accidental deletions
- **Form Validation** - Real-time validation with visual feedback
- **Character Count** - Live title character counter
- **Button Loading States** - Disabled buttons with spinner during API calls
- **Auto-refresh** - UI updates automatically after every CRUD operation

### Accessibility
- Semantic HTML5 elements (`<main>`, `<aside>`, `<nav>`, `<article>`, etc.)
- ARIA attributes (`aria-label`, `aria-current`, `aria-live`, `role="alert"`, etc.)
- Keyboard navigation support
- Skip-to-content link
- Focus-visible indicators
- Reduced motion support (`prefers-reduced-motion`)
- Screen reader friendly states

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd notes-app
   ```

2. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

3. Open `index.html` in your browser:
   ```bash
   # Option 1: Open directly
   open index.html

   # Option 2: Serve with a local server (recommended)
   npx serve .
   ```

## Backend API Configuration

The frontend communicates with the backend REST API via the Fetch API.

### Default Configuration

By default, the API base URL is set to `http://localhost:5000/api`.

### Update API URL

To change the backend URL, edit the `API_BASE_URL` constant in `js/api.js`:

```javascript
const API_BASE_URL = 'http://localhost:5000/api';
```

### Backend API Endpoints

| Method | Endpoint          | Description      |
|--------|-------------------|------------------|
| POST   | `/api/notes`      | Create a note    |
| GET    | `/api/notes`      | Get all notes    |
| GET    | `/api/notes/:id`  | Get a single note|
| PUT    | `/api/notes/:id`  | Update a note    |
| DELETE | `/api/notes/:id`  | Delete a note    |

### Backend Setup

The backend is built with **Node.js, Express.js, and PostgreSQL**.

```bash
cd backend
npm install
npm run dev
```

Make sure your PostgreSQL database is running and configured in the backend `.env` file.

## How to Run

### Option 1: Direct Open

Simply open `frontend/index.html` in any modern browser.

### Option 2: Local Server (Recommended)

Use any static file server to avoid CORS issues:

```bash
# Using npx (comes with Node.js)
npx serve frontend/

# Using Python
python3 -m http.server 8000 --directory frontend/

# Using VS Code Live Server extension
# Right-click index.html → Open with Live Server
```

Then open `http://localhost:3000` (or the port shown) in your browser.

## Screenshots

<!-- Add screenshots here -->
| Page | Screenshot |
|------|-----------|
| Notes List | _Screenshot coming soon_ |
| Create Note | _Screenshot coming soon_ |
| Edit Note | _Screenshot coming soon_ |
| Dark Mode | _Screenshot coming soon_ |
| Mobile View | _Screenshot coming soon_ |

## Browser Compatibility

- **Chrome** (latest 2 versions)
- **Firefox** (latest 2 versions)
- **Safari** (latest 2 versions)
- **Edge** (latest 2 versions)
- **Opera** (latest 2 versions)

The frontend uses modern CSS features (CSS Grid, Flexbox, CSS Variables, `backdrop-filter`) and JavaScript ES6+ features (Fetch API, `async/await`, arrow functions, template literals, destructuring).

## Code Architecture

### `api.js`
- All Fetch API calls to the backend
- Generic request handler with error normalization
- User-friendly error messages based on HTTP status codes

### `validation.js`
- Form validation functions
- Field-level error messages
- Real-time character count updates

### `ui.js`
- DOM rendering and manipulation
- Toast notification system
- Delete confirmation modal
- Note card HTML generation
- State management (loading, empty, error states)

### `app.js`
- Application initialization
- Event listener registration
- State management for notes and search
- CRUD operation orchestration
- Theme management with localStorage persistence
- Sidebar toggle for mobile
- Event delegation for dynamic note cards

## License

MIT
