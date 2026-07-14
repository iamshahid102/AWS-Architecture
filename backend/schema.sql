-- Notes CRUD Application Database Schema
-- PostgreSQL 15.x

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on created_at for faster sorting
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);

-- Insert sample data (optional - for testing)
INSERT INTO notes (title, content) VALUES
  ('Welcome to Notes CRUD', 'This is your first note! The application is successfully deployed on AWS.'),
  ('AWS Infrastructure', 'Deployed with: VPC, ALB, EC2 (t3.micro), RDS (db.t3.micro), Auto Scaling Group - all within FREE TIER!'),
  ('Tech Stack', 'Backend: Node.js + Express + PostgreSQL, Frontend: React, Infrastructure: Terraform + Packer, CI/CD: GitHub Actions')
ON CONFLICT DO NOTHING;
