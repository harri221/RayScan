-- RayScan Database - REAL DATA for Neon
-- Copy ALL of this and paste in Neon SQL Editor

-- Drop existing tables
DROP TABLE IF EXISTS call_logs CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS admin_logs CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS consultations CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS doctor_availability CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS ai_diagnoses CASCADE;
DROP TABLE IF EXISTS scans CASCADE;
DROP TABLE IF EXISTS ultrasound_reports CASCADE;
DROP TABLE IF EXISTS pharmacy_products CASCADE;
DROP TABLE IF EXISTS pharmacies CASCADE;
DROP TABLE IF EXISTS password_reset_tokens CASCADE;
DROP TABLE IF EXISTS user_health_metrics CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    full_name VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Pakistan',
    role VARCHAR(20) NOT NULL DEFAULT 'patient',
    profile_image VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create doctors table
CREATE TABLE doctors (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pmdc_number VARCHAR(50) NOT NULL,
    specialization VARCHAR(255) NOT NULL,
    qualification VARCHAR(500),
    experience_years INTEGER DEFAULT 0,
    consultation_fee NUMERIC(10,2) DEFAULT 0.00,
    clinic_address TEXT,
    clinic_phone VARCHAR(20),
    bio TEXT,
    rating NUMERIC(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    is_pmdc_verified BOOLEAN DEFAULT false,
    availability_status VARCHAR(20) DEFAULT 'offline',
    full_name VARCHAR(100),
    profile_image_url VARCHAR(255)
);

-- Create patients table
CREATE TABLE patients (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emergency_contact VARCHAR(20),
    blood_group VARCHAR(5),
    medical_history TEXT,
    allergies TEXT,
    current_medications TEXT,
    insurance_provider VARCHAR(255),
    insurance_number VARCHAR(100)
);

-- Create doctor_availability table
CREATE TABLE doctor_availability (
    id SERIAL PRIMARY KEY,
    doctor_id INTEGER NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    day_of_week VARCHAR(10) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- Create appointments table
CREATE TABLE appointments (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    appointment_type VARCHAR(20) DEFAULT 'consultation',
    consultation_mode VARCHAR(20) DEFAULT 'video_call',
    status VARCHAR(20) DEFAULT 'scheduled',
    reason_for_visit TEXT,
    consultation_fee NUMERIC(10,2),
    payment_status VARCHAR(20) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create conversations table
CREATE TABLE conversations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    type VARCHAR(20) DEFAULT 'consultation',
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    doctor_user_id INTEGER
);

-- Create messages table
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    sender_type VARCHAR(10) NOT NULL,
    message_type VARCHAR(10) DEFAULT 'text',
    content TEXT,
    file_url VARCHAR(255),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create call_logs table
CREATE TABLE call_logs (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER,
    caller_user_id INTEGER NOT NULL,
    receiver_user_id INTEGER NOT NULL,
    call_type VARCHAR(10) NOT NULL,
    status VARCHAR(20) DEFAULT 'initiated',
    channel_name VARCHAR(255),
    duration INTEGER DEFAULT 0,
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create scans table
CREATE TABLE scans (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    scan_type VARCHAR(20) NOT NULL,
    image_path VARCHAR(500) NOT NULL,
    original_filename VARCHAR(255),
    file_size INTEGER,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scan_status VARCHAR(20) DEFAULT 'uploaded',
    ai_confidence_score NUMERIC(5,4),
    processing_time_seconds INTEGER
);

-- Create ai_diagnoses table
CREATE TABLE ai_diagnoses (
    id SERIAL PRIMARY KEY,
    scan_id INTEGER NOT NULL,
    diagnosis_result VARCHAR(20) NOT NULL,
    condition_detected VARCHAR(255),
    confidence_percentage NUMERIC(5,2),
    ai_model_version VARCHAR(50),
    detection_details JSONB,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create reports table
CREATE TABLE reports (
    id SERIAL PRIMARY KEY,
    scan_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER,
    report_type VARCHAR(20) DEFAULT 'ai_generated',
    diagnosis TEXT NOT NULL,
    recommendations TEXT,
    severity_level VARCHAR(20),
    report_pdf_path VARCHAR(500),
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create ultrasound_reports table
CREATE TABLE ultrasound_reports (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    scan_type VARCHAR(20) NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    ai_analysis TEXT,
    result VARCHAR(20),
    confidence_score NUMERIC(3,2),
    recommended_doctor_id INTEGER,
    status VARCHAR(20) DEFAULT 'processing',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create pharmacies table
CREATE TABLE pharmacies (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    pharmacy_name VARCHAR(255) NOT NULL,
    license_number VARCHAR(100) NOT NULL,
    owner_name VARCHAR(255),
    pharmacy_address TEXT NOT NULL,
    pharmacy_phone VARCHAR(20),
    operating_hours VARCHAR(255),
    delivery_available BOOLEAN DEFAULT false,
    latitude NUMERIC(10,8),
    longitude NUMERIC(11,8)
);

-- Create pharmacy_products table
CREATE TABLE pharmacy_products (
    id SERIAL PRIMARY KEY,
    pharmacy_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price NUMERIC(10,2),
    in_stock BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create payments table
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    appointment_id INTEGER,
    amount NUMERIC(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255),
    payment_status VARCHAR(20) DEFAULT 'pending',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    refund_amount NUMERIC(10,2),
    refund_date TIMESTAMP
);

-- Create consultations table
CREATE TABLE consultations (
    id SERIAL PRIMARY KEY,
    appointment_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    consultation_notes TEXT,
    prescription TEXT,
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    consultation_rating INTEGER,
    started_at TIMESTAMP,
    ended_at TIMESTAMP
);

-- Create notifications table
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create reviews table
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    appointment_id INTEGER,
    rating INTEGER NOT NULL,
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create admin_logs table
CREATE TABLE admin_logs (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL,
    action VARCHAR(100) NOT NULL,
    target_table VARCHAR(50),
    target_id INTEGER,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create password_reset_tokens table
CREATE TABLE password_reset_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    token VARCHAR(6) NOT NULL,
    contact_info VARCHAR(100) NOT NULL,
    contact_type VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create user_health_metrics table
CREATE TABLE user_health_metrics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    heart_rate INTEGER,
    calories_burned INTEGER,
    weight NUMERIC(5,2),
    height NUMERIC(5,2),
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- INSERT REAL USER DATA WITH REAL PASSWORD HASHES
-- =============================================

INSERT INTO users (id, email, password_hash, phone, full_name, gender, city, country, role, profile_image, is_active, is_verified) VALUES
(1, 'admin@rayscan.com', '$2b$12$hash_placeholder', NULL, 'System Admin', NULL, NULL, 'Pakistan', 'admin', NULL, true, true),
(4, 'test@test.com', '$2a$10$leVdxX05qVmYJ8cre9Y.OWzsCiI9msspzv3wbIHSFh5HBZSK1u', NULL, 'Test User', NULL, NULL, 'Pakistan', 'patient', NULL, true, false),
(5, 'ali@gmail.com', '$2a$10$1oPGIdfSOO8Sj6YPuM6gDOqfCtSYho9C4khkJMHRuvqkqcE5eWbze', NULL, 'ali', NULL, NULL, 'Pakistan', 'patient', NULL, true, false),
(6, 'marcus.horizon@rayscan.com', '$2a$10$rayscandefaultpass123456789012345678901234567890123456', '+1-555-0101', 'Dr. Marcus Horizon', NULL, NULL, 'Pakistan', 'doctor', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MH', true, true),
(7, 'maria.elena@rayscan.com', '$2a$10$rayscandefaultpass123456789012345678901234567890123456', '+1-555-0102', 'Dr. Maria Elena Rodriguez', NULL, NULL, 'Pakistan', 'doctor', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=ME', true, true),
(8, 'steff.williams@rayscan.com', '$2a$10$rayscandefaultpass123456789012345678901234567890123456', '+1-555-0103', 'Dr. Steff Jessica Williams', NULL, NULL, 'Pakistan', 'doctor', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SW', true, true),
(9, 'sarah.chen@rayscan.com', '$2a$10$rayscandefaultpass123456789012345678901234567890123456', '+1-555-0104', 'Dr. Sarah Lee Chen', NULL, NULL, 'Pakistan', 'doctor', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SC', true, true),
(10, 'michael.brown@rayscan.com', '$2a$10$rayscandefaultpass123456789012345678901234567890123456', '+1-555-0105', 'Dr. Michael Brown', NULL, NULL, 'Pakistan', 'doctor', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MB', true, true),
(16, 'hariscutie@gmail.com', '$2a$10$WbyoqRXoOwYMZoT4EvP98uY9V4k92uXXWIfAexUlGfnt5kCLi2.O', NULL, 'Haris', NULL, NULL, 'Pakistan', 'patient', NULL, true, false),
(17, 'mushi123@gmail.com', '$2a$10$RBAdtlTxkdeekBovuddPhO2nTUUQqmI0h6AG5Uk6son43.Cl88unW', '03345010416', 'Mus', 'Male', NULL, 'Pakistan', 'doctor', NULL, true, false),
(18, 'itrat@gmail.com', '$2a$10$7aJArzXdYzDCuO.hd2Y1x.CyaKFuKkKR3hNDRsCpAXuQ2lxdT6h6', NULL, 'itrat', NULL, NULL, 'Pakistan', 'patient', NULL, true, false),
(19, 'mushi002@gmail.com', '$2a$10$9ONWjQpvBpsP6vGmvowaeAytR5Mop.6ppDADWdpA5E0ts.WOM4a', '3345010416', 'Mushi', 'Male', NULL, 'Pakistan', 'doctor', NULL, true, false),
(20, 'coolguy123@gmail.com', '$2a$10$oaJTdbnCuB5ibYJ2wBHsk.jLYkCvwo7UT1ly3f6H2U6bj7AM5tiq', NULL, 'coolguy', NULL, NULL, 'Pakistan', 'patient', NULL, true, false),
(21, 'mu@gmail.com', '$2a$10$WfutrDEnguKfmXfR9RlsOOHXX3r7DzRm6SWyY3R7xDpFns.WKr7eq', NULL, 'Mushi', NULL, NULL, 'Pakistan', 'patient', NULL, true, false),
(22, 'harisa@gmail.com', '$2a$10$Omi9.5OexSw6h7bAKnwlPO6Z9h2xXR7i4hSa1gWc06xP6fKCy78.', 'qs2', 'haris', 'Male', NULL, 'Pakistan', 'doctor', NULL, true, false),
(23, 'bro@gmail.com', '$2a$10$nY5YQkoKUwiebz2ByUmnD.YhOPiLdP5Pu7aUSI5yOiSV4Hy0onsq', NULL, 'Bro', NULL, NULL, 'Pakistan', 'patient', NULL, true, false);

-- Reset sequence
SELECT setval('users_id_seq', 25);

-- Insert Doctors
INSERT INTO doctors (id, user_id, pmdc_number, specialization, qualification, experience_years, consultation_fee, clinic_address, clinic_phone, bio, rating, total_reviews, is_pmdc_verified, availability_status, full_name, profile_image_url) VALUES
(2, 6, 'PMDC-001-2024', 'Cardiologist', 'MD, FACC - Harvard Medical School', 15, 120.00, '123 Heart Center, Medical District', '+1-555-0201', 'Dr. Marcus Horizon is a board-certified cardiologist with over 15 years of experience.', 4.80, 245, true, 'available', 'Dr. Marcus Horizon', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MH'),
(3, 7, 'PMDC-002-2024', 'Psychologist', 'PhD Psychology - Stanford University', 12, 90.00, '456 Mind Care Center, Downtown', '+1-555-0202', 'Dr. Maria Elena Rodriguez is a clinical psychologist specializing in cognitive behavioral therapy.', 4.70, 189, true, 'available', 'Dr. Maria Elena Rodriguez', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=ME'),
(4, 8, 'PMDC-003-2024', 'Orthopedist', 'MD Orthopedics - Johns Hopkins', 10, 110.00, '789 Bone & Joint Clinic, Uptown', '+1-555-0203', 'Dr. Steff Williams is an orthopedic surgeon specializing in sports medicine.', 4.60, 156, true, 'available', 'Dr. Steff Jessica Williams', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SW'),
(5, 9, 'PMDC-004-2024', 'Urologist', 'MD Urology - UCLA Medical Center', 15, 130.00, '321 Kidney Care Specialists', '+1-555-0204', 'Dr. Sarah Chen is a renowned urologist with expertise in kidney stone treatment.', 4.90, 298, true, 'available', 'Dr. Sarah Lee Chen', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SC'),
(6, 10, 'PMDC-005-2024', 'Neurologist', 'MD Neurology - Cleveland Clinic', 13, 140.00, '654 Neuro Center', '+1-555-0205', 'Dr. Michael Brown is a neurologist specializing in epilepsy and stroke treatment.', 4.70, 176, true, 'busy', 'Dr. Michael Brown', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MB'),
(8, 17, '123456', 'Surgeon', 'Mbbs', 0, 0.00, NULL, NULL, NULL, 0.00, 0, false, 'offline', 'Mus', NULL),
(9, 19, '1234567', 'Orthopedist', NULL, 0, 0.00, NULL, NULL, NULL, 0.00, 0, false, 'offline', 'Mushi', NULL),
(10, 22, '333442215', 'Orthopedist', '2q33', 0, 0.00, NULL, NULL, NULL, 0.00, 0, false, 'offline', 'haris', NULL);

-- Reset sequence
SELECT setval('doctors_id_seq', 15);

-- Insert Doctor Availability
INSERT INTO doctor_availability (doctor_id, day_of_week, start_time, end_time, is_active) VALUES
(2, 'Monday', '09:00:00', '12:00:00', true),
(2, 'Monday', '14:00:00', '17:00:00', true),
(2, 'Tuesday', '09:00:00', '12:00:00', true),
(2, 'Tuesday', '14:00:00', '17:00:00', true),
(2, 'Wednesday', '09:00:00', '12:00:00', true),
(3, 'Monday', '08:00:00', '13:00:00', true),
(3, 'Tuesday', '08:00:00', '13:00:00', true),
(4, 'Monday', '13:00:00', '18:00:00', true),
(4, 'Tuesday', '13:00:00', '18:00:00', true),
(5, 'Monday', '09:00:00', '12:00:00', true),
(5, 'Tuesday', '09:00:00', '12:00:00', true),
(6, 'Monday', '08:00:00', '13:00:00', true),
(6, 'Tuesday', '08:00:00', '13:00:00', true),
(10, 'Monday', '00:00:00', '14:10:00', true),
(10, 'Thursday', '17:00:00', '18:30:00', true);

-- Insert conversations
INSERT INTO conversations (id, user_id, doctor_id, type, status, doctor_user_id) VALUES
(3, 21, 10, 'consultation', 'active', 22);

SELECT setval('conversations_id_seq', 5);

-- DONE! Now restart Replit and login with your real credentials
