# Notes API Backend

A REST API backend for Notes CRUD operations built with Node.js, Express, and PostgreSQL.

## Tech Stack

- Node.js
- Express.js
- PostgreSQL
- pg (PostgreSQL driver)
- dotenv
- cors
- nodemon (development)

## Installation

```bash
git clone <repo-url>
cd notes-backend
npm install
```

## Environment Variables

Copy `.env.example` to `.env` and update the values:

```env
PORT=5000

DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=notes_db
```

## PostgreSQL Setup

1. Install PostgreSQL and start the service.
2. Create a database:

```sql
CREATE DATABASE notes_db;
```

3. Create the notes table:

```sql
CREATE TABLE notes (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## How to Run

```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

| Method | Endpoint         | Description     |
| ------ | ---------------- | --------------- |
| POST   | /api/notes       | Create a note   |
| GET    | /api/notes       | Get all notes   |
| GET    | /api/notes/:id   | Get a note      |
| PUT    | /api/notes/:id   | Update a note   |
| DELETE | /api/notes/:id   | Delete a note   |

## Example Requests

### Create Note

```bash
curl -X POST http://localhost:5000/api/notes \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Express", "content": "Build CRUD API"}'
```

### Get All Notes

```bash
curl http://localhost:5000/api/notes
```

### Get Single Note

```bash
curl http://localhost:5000/api/notes/1
```

### Update Note

```bash
curl -X PUT http://localhost:5000/api/notes/1 \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Title", "content": "Updated content"}'
```

### Delete Note

```bash
curl -X DELETE http://localhost:5000/api/notes/1
```
