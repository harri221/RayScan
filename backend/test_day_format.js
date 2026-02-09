const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function testDayFormat() {
  try {
    console.log('🔍 Testing day format for doctor_availability...');

    // Get the first doctor
    const doctors = await db.query('SELECT id FROM doctors LIMIT 1');
    if (doctors.rows.length === 0) {
      console.log('❌ No doctors found');
      return;
    }

    const doctorId = doctors.rows[0].id;
    console.log(`Testing with doctor ID: ${doctorId}`);

    // Try different formats
    const formats = [
      'Monday',
      'MONDAY',
      'monday',
      'Mon',
      'MON',
      'mon',
      '1',
      '0', // Sunday as 0
      '7', // Sunday as 7
      'Sunday',
      'sunday'
    ];

    for (const format of formats) {
      try {
        console.log(`Trying format: '${format}'`);
        await db.query(
          'INSERT INTO doctor_availability (doctor_id, day_of_week, start_time, end_time, is_active) VALUES ($1, $2, $3, $4, $5)',
          [doctorId, format, '09:00', '12:00', true]
        );
        console.log(`✅ SUCCESS: '${format}' works!`);

        // Delete the test record
        await db.query('DELETE FROM doctor_availability WHERE doctor_id = $1 AND day_of_week = $2', [doctorId, format]);
        break; // Stop on first success
      } catch (error) {
        console.log(`❌ FAILED: '${format}' - ${error.message}`);
      }
    }

  } catch (error) {
    console.error('❌ Error testing day format:', error);
  } finally {
    await db.end();
  }
}

testDayFormat();