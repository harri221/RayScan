-- RayScan Database Setup for Neon
-- Copy this ENTIRE file and paste in Neon SQL Editor

-- Drop existing tables if any (clean start)
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
-- INSERT DATA
-- =============================================

-- Insert Users (password for all: 12345678)
INSERT INTO users (id, email, password_hash, phone, full_name, gender, role, is_active, is_verified, created_at) VALUES
(1, 'admin@rayscan.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+923001234567', 'Admin User', 'Male', 'admin', true, true, '2025-09-01 10:00:00'),
(2, 'patient1@test.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+923001234568', 'Ali Ahmed', 'Male', 'patient', true, true, '2025-09-01 10:00:00'),
(3, 'mus@gmail.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+923001234569', 'Musharaf', 'Male', 'patient', true, true, '2025-09-01 10:00:00'),
(6, 'marcus@rayscan.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+1234567890', 'Dr. Marcus Horizon', 'Male', 'doctor', true, true, '2025-09-01 10:00:00'),
(7, 'maria@rayscan.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+1234567891', 'Dr. Maria Elena Rodriguez', 'Female', 'doctor', true, true, '2025-09-01 10:00:00'),
(8, 'steff@rayscan.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+1234567892', 'Dr. Steff Jessica Williams', 'Female', 'doctor', true, true, '2025-09-01 10:00:00'),
(9, 'sarah@rayscan.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+1234567894', 'Dr. Sarah Lee Chen', 'Female', 'doctor', true, true, '2025-09-01 10:00:00'),
(10, 'michael@rayscan.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+1234567895', 'Dr. Michael Brown', 'Male', 'doctor', true, true, '2025-09-01 10:00:00'),
(21, 'test@test.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+923001234570', 'Test Patient', 'Male', 'patient', true, true, '2025-09-01 10:00:00'),
(22, 'haris@test.com', '$2b$10$8K1p/gEfU.lMFQGH.kJ3/.5.q9zV9vL3xBXKXXXXXXXXXXXXXXXXX', '+923001234571', 'Haris Doctor', 'Male', 'doctor', true, true, '2025-09-01 10:00:00');

-- Reset sequence
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));

-- Insert Doctors
INSERT INTO doctors (id, user_id, pmdc_number, specialization, qualification, experience_years, consultation_fee, clinic_address, clinic_phone, bio, rating, total_reviews, is_pmdc_verified, availability_status, full_name, profile_image_url) VALUES
(2, 6, 'PMDC-001-2024', 'Cardiologist', 'MD, FACC - Harvard Medical School', 15, 120.00, '123 Heart Center, Medical District', '+1-555-0201', 'Dr. Marcus Horizon is a board-certified cardiologist with over 15 years of experience in treating heart diseases.', 4.80, 245, true, 'available', 'Dr. Marcus Horizon', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MH'),
(3, 7, 'PMDC-002-2024', 'Psychologist', 'PhD Psychology - Stanford University', 12, 90.00, '456 Mind Care Center, Downtown', '+1-555-0202', 'Dr. Maria Elena Rodriguez is a clinical psychologist specializing in cognitive behavioral therapy.', 4.70, 189, true, 'available', 'Dr. Maria Elena Rodriguez', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=ME'),
(4, 8, 'PMDC-003-2024', 'Orthopedist', 'MD Orthopedics - Johns Hopkins', 10, 110.00, '789 Bone & Joint Clinic, Uptown', '+1-555-0203', 'Dr. Steff Williams is an orthopedic surgeon specializing in sports medicine and joint replacement.', 4.60, 156, true, 'available', 'Dr. Steff Jessica Williams', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SW'),
(5, 9, 'PMDC-004-2024', 'Urologist', 'MD Urology - UCLA Medical Center', 15, 130.00, '321 Kidney Care Specialists, Medical Plaza', '+1-555-0204', 'Dr. Sarah Chen is a renowned urologist with expertise in kidney stone treatment and minimally invasive procedures.', 4.90, 298, true, 'available', 'Dr. Sarah Lee Chen', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SC'),
(6, 10, 'PMDC-005-2024', 'Neurologist', 'MD Neurology - Cleveland Clinic', 13, 140.00, '654 Neuro Center, Hospital District', '+1-555-0205', 'Dr. Michael Brown is a neurologist specializing in epilepsy, stroke treatment, and movement disorders.', 4.70, 176, true, 'busy', 'Dr. Michael Brown', 'https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MB'),
(10, 22, '333442215', 'Orthopedist', '2q33', 0, 0.00, NULL, NULL, NULL, 0.00, 0, false, 'offline', 'haris', NULL);

-- Reset sequence
SELECT setval('doctors_id_seq', (SELECT MAX(id) FROM doctors));

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

-- Insert sample conversation
INSERT INTO conversations (id, user_id, doctor_id, type, status, doctor_user_id) VALUES
(3, 21, 10, 'consultation', 'active', 22);

SELECT setval('conversations_id_seq', (SELECT MAX(id) FROM conversations));

-- Done!
-- After running this, restart Replit server
