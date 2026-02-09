const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function addDoctorAvailability() {
  try {
    console.log('🔄 Adding doctor availability data...');

    // Check if availability data already exists
    const existingAvailability = await db.query('SELECT COUNT(*) FROM doctor_availability');

    if (existingAvailability.rows[0].count > 0) {
      console.log('✅ Doctor availability data already exists');
      console.log(`Found ${existingAvailability.rows[0].count} availability slots`);
      return;
    }

    // Get all doctors
    const doctors = await db.query('SELECT id FROM doctors ORDER BY id');

    if (doctors.rows.length === 0) {
      console.log('❌ No doctors found in database');
      return;
    }

    console.log(`📅 Adding availability for ${doctors.rows.length} doctors...`);

    // Define availability patterns (using capitalized day names)
    const availabilityPatterns = [
      // Pattern 1: Monday to Friday, Morning and Evening
      [
        { day: 'Monday', start: '09:00', end: '12:00' },
        { day: 'Monday', start: '14:00', end: '17:00' },
        { day: 'Tuesday', start: '09:00', end: '12:00' },
        { day: 'Tuesday', start: '14:00', end: '17:00' },
        { day: 'Wednesday', start: '09:00', end: '12:00' },
        { day: 'Wednesday', start: '14:00', end: '17:00' },
        { day: 'Thursday', start: '09:00', end: '12:00' },
        { day: 'Thursday', start: '14:00', end: '17:00' },
        { day: 'Friday', start: '09:00', end: '12:00' },
        { day: 'Friday', start: '14:00', end: '17:00' },
      ],
      // Pattern 2: Monday to Saturday, Morning only
      [
        { day: 'Monday', start: '08:00', end: '13:00' },
        { day: 'Tuesday', start: '08:00', end: '13:00' },
        { day: 'Wednesday', start: '08:00', end: '13:00' },
        { day: 'Thursday', start: '08:00', end: '13:00' },
        { day: 'Friday', start: '08:00', end: '13:00' },
        { day: 'Saturday', start: '09:00', end: '12:00' },
      ],
      // Pattern 3: All week except Sunday, Afternoon
      [
        { day: 'Monday', start: '13:00', end: '18:00' },
        { day: 'Tuesday', start: '13:00', end: '18:00' },
        { day: 'Wednesday', start: '13:00', end: '18:00' },
        { day: 'Thursday', start: '13:00', end: '18:00' },
        { day: 'Friday', start: '13:00', end: '18:00' },
        { day: 'Saturday', start: '13:00', end: '16:00' },
      ],
    ];

    // Add availability for each doctor
    for (let i = 0; i < doctors.rows.length; i++) {
      const doctor = doctors.rows[i];
      const patternIndex = i % availabilityPatterns.length;
      const pattern = availabilityPatterns[patternIndex];

      console.log(`  Adding availability for doctor ID ${doctor.id} (pattern ${patternIndex + 1})`);

      for (const slot of pattern) {
        await db.query(
          'INSERT INTO doctor_availability (doctor_id, day_of_week, start_time, end_time, is_active) VALUES ($1, $2, $3, $4, $5)',
          [doctor.id, slot.day, slot.start, slot.end, true]
        );
      }
    }

    // Display summary
    const totalAvailability = await db.query('SELECT COUNT(*) FROM doctor_availability');
    const activeDoctors = await db.query('SELECT COUNT(DISTINCT doctor_id) FROM doctor_availability WHERE is_active = true');

    console.log('\n✅ Doctor availability added successfully!');
    console.log(`📅 Total availability slots: ${totalAvailability.rows[0].count}`);
    console.log(`👨‍⚕️ Doctors with availability: ${activeDoctors.rows[0].count}`);

    // Show sample availability
    const sampleAvailability = await db.query(`
      SELECT d.full_name, da.day_of_week, da.start_time, da.end_time
      FROM doctor_availability da
      JOIN doctors d ON da.doctor_id = d.id
      ORDER BY d.id, da.day_of_week, da.start_time
      LIMIT 10
    `);

    console.log('\n📋 Sample availability:');
    sampleAvailability.rows.forEach(row => {
      console.log(`  - ${row.full_name}: ${row.day_of_week} ${row.start_time} - ${row.end_time}`);
    });

  } catch (error) {
    console.error('❌ Error adding doctor availability:', error);
  } finally {
    await db.end();
  }
}

addDoctorAvailability();