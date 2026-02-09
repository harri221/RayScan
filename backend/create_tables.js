const { Pool } = require('pg');
require('dotenv').config();

async function createTables() {
  const pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 5432,
  });

  try {
    console.log('🔄 Creating essential tables for authentication...');

    // Create users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        phone VARCHAR(20),
        password VARCHAR(255) NOT NULL,
        profile_image VARCHAR(255),
        date_of_birth DATE,
        gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
        address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE
      )
    `);
    console.log('✅ Users table created');

    // Create doctors table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS doctors (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        phone VARCHAR(20),
        specialty VARCHAR(100) NOT NULL,
        qualification VARCHAR(255),
        experience_years INTEGER DEFAULT 0,
        rating DECIMAL(2,1) DEFAULT 0.0,
        consultation_fee DECIMAL(10,2) DEFAULT 0.00,
        about TEXT,
        profile_image VARCHAR(255),
        is_available BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Doctors table created');

    // Create password reset tokens table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS password_reset_tokens (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token VARCHAR(6) NOT NULL,
        contact_info VARCHAR(100) NOT NULL,
        contact_type VARCHAR(10) NOT NULL CHECK (contact_type IN ('email', 'phone')),
        expires_at TIMESTAMP NOT NULL,
        is_used BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Password reset tokens table created');

    // Insert sample doctors
    const doctorCheck = await pool.query('SELECT COUNT(*) FROM doctors');
    if (parseInt(doctorCheck.rows[0].count) === 0) {
      await pool.query(`
        INSERT INTO doctors (name, email, phone, specialty, qualification, experience_years, rating, consultation_fee, about) VALUES
        ('Dr. Marcus Horizon', 'marcus@rayscan.com', '+1234567890', 'Cardiologist', 'MD Cardiology', 15, 4.7, 60.00, 'Experienced cardiologist specializing in heart diseases and preventive care.'),
        ('Dr. Maria Elena', 'maria@rayscan.com', '+1234567891', 'Psychologist', 'PhD Psychology', 12, 4.7, 60.00, 'Clinical psychologist focused on mental health and behavioral therapy.'),
        ('Dr. Steff Jessi', 'steff@rayscan.com', '+1234567892', 'Orthopedist', 'MD Orthopedics', 10, 4.7, 60.00, 'Orthopedic surgeon specializing in bone and joint disorders.')
      `);
      console.log('✅ Sample doctors inserted');
    }

    // Create indexes
    await pool.query('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)');
    console.log('✅ Indexes created');

    console.log('🎉 Database setup completed successfully!');

  } catch (error) {
    console.error('❌ Database setup failed:', error.message);
  } finally {
    await pool.end();
  }
}

createTables();