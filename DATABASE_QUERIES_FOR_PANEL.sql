-- ============================================================
-- RAYSCAN DATABASE QUERIES FOR FYP PANEL PRESENTATION
-- ============================================================
-- Run these queries in pgAdmin, DBeaver, or psql to demonstrate
-- your database structure and data to the panel
-- ============================================================

-- ============================================================
-- SECTION 1: SHOW ALL TABLES IN DATABASE
-- ============================================================

-- List all tables in the database
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Show table structure with columns
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- ============================================================
-- SECTION 2: USERS TABLE
-- ============================================================

-- Show all users (basic info - hide passwords for security)
SELECT
    id,
    email,
    full_name,
    role,
    phone,
    is_verified,
    created_at
FROM users
ORDER BY created_at DESC;

-- Count users by role
SELECT
    role,
    COUNT(*) as total_users
FROM users
GROUP BY role;

-- Show patients only
SELECT id, email, full_name, phone, created_at
FROM users
WHERE role = 'patient'
ORDER BY created_at DESC;

-- Show doctors only
SELECT id, email, full_name, phone, created_at
FROM users
WHERE role = 'doctor'
ORDER BY created_at DESC;

-- ============================================================
-- SECTION 3: DOCTORS TABLE
-- ============================================================

-- Show all doctors with their details
SELECT
    d.id,
    u.full_name as doctor_name,
    u.email,
    d.specialty,
    d.qualification,
    d.experience_years,
    d.consultation_fee,
    d.rating,
    d.total_reviews,
    d.hospital_name,
    d.is_available
FROM doctors d
JOIN users u ON d.user_id = u.id
ORDER BY d.rating DESC;

-- Show doctors by specialty
SELECT
    specialty,
    COUNT(*) as doctor_count,
    AVG(consultation_fee) as avg_fee,
    AVG(rating) as avg_rating
FROM doctors
GROUP BY specialty
ORDER BY doctor_count DESC;

-- Top rated doctors
SELECT
    u.full_name,
    d.specialty,
    d.rating,
    d.total_reviews,
    d.consultation_fee
FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE d.rating >= 4.0
ORDER BY d.rating DESC
LIMIT 10;

-- ============================================================
-- SECTION 4: APPOINTMENTS TABLE
-- ============================================================

-- Show all appointments with patient and doctor names
SELECT
    a.id,
    p.full_name as patient_name,
    doc_user.full_name as doctor_name,
    d.specialty,
    a.appointment_date,
    a.appointment_time,
    a.status,
    a.reason,
    a.consultation_fee,
    a.payment_status,
    a.created_at
FROM appointments a
JOIN users p ON a.user_id = p.id
JOIN doctors d ON a.doctor_id = d.id
JOIN users doc_user ON d.user_id = doc_user.id
ORDER BY a.appointment_date DESC, a.appointment_time DESC;

-- Appointments by status
SELECT
    status,
    COUNT(*) as total_appointments
FROM appointments
GROUP BY status;

-- Today's appointments
SELECT
    a.id,
    p.full_name as patient,
    doc_user.full_name as doctor,
    a.appointment_time,
    a.status,
    a.reason
FROM appointments a
JOIN users p ON a.user_id = p.id
JOIN doctors d ON a.doctor_id = d.id
JOIN users doc_user ON d.user_id = doc_user.id
WHERE DATE(a.appointment_date) = CURRENT_DATE
ORDER BY a.appointment_time;

-- Upcoming appointments
SELECT
    a.id,
    p.full_name as patient,
    doc_user.full_name as doctor,
    a.appointment_date,
    a.appointment_time,
    a.status
FROM appointments a
JOIN users p ON a.user_id = p.id
JOIN doctors d ON a.doctor_id = d.id
JOIN users doc_user ON d.user_id = doc_user.id
WHERE a.appointment_date >= CURRENT_DATE
  AND a.status IN ('pending', 'confirmed')
ORDER BY a.appointment_date, a.appointment_time;

-- Appointments with feedback/ratings
SELECT
    a.id,
    p.full_name as patient,
    doc_user.full_name as doctor,
    a.feedback_rating,
    a.feedback_comment,
    a.appointment_date
FROM appointments a
JOIN users p ON a.user_id = p.id
JOIN doctors d ON a.doctor_id = d.id
JOIN users doc_user ON d.user_id = doc_user.id
WHERE a.feedback_rating IS NOT NULL
ORDER BY a.feedback_rating DESC;

-- ============================================================
-- SECTION 5: MESSAGES TABLE (Chat System)
-- ============================================================

-- Show recent messages
SELECT
    m.id,
    sender.full_name as sender_name,
    receiver.full_name as receiver_name,
    m.message,
    m.is_read,
    m.created_at
FROM messages m
JOIN users sender ON m.sender_id = sender.id
JOIN users receiver ON m.receiver_id = receiver.id
ORDER BY m.created_at DESC
LIMIT 20;

-- Messages between specific users (conversation)
-- Replace user IDs with actual IDs
SELECT
    m.id,
    sender.full_name as sender,
    m.message,
    m.is_read,
    m.created_at
FROM messages m
JOIN users sender ON m.sender_id = sender.id
WHERE (m.sender_id = 1 AND m.receiver_id = 2)
   OR (m.sender_id = 2 AND m.receiver_id = 1)
ORDER BY m.created_at ASC;

-- Unread messages count per user
SELECT
    u.full_name,
    COUNT(m.id) as unread_messages
FROM users u
LEFT JOIN messages m ON m.receiver_id = u.id AND m.is_read = false
GROUP BY u.id, u.full_name
HAVING COUNT(m.id) > 0;

-- ============================================================
-- SECTION 6: CALLS TABLE (Video/Voice Calls)
-- ============================================================

-- Show all calls
SELECT
    c.id,
    caller.full_name as caller_name,
    receiver.full_name as receiver_name,
    c.call_type,
    c.status,
    c.started_at,
    c.ended_at,
    c.duration_seconds
FROM calls c
JOIN users caller ON c.caller_id = caller.id
JOIN users receiver ON c.receiver_id = receiver.id
ORDER BY c.started_at DESC;

-- Call statistics
SELECT
    call_type,
    status,
    COUNT(*) as total_calls,
    AVG(duration_seconds) as avg_duration_seconds
FROM calls
GROUP BY call_type, status;

-- ============================================================
-- SECTION 7: DOCTOR AVAILABILITY
-- ============================================================

-- Show doctor schedules
SELECT
    u.full_name as doctor_name,
    da.day_of_week,
    da.start_time,
    da.end_time,
    da.is_available
FROM doctor_availability da
JOIN doctors d ON da.doctor_id = d.id
JOIN users u ON d.user_id = u.id
ORDER BY u.full_name,
    CASE da.day_of_week
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;

-- Available doctors today
SELECT
    u.full_name,
    d.specialty,
    da.start_time,
    da.end_time
FROM doctor_availability da
JOIN doctors d ON da.doctor_id = d.id
JOIN users u ON d.user_id = u.id
WHERE da.day_of_week = TO_CHAR(CURRENT_DATE, 'FMDay')
  AND da.is_available = true
  AND d.is_available = true;

-- ============================================================
-- SECTION 8: REPORTS TABLE (AI Diagnosis Results)
-- ============================================================

-- Show all AI diagnosis reports
SELECT
    r.id,
    u.full_name as patient_name,
    r.diagnosis_result,
    r.confidence_score,
    r.image_path,
    r.created_at
FROM reports r
JOIN users u ON r.user_id = u.id
ORDER BY r.created_at DESC;

-- Diagnosis statistics
SELECT
    diagnosis_result,
    COUNT(*) as total_cases,
    AVG(confidence_score) as avg_confidence
FROM reports
GROUP BY diagnosis_result;

-- High confidence detections
SELECT
    u.full_name,
    r.diagnosis_result,
    r.confidence_score,
    r.created_at
FROM reports r
JOIN users u ON r.user_id = u.id
WHERE r.confidence_score >= 0.95
ORDER BY r.confidence_score DESC;

-- ============================================================
-- SECTION 9: STATISTICS & ANALYTICS
-- ============================================================

-- Overall system statistics
SELECT
    (SELECT COUNT(*) FROM users WHERE role = 'patient') as total_patients,
    (SELECT COUNT(*) FROM users WHERE role = 'doctor') as total_doctors,
    (SELECT COUNT(*) FROM appointments) as total_appointments,
    (SELECT COUNT(*) FROM appointments WHERE status = 'completed') as completed_appointments,
    (SELECT COUNT(*) FROM messages) as total_messages,
    (SELECT COUNT(*) FROM calls) as total_calls,
    (SELECT COUNT(*) FROM reports) as total_ai_diagnoses;

-- Monthly appointment trends
SELECT
    TO_CHAR(appointment_date, 'YYYY-MM') as month,
    COUNT(*) as total_appointments,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled
FROM appointments
GROUP BY TO_CHAR(appointment_date, 'YYYY-MM')
ORDER BY month DESC;

-- Doctor performance (ratings and appointments)
SELECT
    u.full_name as doctor_name,
    d.specialty,
    d.rating,
    d.total_reviews,
    COUNT(a.id) as total_appointments,
    COUNT(CASE WHEN a.status = 'completed' THEN 1 END) as completed_appointments
FROM doctors d
JOIN users u ON d.user_id = u.id
LEFT JOIN appointments a ON a.doctor_id = d.id
GROUP BY d.id, u.full_name, d.specialty, d.rating, d.total_reviews
ORDER BY d.rating DESC;

-- Revenue statistics (if tracking payments)
SELECT
    TO_CHAR(appointment_date, 'YYYY-MM') as month,
    SUM(consultation_fee) as total_revenue,
    COUNT(*) as appointments,
    AVG(consultation_fee) as avg_fee
FROM appointments
WHERE status = 'completed' AND payment_status = 'paid'
GROUP BY TO_CHAR(appointment_date, 'YYYY-MM')
ORDER BY month DESC;

-- ============================================================
-- SECTION 10: TABLE STRUCTURE QUERIES
-- ============================================================

-- Users table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Doctors table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'doctors'
ORDER BY ordinal_position;

-- Appointments table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'appointments'
ORDER BY ordinal_position;

-- Messages table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'messages'
ORDER BY ordinal_position;

-- ============================================================
-- SECTION 11: SAMPLE DATA INSERTION (For Demo)
-- ============================================================

-- If you need to insert sample data for demo:

-- Insert sample patient (uncomment to use)
-- INSERT INTO users (email, password_hash, full_name, role, phone)
-- VALUES ('demo.patient@example.com', '$2b$10$hashedpassword', 'Demo Patient', 'patient', '+923001234567');

-- Insert sample doctor (uncomment to use)
-- INSERT INTO users (email, password_hash, full_name, role, phone)
-- VALUES ('demo.doctor@example.com', '$2b$10$hashedpassword', 'Dr. Demo Doctor', 'doctor', '+923007654321');

-- INSERT INTO doctors (user_id, specialty, qualification, experience_years, consultation_fee, hospital_name, is_available)
-- VALUES ((SELECT id FROM users WHERE email = 'demo.doctor@example.com'), 'Urology', 'MBBS, FCPS', 10, 2000, 'City Hospital', true);

-- ============================================================
-- SECTION 12: USEFUL JOINS FOR PRESENTATION
-- ============================================================

-- Complete appointment view with all related data
SELECT
    a.id as appointment_id,
    p.full_name as patient_name,
    p.email as patient_email,
    p.phone as patient_phone,
    doc_user.full_name as doctor_name,
    d.specialty,
    d.qualification,
    d.hospital_name,
    a.appointment_date,
    a.appointment_time,
    a.status,
    a.reason,
    a.consultation_fee,
    a.payment_status,
    a.feedback_rating,
    a.feedback_comment,
    a.created_at
FROM appointments a
JOIN users p ON a.user_id = p.id
JOIN doctors d ON a.doctor_id = d.id
JOIN users doc_user ON d.user_id = doc_user.id
ORDER BY a.created_at DESC;

-- Patient history with all appointments and diagnoses
SELECT
    u.full_name as patient_name,
    'Appointment' as record_type,
    doc_user.full_name as related_to,
    a.status as result,
    a.appointment_date as date
FROM appointments a
JOIN users u ON a.user_id = u.id
JOIN doctors d ON a.doctor_id = d.id
JOIN users doc_user ON d.user_id = doc_user.id

UNION ALL

SELECT
    u.full_name as patient_name,
    'AI Diagnosis' as record_type,
    'AI System' as related_to,
    r.diagnosis_result || ' (' || ROUND(r.confidence_score * 100) || '%)' as result,
    r.created_at as date
FROM reports r
JOIN users u ON r.user_id = u.id

ORDER BY date DESC;

-- ============================================================
-- END OF QUERIES
-- ============================================================
