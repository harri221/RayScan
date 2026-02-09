const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function checkAvailabilityConstraint() {
  try {
    console.log('🔍 Checking doctor_availability table constraints...');

    // Get constraint details
    const constraints = await db.query(`
      SELECT
        conname,
        consrc
      FROM pg_constraint
      WHERE conrelid = 'doctor_availability'::regclass
      AND contype = 'c'
    `);

    console.log('📋 Check constraints:');
    constraints.rows.forEach(row => {
      console.log(`  - ${row.conname}: ${row.consrc}`);
    });

    // Get column details
    const columns = await db.query(`
      SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'doctor_availability'
      ORDER BY ordinal_position
    `);

    console.log('\n📊 Column details:');
    columns.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable}, default: ${row.column_default})`);
    });

  } catch (error) {
    console.error('❌ Error checking constraints:', error);
  } finally {
    await db.end();
  }
}

checkAvailabilityConstraint();