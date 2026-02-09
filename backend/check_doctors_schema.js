const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function checkDoctorsSchema() {
  try {
    console.log('=== DOCTORS TABLE SCHEMA ===');
    const result = await db.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'doctors'
      ORDER BY ordinal_position
    `);
    result.rows.forEach(row => {
      console.log(`${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    console.log('\n=== TESTING DOCTOR 2 ===');
    const doctor = await db.query('SELECT id, full_name, consultation_fee FROM doctors WHERE id = 2');
    if (doctor.rows.length > 0) {
      console.log('Doctor 2:', doctor.rows[0]);
    } else {
      console.log('Doctor 2 not found');
    }

    console.log('\n=== ALL DOCTORS ===');
    const allDoctors = await db.query('SELECT id, full_name FROM doctors LIMIT 5');
    allDoctors.rows.forEach(d => {
      console.log(`ID ${d.id}: ${d.full_name}`);
    });

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await db.end();
  }
}

checkDoctorsSchema();