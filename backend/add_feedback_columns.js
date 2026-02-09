// Script to add feedback columns to appointments table
// Run this once on your database

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function addFeedbackColumns() {
  try {
    console.log('Adding feedback columns to appointments table...');

    // Add feedback_rating column if not exists
    await pool.query(`
      ALTER TABLE appointments
      ADD COLUMN IF NOT EXISTS feedback_rating INTEGER CHECK (feedback_rating >= 1 AND feedback_rating <= 5)
    `);
    console.log('✅ Added feedback_rating column');

    // Add feedback_comment column if not exists
    await pool.query(`
      ALTER TABLE appointments
      ADD COLUMN IF NOT EXISTS feedback_comment TEXT
    `);
    console.log('✅ Added feedback_comment column');

    // Add feedback_date column if not exists
    await pool.query(`
      ALTER TABLE appointments
      ADD COLUMN IF NOT EXISTS feedback_date TIMESTAMP
    `);
    console.log('✅ Added feedback_date column');

    // Add total_reviews to doctors table if not exists
    await pool.query(`
      ALTER TABLE doctors
      ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0
    `);
    console.log('✅ Added total_reviews column to doctors');

    console.log('\n🎉 All feedback columns added successfully!');

  } catch (error) {
    console.error('Error adding columns:', error);
  } finally {
    await pool.end();
  }
}

addFeedbackColumns();
