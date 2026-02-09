const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function checkAppointmentTables() {
  try {
    console.log('🔍 Checking appointment tables...');

    // Check if appointments table exists
    const appointmentsTable = await db.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'appointments'
      ORDER BY ordinal_position
    `);

    if (appointmentsTable.rows.length > 0) {
      console.log('📅 Appointments table columns:');
      appointmentsTable.rows.forEach(row => {
        console.log(`  - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });
    } else {
      console.log('❌ Appointments table does not exist');
    }

    // Check if doctor_availability table exists
    const availabilityTable = await db.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'doctor_availability'
      ORDER BY ordinal_position
    `);

    if (availabilityTable.rows.length > 0) {
      console.log('\n🕒 Doctor availability table columns:');
      availabilityTable.rows.forEach(row => {
        console.log(`  - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });
    } else {
      console.log('❌ Doctor availability table does not exist');
    }

    // Check existing data
    const appointmentCount = await db.query('SELECT COUNT(*) FROM appointments');
    const availabilityCount = await db.query('SELECT COUNT(*) FROM doctor_availability');
    const doctorCount = await db.query('SELECT COUNT(*) FROM doctors');

    console.log(`\n📊 Data count:`);
    console.log(`  - Doctors: ${doctorCount.rows[0].count}`);
    console.log(`  - Appointments: ${appointmentCount.rows[0].count}`);
    console.log(`  - Doctor availability slots: ${availabilityCount.rows[0].count}`);

    if (doctorCount.rows[0].count > 0) {
      const sampleDoctors = await db.query('SELECT d.id, d.full_name, d.specialization FROM doctors d LIMIT 3');
      console.log('\n👨‍⚕️ Sample doctors:');
      sampleDoctors.rows.forEach(doctor => {
        console.log(`  - ID: ${doctor.id}, Name: ${doctor.full_name}, Specialty: ${doctor.specialization}`);
      });
    }

  } catch (error) {
    console.error('❌ Error checking appointment tables:', error);
  } finally {
    await db.end();
  }
}

checkAppointmentTables();