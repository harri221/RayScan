const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function studyCompleteSchema() {
  try {
    console.log('=== ALL TABLES IN DATABASE ===');
    const tables = await db.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    tables.rows.forEach(row => {
      console.log(`- ${row.table_name}`);
    });

    console.log('\n=== PATIENTS TABLE SCHEMA ===');
    try {
      const patientsSchema = await db.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'patients'
        ORDER BY ordinal_position
      `);
      patientsSchema.rows.forEach(row => {
        console.log(`${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });

      console.log('\n=== PATIENTS DATA SAMPLE ===');
      const patientsSample = await db.query('SELECT * FROM patients LIMIT 3');
      patientsSample.rows.forEach(patient => {
        console.log(`Patient ID ${patient.id}: User ID ${patient.user_id}`);
      });
    } catch (error) {
      console.log('Patients table error:', error.message);
    }

    console.log('\n=== USERS TABLE SCHEMA ===');
    const usersSchema = await db.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);
    usersSchema.rows.forEach(row => {
      console.log(`${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    console.log('\n=== FOREIGN KEY CONSTRAINTS ===');
    const fkeys = await db.query(`
      SELECT
          tc.table_name,
          kcu.column_name,
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name,
          tc.constraint_name
      FROM
          information_schema.table_constraints AS tc
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name IN ('appointments', 'patients', 'doctors')
      ORDER BY tc.table_name, tc.constraint_name;
    `);
    fkeys.rows.forEach(row => {
      console.log(`${row.table_name}.${row.column_name} -> ${row.foreign_table_name}.${row.foreign_column_name}`);
    });

    console.log('\n=== TEST USER AND PATIENT RELATIONSHIP ===');
    const userInfo = await db.query('SELECT id, full_name, email FROM users WHERE id = 12');
    if (userInfo.rows.length > 0) {
      console.log('User 12:', userInfo.rows[0]);

      const patientInfo = await db.query('SELECT * FROM patients WHERE user_id = 12');
      if (patientInfo.rows.length > 0) {
        console.log('Patient record for user 12:', patientInfo.rows[0]);
      } else {
        console.log('❌ No patient record found for user 12');
        console.log('Creating patient record...');
        try {
          const newPatient = await db.query(
            'INSERT INTO patients (user_id) VALUES ($1) RETURNING id',
            [12]
          );
          console.log('✅ Created patient record with ID:', newPatient.rows[0].id);
        } catch (createError) {
          console.log('Error creating patient:', createError.message);
        }
      }
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await db.end();
  }
}

studyCompleteSchema();