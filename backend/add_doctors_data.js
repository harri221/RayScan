const { Pool } = require('pg');
require('dotenv').config();

async function addDoctorsData() {
  const pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 5432,
  });

  try {
    console.log('🔄 Adding comprehensive doctor data...');

    // Clear existing doctors (optional - remove if you want to keep existing ones)
    await pool.query('DELETE FROM doctors');
    console.log('✅ Cleared existing doctors');

    // First, we need to add users for the doctors
    const usersData = [
      {
        full_name: 'Dr. Marcus Horizon',
        email: 'marcus.horizon@rayscan.com',
        phone: '+1-555-0101',
        password_hash: '$2a$10$defaulthashedpassword123456789', // Default hashed password
        role: 'doctor',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MH'
      },
      {
        name: 'Dr. Maria Elena Rodriguez',
        email: 'maria.elena@rayscan.com',
        phone: '+1-555-0102',
        specialty: 'Psychologist',
        qualification: 'PhD Psychology - Stanford University',
        experience_years: 12,
        rating: 4.7,
        consultation_fee: 90.00,
        about: 'Dr. Maria Elena Rodriguez is a clinical psychologist specializing in cognitive behavioral therapy, anxiety disorders, and trauma treatment. She has extensive experience in both individual and group therapy.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=ME',
        is_available: true
      },
      {
        name: 'Dr. Steff Jessica Williams',
        email: 'steff.williams@rayscan.com',
        phone: '+1-555-0103',
        specialty: 'Orthopedist',
        qualification: 'MD Orthopedics - Johns Hopkins',
        experience_years: 10,
        rating: 4.6,
        consultation_fee: 110.00,
        about: 'Dr. Steff Williams is an orthopedic surgeon specializing in sports medicine, joint replacement, and arthroscopic procedures. She has treated numerous professional athletes.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SW',
        is_available: true
      },
      {
        name: 'Dr. Gerty Cori Thompson',
        email: 'gerty.thompson@rayscan.com',
        phone: '+1-555-0104',
        specialty: 'Orthopedist',
        qualification: 'MD Orthopedics - Mayo Clinic',
        experience_years: 8,
        rating: 4.5,
        consultation_fee: 105.00,
        about: 'Dr. Gerty Thompson specializes in pediatric orthopedics and spinal surgery. She is known for her compassionate approach to treating young patients with musculoskeletal disorders.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=GT',
        is_available: true
      },
      {
        name: 'Dr. Sarah Lee Chen',
        email: 'sarah.chen@rayscan.com',
        phone: '+1-555-0105',
        specialty: 'Urologist',
        qualification: 'MD Urology - UCLA Medical Center',
        experience_years: 15,
        rating: 4.9,
        consultation_fee: 130.00,
        about: 'Dr. Sarah Chen is a renowned urologist with expertise in kidney stone treatment, prostate disorders, and minimally invasive urological procedures. She has published numerous research papers.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SC',
        is_available: true
      },
      {
        name: 'Dr. David Miller',
        email: 'david.miller@rayscan.com',
        phone: '+1-555-0106',
        specialty: 'Dermatologist',
        qualification: 'MD Dermatology - Northwestern University',
        experience_years: 9,
        rating: 4.4,
        consultation_fee: 95.00,
        about: 'Dr. David Miller is a dermatologist specializing in skin cancer detection, cosmetic dermatology, and treatment of chronic skin conditions like eczema and psoriasis.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=DM',
        is_available: true
      },
      {
        name: 'Dr. Jennifer Adams',
        email: 'jennifer.adams@rayscan.com',
        phone: '+1-555-0107',
        specialty: 'Pediatrician',
        qualification: 'MD Pediatrics - Children\'s Hospital of Philadelphia',
        experience_years: 11,
        rating: 4.8,
        consultation_fee: 85.00,
        about: 'Dr. Jennifer Adams is a board-certified pediatrician with a special interest in developmental pediatrics and childhood nutrition. She is beloved by both children and parents.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=JA',
        is_available: true
      },
      {
        name: 'Dr. Michael Brown',
        email: 'michael.brown@rayscan.com',
        phone: '+1-555-0108',
        specialty: 'Neurologist',
        qualification: 'MD Neurology - Cleveland Clinic',
        experience_years: 13,
        rating: 4.7,
        consultation_fee: 140.00,
        about: 'Dr. Michael Brown is a neurologist specializing in epilepsy, stroke treatment, and movement disorders. He leads the neurology department at his current hospital.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MB',
        is_available: true
      },
      {
        name: 'Dr. Lisa Wang',
        email: 'lisa.wang@rayscan.com',
        phone: '+1-555-0109',
        specialty: 'Ophthalmologist',
        qualification: 'MD Ophthalmology - Bascom Palmer Eye Institute',
        experience_years: 7,
        rating: 4.6,
        consultation_fee: 100.00,
        about: 'Dr. Lisa Wang is an ophthalmologist specializing in retinal diseases, cataract surgery, and LASIK procedures. She uses the latest technology for precise diagnoses.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=LW',
        is_available: false
      },
      {
        name: 'Dr. Robert Johnson',
        email: 'robert.johnson@rayscan.com',
        phone: '+1-555-0110',
        specialty: 'Gastroenterologist',
        qualification: 'MD Gastroenterology - Mount Sinai Hospital',
        experience_years: 14,
        rating: 4.5,
        consultation_fee: 115.00,
        about: 'Dr. Robert Johnson is a gastroenterologist with expertise in digestive disorders, colonoscopy procedures, and inflammatory bowel disease treatment.',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=RJ',
        is_available: true
      }
    ];

    for (const doctor of doctorsData) {
      await pool.query(
        `INSERT INTO doctors
         (name, email, phone, specialty, qualification, experience_years, rating, consultation_fee, about, profile_image, is_available)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [
          doctor.name,
          doctor.email,
          doctor.phone,
          doctor.specialty,
          doctor.qualification,
          doctor.experience_years,
          doctor.rating,
          doctor.consultation_fee,
          doctor.about,
          doctor.profile_image,
          doctor.is_available
        ]
      );
    }

    console.log(`✅ Added ${doctorsData.length} doctors to the database`);

    // Also add some availability data for the doctors
    const doctorIds = await pool.query('SELECT id FROM doctors ORDER BY id');

    console.log('🔄 Adding doctor availability schedules...');

    for (const doctor of doctorIds.rows) {
      // Add Monday to Friday availability for most doctors
      const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];

      for (const day of weekdays) {
        await pool.query(
          `INSERT INTO doctor_availability
           (doctor_id, day_of_week, start_time, end_time, is_available)
           VALUES ($1, $2, $3, $4, $5)`,
          [doctor.id, day, '09:00:00', '17:00:00', true]
        );
      }

      // Add Saturday availability for some doctors (every other doctor)
      if (doctor.id % 2 === 0) {
        await pool.query(
          `INSERT INTO doctor_availability
           (doctor_id, day_of_week, start_time, end_time, is_available)
           VALUES ($1, $2, $3, $4, $5)`,
          [doctor.id, 'saturday', '10:00:00', '14:00:00', true]
        );
      }
    }

    console.log('✅ Added doctor availability schedules');

    await pool.end();
    console.log('🎉 Database populated successfully!');

  } catch (error) {
    console.error('❌ Error adding doctor data:', error);
    await pool.end();
    process.exit(1);
  }
}

addDoctorsData();