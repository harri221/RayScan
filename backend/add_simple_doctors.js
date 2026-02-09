const { Pool } = require('pg');
require('dotenv').config();

async function addSimpleDoctors() {
  const pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 5432,
  });

  try {
    console.log('🔄 Adding doctor data to existing schema...');

    // First create users for doctors
    const doctorUsers = [
      {
        full_name: 'Dr. Marcus Horizon',
        email: 'marcus.horizon@rayscan.com',
        phone: '+1-555-0101',
        password_hash: '$2a$10$rayscandefaultpass123456789012345678901234567890123456',
        role: 'doctor',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MH'
      },
      {
        full_name: 'Dr. Maria Elena Rodriguez',
        email: 'maria.elena@rayscan.com',
        phone: '+1-555-0102',
        password_hash: '$2a$10$rayscandefaultpass123456789012345678901234567890123456',
        role: 'doctor',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=ME'
      },
      {
        full_name: 'Dr. Steff Jessica Williams',
        email: 'steff.williams@rayscan.com',
        phone: '+1-555-0103',
        password_hash: '$2a$10$rayscandefaultpass123456789012345678901234567890123456',
        role: 'doctor',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SW'
      },
      {
        full_name: 'Dr. Sarah Lee Chen',
        email: 'sarah.chen@rayscan.com',
        phone: '+1-555-0104',
        password_hash: '$2a$10$rayscandefaultpass123456789012345678901234567890123456',
        role: 'doctor',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SC'
      },
      {
        full_name: 'Dr. Michael Brown',
        email: 'michael.brown@rayscan.com',
        phone: '+1-555-0105',
        password_hash: '$2a$10$rayscandefaultpass123456789012345678901234567890123456',
        role: 'doctor',
        profile_image: 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MB'
      }
    ];

    // Insert users first
    console.log('Adding doctor users...');
    const userIds = [];
    for (const user of doctorUsers) {
      const result = await pool.query(
        `INSERT INTO users (full_name, email, phone, password_hash, role, profile_image, is_active, is_verified)
         VALUES ($1, $2, $3, $4, $5, $6, true, true)
         RETURNING id`,
        [user.full_name, user.email, user.phone, user.password_hash, user.role, user.profile_image]
      );
      userIds.push({ id: result.rows[0].id, email: user.email });
    }
    console.log(`✅ Added ${userIds.length} doctor users`);

    // Now add doctor profiles
    const doctorProfiles = [
      {
        email: 'marcus.horizon@rayscan.com',
        pmdc_number: 'PMDC-001-2024',
        specialization: 'Cardiologist',
        qualification: 'MD, FACC - Harvard Medical School',
        experience_years: 15,
        consultation_fee: 120.00,
        clinic_address: '123 Heart Center, Medical District',
        clinic_phone: '+1-555-0201',
        bio: 'Dr. Marcus Horizon is a board-certified cardiologist with over 15 years of experience in treating heart diseases.',
        rating: 4.8,
        total_reviews: 245,
        is_pmdc_verified: true,
        availability_status: 'available'
      },
      {
        email: 'maria.elena@rayscan.com',
        pmdc_number: 'PMDC-002-2024',
        specialization: 'Psychologist',
        qualification: 'PhD Psychology - Stanford University',
        experience_years: 12,
        consultation_fee: 90.00,
        clinic_address: '456 Mind Care Center, Downtown',
        clinic_phone: '+1-555-0202',
        bio: 'Dr. Maria Elena Rodriguez is a clinical psychologist specializing in cognitive behavioral therapy.',
        rating: 4.7,
        total_reviews: 189,
        is_pmdc_verified: true,
        availability_status: 'available'
      },
      {
        email: 'steff.williams@rayscan.com',
        pmdc_number: 'PMDC-003-2024',
        specialization: 'Orthopedist',
        qualification: 'MD Orthopedics - Johns Hopkins',
        experience_years: 10,
        consultation_fee: 110.00,
        clinic_address: '789 Bone & Joint Clinic, Uptown',
        clinic_phone: '+1-555-0203',
        bio: 'Dr. Steff Williams is an orthopedic surgeon specializing in sports medicine and joint replacement.',
        rating: 4.6,
        total_reviews: 156,
        is_pmdc_verified: true,
        availability_status: 'available'
      },
      {
        email: 'sarah.chen@rayscan.com',
        pmdc_number: 'PMDC-004-2024',
        specialization: 'Urologist',
        qualification: 'MD Urology - UCLA Medical Center',
        experience_years: 15,
        consultation_fee: 130.00,
        clinic_address: '321 Kidney Care Specialists, Medical Plaza',
        clinic_phone: '+1-555-0204',
        bio: 'Dr. Sarah Chen is a renowned urologist with expertise in kidney stone treatment and minimally invasive procedures.',
        rating: 4.9,
        total_reviews: 298,
        is_pmdc_verified: true,
        availability_status: 'available'
      },
      {
        email: 'michael.brown@rayscan.com',
        pmdc_number: 'PMDC-005-2024',
        specialization: 'Neurologist',
        qualification: 'MD Neurology - Cleveland Clinic',
        experience_years: 13,
        consultation_fee: 140.00,
        clinic_address: '654 Neuro Center, Hospital District',
        clinic_phone: '+1-555-0205',
        bio: 'Dr. Michael Brown is a neurologist specializing in epilepsy, stroke treatment, and movement disorders.',
        rating: 4.7,
        total_reviews: 176,
        is_pmdc_verified: true,
        availability_status: 'busy'
      }
    ];

    console.log('Adding doctor profiles...');
    for (const profile of doctorProfiles) {
      const user = userIds.find(u => u.email === profile.email);
      if (user) {
        await pool.query(
          `INSERT INTO doctors
           (user_id, pmdc_number, specialization, qualification, experience_years, consultation_fee,
            clinic_address, clinic_phone, bio, rating, total_reviews, is_pmdc_verified, availability_status,
            full_name, profile_image_url)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13,
                   (SELECT full_name FROM users WHERE id = $1),
                   (SELECT profile_image FROM users WHERE id = $1))`,
          [
            user.id, profile.pmdc_number, profile.specialization, profile.qualification,
            profile.experience_years, profile.consultation_fee, profile.clinic_address,
            profile.clinic_phone, profile.bio, profile.rating, profile.total_reviews,
            profile.is_pmdc_verified, profile.availability_status
          ]
        );
      }
    }

    console.log(`✅ Added ${doctorProfiles.length} doctor profiles`);

    await pool.end();
    console.log('🎉 Doctor data added successfully!');

  } catch (error) {
    console.error('❌ Error adding doctor data:', error);
    await pool.end();
    process.exit(1);
  }
}

addSimpleDoctors();