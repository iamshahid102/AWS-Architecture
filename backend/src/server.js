const app = require('./app');

// PORT: In production (Terraform/EC2), this comes from environment variable
// Default 5000 is ONLY for local development
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
