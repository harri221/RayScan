const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for profile image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/doctors/';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'doctor-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// Doctor Profile Management API routes
module.exports = (db) => {

  // 1. GET DOCTOR'S OWN PROFILE
  router.get('/profile', async (req, res) => {
    try {
      const userId = req.user.id;

      // Get doctor info
      const doctorResult = await db.query(
        `SELECT
          d.id, d.user_id, d.full_name as name, u.email, u.phone,
          d.pmdc_number, d.specialization, d.qualification,
          d.experience_years, d.rating, d.consultation_fee,
          d.bio, d.profile_image_url as profile_image,
          d.clinic_address, d.clinic_phone, d.availability_status,
          u.created_at
        FROM doctors d
        JOIN users u ON d.user_id = u.id
        WHERE d.user_id = $1 AND u.is_active = true`,
        [userId]
      );

      if (doctorResult.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctor = doctorResult.rows[0];

      res.json({
        doctor: {
          id: doctor.id,
          userId: doctor.user_id,
          name: doctor.name,
          email: doctor.email,
          phone: doctor.phone,
          pmdcNumber: doctor.pmdc_number,
          specialization: doctor.specialization,
          qualification: doctor.qualification,
          experienceYears: doctor.experience_years,
          rating: parseFloat(doctor.rating),
          consultationFee: parseFloat(doctor.consultation_fee),
          bio: doctor.bio,
          profileImage: doctor.profile_image,
          clinicAddress: doctor.clinic_address,
          clinicPhone: doctor.clinic_phone,
          availabilityStatus: doctor.availability_status,
          createdAt: doctor.created_at
        }
      });

    } catch (error) {
      console.error('Get doctor profile error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 2. UPDATE DOCTOR PROFILE
  router.put('/profile', async (req, res) => {
    try {
      const userId = req.user.id;
      const {
        bio,
        qualification,
        experienceYears,
        consultationFee,
        clinicAddress,
        clinicPhone,
        specialization
      } = req.body;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Build dynamic update query
      const updates = [];
      const values = [];
      let paramCount = 1;

      if (bio !== undefined) {
        updates.push(`bio = $${paramCount++}`);
        values.push(bio);
      }
      if (qualification !== undefined) {
        updates.push(`qualification = $${paramCount++}`);
        values.push(qualification);
      }
      if (experienceYears !== undefined) {
        updates.push(`experience_years = $${paramCount++}`);
        values.push(experienceYears);
      }
      if (consultationFee !== undefined) {
        updates.push(`consultation_fee = $${paramCount++}`);
        values.push(consultationFee);
      }
      if (clinicAddress !== undefined) {
        updates.push(`clinic_address = $${paramCount++}`);
        values.push(clinicAddress);
      }
      if (clinicPhone !== undefined) {
        updates.push(`clinic_phone = $${paramCount++}`);
        values.push(clinicPhone);
      }
      if (specialization !== undefined) {
        updates.push(`specialization = $${paramCount++}`);
        values.push(specialization);
      }

      if (updates.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }

      updates.push(`updated_at = NOW()`);
      values.push(doctorId);

      const query = `UPDATE doctors SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`;

      const result = await db.query(query, values);
      const updatedDoctor = result.rows[0];

      res.json({
        message: 'Profile updated successfully',
        doctor: {
          id: updatedDoctor.id,
          bio: updatedDoctor.bio,
          qualification: updatedDoctor.qualification,
          experienceYears: updatedDoctor.experience_years,
          consultationFee: parseFloat(updatedDoctor.consultation_fee),
          clinicAddress: updatedDoctor.clinic_address,
          clinicPhone: updatedDoctor.clinic_phone,
          specialization: updatedDoctor.specialization
        }
      });

    } catch (error) {
      console.error('Update doctor profile error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 3. UPLOAD PROFILE IMAGE
  router.post('/profile/image', upload.single('profileImage'), async (req, res) => {
    try {
      const userId = req.user.id;

      if (!req.file) {
        return res.status(400).json({ error: 'No image file uploaded' });
      }

      const imageUrl = `/uploads/doctors/${req.file.filename}`;

      // Get doctor ID and old image
      const doctorCheck = await db.query(
        'SELECT id, profile_image_url FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;
      const oldImage = doctorCheck.rows[0].profile_image_url;

      // Update profile image
      await db.query(
        'UPDATE doctors SET profile_image_url = $1, updated_at = NOW() WHERE id = $2',
        [imageUrl, doctorId]
      );

      // Delete old image file if it exists
      if (oldImage && oldImage.startsWith('/uploads/')) {
        const oldImagePath = path.join(__dirname, '..', oldImage);
        if (fs.existsSync(oldImagePath)) {
          fs.unlinkSync(oldImagePath);
        }
      }

      res.json({
        message: 'Profile image uploaded successfully',
        imageUrl: imageUrl
      });

    } catch (error) {
      console.error('Upload profile image error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 4. GET DOCTOR'S SCHEDULE
  router.get('/schedule', async (req, res) => {
    try {
      const userId = req.user.id;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Get schedule
      const scheduleResult = await db.query(
        `SELECT id, day_of_week, start_time, end_time, is_active
         FROM doctor_availability
         WHERE doctor_id = $1
         ORDER BY
           CASE day_of_week
             WHEN 'Monday' THEN 1
             WHEN 'Tuesday' THEN 2
             WHEN 'Wednesday' THEN 3
             WHEN 'Thursday' THEN 4
             WHEN 'Friday' THEN 5
             WHEN 'Saturday' THEN 6
             WHEN 'Sunday' THEN 7
           END`,
        [doctorId]
      );

      res.json({
        schedule: scheduleResult.rows.map(slot => ({
          id: slot.id,
          dayOfWeek: slot.day_of_week,
          startTime: slot.start_time,
          endTime: slot.end_time,
          isAvailable: slot.is_active
        }))
      });

    } catch (error) {
      console.error('Get schedule error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 5. ADD SCHEDULE TIME SLOT (supports multiple slots per day)
  router.post('/schedule', async (req, res) => {
    try {
      const userId = req.user.id;
      const { dayOfWeek, startTime, endTime, isAvailable } = req.body;

      // Validation
      if (!dayOfWeek || !startTime || !endTime) {
        return res.status(400).json({ error: 'Day of week, start time, and end time are required' });
      }

      const validDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      if (!validDays.includes(dayOfWeek)) {
        return res.status(400).json({ error: 'Invalid day of week' });
      }

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Check for overlapping time slots on the same day
      const overlapCheck = await db.query(
        `SELECT id FROM doctor_availability
         WHERE doctor_id = $1 AND day_of_week = $2
         AND (
           (start_time <= $3 AND end_time > $3) OR
           (start_time < $4 AND end_time >= $4) OR
           (start_time >= $3 AND end_time <= $4)
         )`,
        [doctorId, dayOfWeek, startTime, endTime]
      );

      if (overlapCheck.rows.length > 0) {
        return res.status(400).json({ error: 'Time slot overlaps with existing schedule' });
      }

      // Insert new schedule slot
      const result = await db.query(
        `INSERT INTO doctor_availability (doctor_id, day_of_week, start_time, end_time, is_active)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [doctorId, dayOfWeek, startTime, endTime, isAvailable !== false]
      );

      const schedule = result.rows[0];

      res.json({
        message: 'Schedule slot added successfully',
        schedule: {
          id: schedule.id,
          dayOfWeek: schedule.day_of_week,
          startTime: schedule.start_time,
          endTime: schedule.end_time,
          isAvailable: schedule.is_active
        }
      });

    } catch (error) {
      console.error('Add schedule error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 5b. UPDATE SCHEDULE TIME SLOT BY ID
  router.put('/schedule/:id', async (req, res) => {
    try {
      const userId = req.user.id;
      const { id } = req.params;
      const { startTime, endTime, isAvailable } = req.body;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Verify schedule belongs to doctor
      const scheduleCheck = await db.query(
        'SELECT day_of_week FROM doctor_availability WHERE id = $1 AND doctor_id = $2',
        [id, doctorId]
      );

      if (scheduleCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Schedule not found' });
      }

      const dayOfWeek = scheduleCheck.rows[0].day_of_week;

      // Check for overlaps (excluding current slot)
      if (startTime && endTime) {
        const overlapCheck = await db.query(
          `SELECT id FROM doctor_availability
           WHERE doctor_id = $1 AND day_of_week = $2 AND id != $3
           AND (
             (start_time <= $4 AND end_time > $4) OR
             (start_time < $5 AND end_time >= $5) OR
             (start_time >= $4 AND end_time <= $5)
           )`,
          [doctorId, dayOfWeek, id, startTime, endTime]
        );

        if (overlapCheck.rows.length > 0) {
          return res.status(400).json({ error: 'Time slot overlaps with existing schedule' });
        }
      }

      // Build update query
      const updates = [];
      const values = [];
      let paramCount = 1;

      if (startTime !== undefined) {
        updates.push(`start_time = $${paramCount++}`);
        values.push(startTime);
      }
      if (endTime !== undefined) {
        updates.push(`end_time = $${paramCount++}`);
        values.push(endTime);
      }
      if (isAvailable !== undefined) {
        updates.push(`is_active = $${paramCount++}`);
        values.push(isAvailable);
      }

      values.push(id, doctorId);
      const query = `UPDATE doctor_availability SET ${updates.join(', ')} WHERE id = $${paramCount++} AND doctor_id = $${paramCount} RETURNING *`;

      const result = await db.query(query, values);

      res.json({
        message: 'Schedule updated successfully',
        schedule: {
          id: result.rows[0].id,
          dayOfWeek: result.rows[0].day_of_week,
          startTime: result.rows[0].start_time,
          endTime: result.rows[0].end_time,
          isAvailable: result.rows[0].is_active
        }
      });

    } catch (error) {
      console.error('Update schedule error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 6. DELETE SCHEDULE TIME SLOT BY ID
  router.delete('/schedule/slot/:id', async (req, res) => {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Delete schedule slot
      const result = await db.query(
        'DELETE FROM doctor_availability WHERE id = $1 AND doctor_id = $2 RETURNING *',
        [id, doctorId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Schedule slot not found' });
      }

      res.json({
        message: 'Schedule slot deleted successfully'
      });

    } catch (error) {
      console.error('Delete schedule error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 6b. DELETE ALL SCHEDULES FOR A DAY
  router.delete('/schedule/day/:day', async (req, res) => {
    try {
      const userId = req.user.id;
      const { day } = req.params;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Delete all schedule slots for the day
      const result = await db.query(
        'DELETE FROM doctor_availability WHERE doctor_id = $1 AND day_of_week = $2 RETURNING *',
        [doctorId, day]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'No schedules found for this day' });
      }

      res.json({
        message: `All schedules for ${day} deleted successfully`,
        deletedCount: result.rows.length
      });

    } catch (error) {
      console.error('Delete schedules error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 7. GET DOCTOR'S APPOINTMENTS
  router.get('/appointments', async (req, res) => {
    try {
      const userId = req.user.id;
      const { status, upcoming } = req.query;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Build query
      let query = `
        SELECT
          a.id, a.patient_id, a.doctor_id, a.appointment_date, a.appointment_time,
          a.appointment_type, a.consultation_mode, a.reason_for_visit,
          a.status, a.consultation_fee, a.payment_status, a.notes,
          a.created_at, a.updated_at,
          u.full_name as patient_name, u.email as patient_email, u.phone as patient_phone,
          u.profile_image as patient_image
        FROM appointments a
        JOIN patients p ON a.patient_id = p.id
        JOIN users u ON p.user_id = u.id
        WHERE a.doctor_id = $1
      `;

      const params = [doctorId];
      let paramCount = 2;

      if (status) {
        query += ` AND a.status = $${paramCount++}`;
        params.push(status);
      }

      if (upcoming === 'true') {
        query += ` AND a.appointment_date >= CURRENT_DATE`;
      } else if (upcoming === 'false') {
        query += ` AND a.appointment_date < CURRENT_DATE`;
      }

      query += ' ORDER BY a.appointment_date DESC, a.appointment_time DESC';

      const result = await db.query(query, params);

      res.json({
        appointments: result.rows.map(apt => ({
          id: apt.id,
          patientId: apt.patient_id,
          patientName: apt.patient_name,
          patientEmail: apt.patient_email,
          patientPhone: apt.patient_phone,
          patientImage: apt.patient_image,
          appointmentDate: apt.appointment_date,
          appointmentTime: apt.appointment_time,
          appointmentType: apt.appointment_type,
          consultationMode: apt.consultation_mode,
          reason: apt.reason_for_visit,
          status: apt.status,
          consultationFee: parseFloat(apt.consultation_fee),
          paymentStatus: apt.payment_status,
          notes: apt.notes,
          createdAt: apt.created_at,
          updatedAt: apt.updated_at
        }))
      });

    } catch (error) {
      console.error('Get doctor appointments error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 8. GET APPOINTMENT DETAILS
  router.get('/appointments/:id', async (req, res) => {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Get appointment
      const result = await db.query(
        `SELECT
          a.id, a.patient_id, a.doctor_id, a.appointment_date, a.appointment_time,
          a.appointment_type, a.consultation_mode, a.reason_for_visit,
          a.status, a.consultation_fee, a.payment_status, a.notes,
          a.created_at, a.updated_at,
          u.full_name as patient_name, u.email as patient_email, u.phone as patient_phone,
          u.profile_image as patient_image, u.date_of_birth as patient_dob,
          u.gender as patient_gender, u.address as patient_address
        FROM appointments a
        JOIN patients p ON a.patient_id = p.id
        JOIN users u ON p.user_id = u.id
        WHERE a.id = $1 AND a.doctor_id = $2`,
        [id, doctorId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Appointment not found' });
      }

      const apt = result.rows[0];

      res.json({
        appointment: {
          id: apt.id,
          patientId: apt.patient_id,
          patientName: apt.patient_name,
          patientEmail: apt.patient_email,
          patientPhone: apt.patient_phone,
          patientImage: apt.patient_image,
          patientDateOfBirth: apt.patient_dob,
          patientGender: apt.patient_gender,
          patientAddress: apt.patient_address,
          appointmentDate: apt.appointment_date,
          appointmentTime: apt.appointment_time,
          appointmentType: apt.appointment_type,
          consultationMode: apt.consultation_mode,
          reason: apt.reason_for_visit,
          status: apt.status,
          consultationFee: parseFloat(apt.consultation_fee),
          paymentStatus: apt.payment_status,
          notes: apt.notes,
          createdAt: apt.created_at,
          updatedAt: apt.updated_at
        }
      });

    } catch (error) {
      console.error('Get appointment details error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 9. UPDATE APPOINTMENT STATUS
  router.put('/appointments/:id/status', async (req, res) => {
    try {
      const userId = req.user.id;
      const { id } = req.params;
      const { status, notes } = req.body;

      if (!status) {
        return res.status(400).json({ error: 'Status is required' });
      }

      const validStatuses = ['scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({ error: 'Invalid status value' });
      }

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Verify appointment belongs to this doctor
      const appointmentCheck = await db.query(
        'SELECT id, status FROM appointments WHERE id = $1 AND doctor_id = $2',
        [id, doctorId]
      );

      if (appointmentCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Appointment not found' });
      }

      // Update appointment
      let query = 'UPDATE appointments SET status = $1, updated_at = NOW()';
      const params = [status];
      let paramCount = 2;

      if (notes) {
        query += `, notes = COALESCE(notes || E'\\n\\n', '') || $${paramCount++}`;
        params.push(notes);
      }

      query += ` WHERE id = $${paramCount} RETURNING *`;
      params.push(id);

      const result = await db.query(query, params);

      res.json({
        message: 'Appointment status updated successfully',
        appointment: {
          id: result.rows[0].id,
          status: result.rows[0].status,
          notes: result.rows[0].notes
        }
      });

    } catch (error) {
      console.error('Update appointment status error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 10. CANCEL APPOINTMENT
  router.put('/appointments/:id/cancel', async (req, res) => {
    try {
      const userId = req.user.id;
      const { id } = req.params;
      const { reason } = req.body;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Verify appointment belongs to this doctor
      const appointmentCheck = await db.query(
        'SELECT id, status FROM appointments WHERE id = $1 AND doctor_id = $2',
        [id, doctorId]
      );

      if (appointmentCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Appointment not found' });
      }

      const currentStatus = appointmentCheck.rows[0].status;
      if (currentStatus === 'cancelled') {
        return res.status(400).json({ error: 'Appointment is already cancelled' });
      }

      if (currentStatus === 'completed') {
        return res.status(400).json({ error: 'Cannot cancel completed appointment' });
      }

      // Cancel appointment
      const noteText = reason ? `Cancelled by doctor: ${reason}` : 'Cancelled by doctor';
      await db.query(
        `UPDATE appointments
         SET status = 'cancelled', notes = COALESCE(notes || E'\\n\\n', '') || $1, updated_at = NOW()
         WHERE id = $2`,
        [noteText, id]
      );

      res.json({
        message: 'Appointment cancelled successfully'
      });

    } catch (error) {
      console.error('Cancel appointment error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 11. GET DOCTOR'S PATIENTS (patients who have booked appointments)
  router.get('/patients', async (req, res) => {
    try {
      const userId = req.user.id;

      // Get doctor ID
      const doctorCheck = await db.query(
        'SELECT id FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;

      // Get all unique patients who have booked appointments with this doctor
      const result = await db.query(
        `SELECT DISTINCT
          u.id as patient_id,
          u.full_name as patient_name,
          u.email,
          u.phone,
          u.profile_image_url as profile_image,
          COUNT(DISTINCT a.id) as total_appointments,
          MAX(a.appointment_date) as last_visit
         FROM appointments a
         JOIN users u ON a.patient_id = u.id
         WHERE a.doctor_id = $1 AND a.status IN ('confirmed', 'completed', 'scheduled')
         GROUP BY u.id, u.full_name, u.email, u.phone, u.profile_image_url
         ORDER BY MAX(a.appointment_date) DESC`,
        [doctorId]
      );

      res.json({
        patients: result.rows.map(patient => ({
          id: patient.patient_id,
          name: patient.patient_name,
          email: patient.email,
          phone: patient.phone,
          profileImage: patient.profile_image,
          totalAppointments: parseInt(patient.total_appointments),
          lastVisit: patient.last_visit
        }))
      });

    } catch (error) {
      console.error('Get doctor patients error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 12. GET DOCTOR STATISTICS
  router.get('/stats', async (req, res) => {
    try {
      const userId = req.user.id;

      // Get doctor ID and rating
      const doctorCheck = await db.query(
        'SELECT id, rating FROM doctors WHERE user_id = $1',
        [userId]
      );

      if (doctorCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }

      const doctorId = doctorCheck.rows[0].id;
      const rating = doctorCheck.rows[0].rating;

      // Get today's appointments count
      const todayAppointments = await db.query(
        `SELECT COUNT(*) as count
         FROM appointments
         WHERE doctor_id = $1 AND appointment_date = CURRENT_DATE`,
        [doctorId]
      );

      // Get total patients count (unique patients who booked appointments)
      const totalPatients = await db.query(
        `SELECT COUNT(DISTINCT patient_id) as count
         FROM appointments
         WHERE doctor_id = $1`,
        [doctorId]
      );

      // Get monthly earnings (sum of consultation fees for current month)
      const monthlyEarnings = await db.query(
        `SELECT COALESCE(SUM(consultation_fee), 0) as total
         FROM appointments
         WHERE doctor_id = $1
         AND EXTRACT(MONTH FROM appointment_date) = EXTRACT(MONTH FROM CURRENT_DATE)
         AND EXTRACT(YEAR FROM appointment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
         AND status IN ('completed', 'confirmed', 'in_progress')`,
        [doctorId]
      );

      // Get total appointments (all time)
      const totalAppointments = await db.query(
        `SELECT COUNT(*) as count
         FROM appointments
         WHERE doctor_id = $1`,
        [doctorId]
      );

      res.json({
        stats: {
          todayAppointments: parseInt(todayAppointments.rows[0].count),
          totalPatients: parseInt(totalPatients.rows[0].count),
          monthlyEarnings: parseFloat(monthlyEarnings.rows[0].total),
          totalAppointments: parseInt(totalAppointments.rows[0].count),
          rating: parseFloat(rating) || 0.0,
        }
      });

    } catch (error) {
      console.error('Get doctor stats error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  return router;
};
