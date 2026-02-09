const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function checkSchema() {
  try {
    console.log('=== APPOINTMENTS TABLE SCHEMA ===');
    const result = await db.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'appointments'
      ORDER BY ordinal_position
    `);
    result.rows.forEach(row => {
      console.log(`${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    console.log('\n=== CHECK CONSTRAINTS ===');
    const constraints = await db.query(`
      SELECT conname, pg_get_constraintdef(oid) as definition
      FROM pg_constraint
      WHERE conrelid = 'appointments'::regclass AND contype = 'c'
    `);
    constraints.rows.forEach(row => {
      console.log(`${row.conname}: ${row.definition}`);
    });

    console.log('\n=== SAMPLE DATA ===');
    const sample = await db.query('SELECT * FROM appointments LIMIT 1');
    if (sample.rows.length > 0) {
      console.log('Sample row:', sample.rows[0]);
    } else {
      console.log('No appointments in table');
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await db.end();
  }
}

checkSchema();