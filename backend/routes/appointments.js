const express = require('express');
const router = express.Router();

// Appointment management API routes
module.exports = (db) => {

  // 1. BOOK APPOINTMENT
  router.post('/', async (req, res) => {
    try {
      const {
        doctorId,
        appointmentDate,
        appointmentTime,
        reason,
        consultationFee,
        appointmentType = 'consultation',
        consultationMode = 'video_call'
      } = req.body;

      // Validation
      if (!doctorId || !appointmentDate || !appointmentTime) {
        return res.status(400).json({
          error: 'Doctor ID, appointment date, and time are required'
        });
      }

      // Check if doctor exists and is available
      const doctorResult = await db.query(
        'SELECT d.id, d.consultation_fee FROM doctors d WHERE d.id = $1',
        [doctorId]
      );

      if (doctorResult.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor not found' });
      }

      const doctor = doctorResult.rows[0];

      // Get or create patient record for this user
      let patientResult = await db.query(
        'SELECT id FROM patients WHERE user_id = $1',
        [req.user.id]
      );

      let patientId;
      if (patientResult.rows.length === 0) {
        // Create patient record if it doesn't exist
        const newPatientResult = await db.query(
          'INSERT INTO patients (user_id) VALUES ($1) RETURNING id',
          [req.user.id]
        );
        patientId = newPatientResult.rows[0].id;
      } else {
        patientId = patientResult.rows[0].id;
      }

      // Check if the time slot is already booked
      const existingAppointments = await db.query(
        `SELECT id FROM appointments
         WHERE doctor_id = $1 AND appointment_date = $2 AND appointment_time = $3
         AND status IN ('scheduled', 'confirmed', 'in_progress')`,
        [doctorId, appointmentDate, appointmentTime]
      );

      if (existingAppointments.rows.length > 0) {
        return res.status(400).json({ error: 'This time slot is already booked' });
      }

      // Create appointment
      const fee = consultationFee || doctor.consultation_fee || 0;
      const insertResult = await db.query(
        `INSERT INTO appointments
         (patient_id, doctor_id, appointment_date, appointment_time, appointment_type, consultation_mode, reason_for_visit, consultation_fee, status, payment_status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'scheduled', 'pending') RETURNING id`,
        [patientId, doctorId, appointmentDate, appointmentTime, appointmentType, consultationMode, reason, fee]
      );

      // Get the created appointment with doctor details
      const newAppointment = await db.query(
        `SELECT
          a.*,
          d.full_name as doctor_name,
          d.specialization as doctor_specialty,
          d.profile_image_url as doctor_image
         FROM appointments a
         JOIN doctors d ON a.doctor_id = d.id
         WHERE a.id = $1`,
        [insertResult.rows[0].id]
      );

      const appointment = newAppointment.rows[0];

      res.status(201).json({
        message: 'Appointment booked successfully',
        appointment: {
          id: appointment.id,
          userId: req.user.id,
          patientId: appointment.patient_id,
          doctorId: appointment.doctor_id,
          doctorName: appointment.doctor_name,
          doctorSpecialty: appointment.doctor_specialty,
          doctorImage: appointment.doctor_image,
          appointmentDate: appointment.appointment_date,
          appointmentTime: appointment.appointment_time,
          appointmentType: appointment.appointment_type,
          consultationMode: appointment.consultation_mode,
          reason: appointment.reason_for_visit,
          status: appointment.status,
          consultationFee: parseFloat(appointment.consultation_fee),
          paymentStatus: appointment.payment_status,
          notes: appointment.notes,
          createdAt: appointment.created_at
        }
      });

    } catch (error) {
      console.error('Book appointment error:', error);
      console.error('Error details:', {
        message: error.message,
        code: error.code,
        detail: error.detail
      });
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 2. GET USER APPOINTMENTS
  router.get('/', async (req, res) => {
    try {
      const { status, upcoming } = req.query;

      // Get patient_id for this user
      const patientResult = await db.query(
        'SELECT id FROM patients WHERE user_id = $1',
        [req.user.id]
      );

      if (patientResult.rows.length === 0) {
        return res.json({ appointments: [] });
      }

      const patientId = patientResult.rows[0].id;

      let query = `
        SELECT
          a.*,
          d.full_name as doctor_name,
          d.specialization as doctor_specialty,
          d.profile_image_url as doctor_image,
          d.clinic_phone as doctor_phone,
          p.user_id as user_id
        FROM appointments a
        JOIN doctors d ON a.doctor_id = d.id
        JOIN patients p ON a.patient_id = p.id
        WHERE a.patient_id = $1
      `;
      const params = [patientId];
      let paramCount = 1;

      if (status) {
        paramCount++;
        query += ` AND a.status = $${paramCount}`;
        params.push(status);
      }

      if (upcoming === 'true') {
        query += ' AND a.appointment_date >= CURRENT_DATE';
      }

      query += ' ORDER BY a.appointment_date DESC, a.appointment_time DESC';

      const appointmentsResult = await db.query(query, params);
      const appointments = appointmentsResult.rows;

      res.json({
        appointments: appointments.map(appointment => ({
          id: appointment.id,
          userId: appointment.user_id,
          doctorId: appointment.doctor_id,
          doctorName: appointment.doctor_name,
          doctorSpecialty: appointment.doctor_specialty,
          doctorImage: appointment.doctor_image,
          doctorPhone: appointment.doctor_phone,
          appointmentDate: appointment.appointment_date,
          appointmentTime: appointment.appointment_time,
          appointmentType: appointment.appointment_type,
          consultationMode: appointment.consultation_mode,
          reason: appointment.reason_for_visit,
          status: appointment.status,
          consultationFee: parseFloat(appointment.consultation_fee || 0),
          paymentStatus: appointment.payment_status,
          notes: appointment.notes,
          createdAt: appointment.created_at,
          updatedAt: appointment.updated_at,
          feedbackRating: appointment.feedback_rating,
          feedbackComment: appointment.feedback_comment
        }))
      });

    } catch (error) {
      console.error('Get appointments error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 3. GET APPOINTMENT BY ID
  router.get('/:id', async (req, res) => {
    try {
      const { id } = req.params;

      // Get patient_id for this user
      const patientResult = await db.query(
        'SELECT id FROM patients WHERE user_id = $1',
        [req.user.id]
      );

      if (patientResult.rows.length === 0) {
        return res.status(404).json({ error: 'Patient record not found' });
      }

      const patientId = patientResult.rows[0].id;

      const appointmentResult = await db.query(
        `SELECT
          a.*,
          d.full_name as doctor_name,
          d.specialization as doctor_specialty,
          d.profile_image_url as doctor_image,
          d.clinic_phone as doctor_phone,
          du.email as doctor_email,
          u.full_name as user_name,
          u.phone as user_phone
         FROM appointments a
         JOIN doctors d ON a.doctor_id = d.id
         JOIN users du ON d.user_id = du.id
         JOIN patients p ON a.patient_id = p.id
         JOIN users u ON p.user_id = u.id
         WHERE a.id = $1 AND a.patient_id = $2`,
        [id, patientId]
      );

      if (appointmentResult.rows.length === 0) {
        return res.status(404).json({ error: 'Appointment not found' });
      }

      const appointment = appointmentResult.rows[0];

      res.json({
        appointment: {
          id: appointment.id,
          userId: appointment.patient_id,
          userName: appointment.user_name,
          userPhone: appointment.user_phone,
          doctorId: appointment.doctor_id,
          doctorName: appointment.doctor_name,
          doctorSpecialty: appointment.doctor_specialty,
          doctorImage: appointment.doctor_image,
          doctorPhone: appointment.doctor_phone,
          doctorEmail: appointment.doctor_email,
          appointmentDate: appointment.appointment_date,
          appointmentTime: appointment.appointment_time,
          appointmentType: appointment.appointment_type,
          consultationMode: appointment.consultation_mode,
          reason: appointment.reason_for_visit,
          status: appointment.status,
          consultationFee: parseFloat(appointment.consultation_fee || 0),
          paymentStatus: appointment.payment_status,
          notes: appointment.notes,
          createdAt: appointment.created_at,
          updatedAt: appointment.updated_at,
          feedbackRating: appointment.feedback_rating,
          feedbackComment: appointment.feedback_comment
        }
      });

    } catch (error) {
      console.error('Get appointment error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 4. CANCEL APPOINTMENT
  router.put('/:id/cancel', async (req, res) => {
    try {
      const { id } = req.params;
      const { reason } = req.body;

      // Get patient_id for this user
      const patientResult = await db.query(
        'SELECT id FROM patients WHERE user_id = $1',
        [req.user.id]
      );

      if (patientResult.rows.length === 0) {
        return res.status(404).json({ error: 'Patient record not found' });
      }

      const patientId = patientResult.rows[0].id;

      // Check if appointment exists and belongs to user
      const appointmentCheck = await db.query(
        'SELECT id, status, appointment_date FROM appointments WHERE id = $1 AND patient_id = $2',
        [id, patientId]
      );

      if (appointmentCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Appointment not found' });
      }

      const appointment = appointmentCheck.rows[0];

      if (appointment.status === 'cancelled') {
        return res.status(400).json({ error: 'Appointment is already cancelled' });
      }

      if (appointment.status === 'completed') {
        return res.status(400).json({ error: 'Cannot cancel completed appointment' });
      }

      // Update appointment status
      await db.query(
        `UPDATE appointments
         SET status = 'cancelled', notes = COALESCE(notes, '') || $1
         WHERE id = $2`,
        ['\nCancellation reason: ' + (reason || 'No reason provided'), id]
      );

      res.json({
        message: 'Appointment cancelled successfully'
      });

    } catch (error) {
      console.error('Cancel appointment error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 5. RESCHEDULE APPOINTMENT
  router.put('/:id/reschedule', async (req, res) => {
    try {
      const { id } = req.params;
      const { appointmentDate, appointmentTime } = req.body;

      // Validation
      if (!appointmentDate || !appointmentTime) {
        return res.status(400).json({
          error: 'New appointment date and time are required'
        });
      }

      // Get patient_id for this user
      const patientResult = await db.query(
        'SELECT id FROM patients WHERE user_id = $1',
        [req.user.id]
      );

      if (patientResult.rows.length === 0) {
        return res.status(404).json({ error: 'Patient record not found' });
      }

      const patientId = patientResult.rows[0].id;

      // Check if appointment exists and belongs to user
      const appointmentCheck = await db.query(
        'SELECT id, doctor_id, status FROM appointments WHERE id = $1 AND patient_id = $2',
        [id, patientId]
      );

      if (appointmentCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Appointment not found' });
      }

      const appointment = appointmentCheck.rows[0];

      if (appointment.status === 'cancelled' || appointment.status === 'completed') {
        return res.status(400).json({
          error: `Cannot reschedule ${appointment.status} appointment`
        });
      }

      // Check if new time slot is available
      const conflicting = await db.query(
        `SELECT id FROM appointments
         WHERE doctor_id = $1 AND appointment_date = $2 AND appointment_time = $3
         AND status IN ('scheduled', 'confirmed', 'in_progress') AND id != $4`,
        [appointment.doctor_id, appointmentDate, appointmentTime, id]
      );

      if (conflicting.rows.length > 0) {
        return res.status(400).json({ error: 'New time slot is already booked' });
      }

      // Update appointment
      await db.query(
        `UPDATE appointments
         SET appointment_date = $1, appointment_time = $2, status = 'scheduled'
         WHERE id = $3`,
        [appointmentDate, appointmentTime, id]
      );

      res.json({
        message: 'Appointment rescheduled successfully'
      });

    } catch (error) {
      console.error('Reschedule appointment error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 6. UPDATE PAYMENT STATUS
  router.put('/:id/payment', async (req, res) => {
    try {
      const { id } = req.params;
      const { paymentStatus, paymentId } = req.body;

      // Validation
      if (!paymentStatus || !['pending', 'paid', 'refunded'].includes(paymentStatus)) {
        return res.status(400).json({ error: 'Valid payment status is required' });
      }

      // Get patient_id for this user
      const patientResult = await db.query(
        'SELECT id FROM patients WHERE user_id = $1',
        [req.user.id]
      );

      if (patientResult.rows.length === 0) {
        return res.status(404).json({ error: 'Patient record not found' });
      }

      const patientId = patientResult.rows[0].id;

      // Check if appointment exists and belongs to user
      const appointmentCheck = await db.query(
        'SELECT id FROM appointments WHERE id = $1 AND patient_id = $2',
        [id, patientId]
      );

      if (appointmentCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Appointment not found' });
      }

      // Update payment status
      await db.query(
        'UPDATE appointments SET payment_status = $1, payment_id = $2 WHERE id = $3',
        [paymentStatus, paymentId, id]
      );

      res.json({
        message: 'Payment status updated successfully'
      });

    } catch (error) {
      console.error('Update payment error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 7. SUBMIT FEEDBACK/RATING FOR APPOINTMENT
  router.post('/:id/feedback', async (req, res) => {
    try {
      const { id } = req.params;
      const { rating, feedback } = req.body;

      // Validation
      if (!rating || rating < 1 || rating > 5) {
        return res.status(400).json({
          error: 'Rating is required and must be between 1 and 5'
        });
      }

      // Get patient_id for this user
      const patientResult = await db.query(
        'SELECT id FROM patients WHERE user_id = $1',
        [req.user.id]
      );

      if (patientResult.rows.length === 0) {
        return res.status(404).json({ error: 'Patient record not found' });
      }

      const patientId = patientResult.rows[0].id;

      // Check if appointment exists, belongs to user, and is completed
      const appointmentCheck = await db.query(
        'SELECT id, doctor_id, status, feedback_rating FROM appointments WHERE id = $1 AND patient_id = $2',
        [id, patientId]
      );

      if (appointmentCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Appointment not found' });
      }

      const appointment = appointmentCheck.rows[0];

      if (appointment.status !== 'completed') {
        return res.status(400).json({
          error: 'Can only submit feedback for completed appointments'
        });
      }

      if (appointment.feedback_rating) {
        return res.status(400).json({
          error: 'Feedback already submitted for this appointment'
        });
      }

      // Update appointment with feedback
      await db.query(
        'UPDATE appointments SET feedback_rating = $1, feedback_comment = $2, feedback_date = NOW() WHERE id = $3',
        [rating, feedback || null, id]
      );

      // Update doctor's overall rating
      const ratingResult = await db.query(
        `SELECT AVG(feedback_rating) as avg_rating, COUNT(*) as total_reviews
         FROM appointments
         WHERE doctor_id = $1 AND feedback_rating IS NOT NULL`,
        [appointment.doctor_id]
      );

      const avgRating = parseFloat(ratingResult.rows[0].avg_rating) || rating;
      const totalReviews = parseInt(ratingResult.rows[0].total_reviews) || 1;

      // Update doctor's rating in doctors table
      await db.query(
        'UPDATE doctors SET rating = $1, total_reviews = $2 WHERE id = $3',
        [avgRating.toFixed(1), totalReviews, appointment.doctor_id]
      );

      res.json({
        message: 'Feedback submitted successfully',
        newRating: avgRating.toFixed(1),
        totalReviews: totalReviews
      });

    } catch (error) {
      console.error('Submit feedback error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 8. GET DOCTOR REVIEWS/FEEDBACK
  router.get('/doctor/:doctorId/reviews', async (req, res) => {
    try {
      const { doctorId } = req.params;

      const reviews = await db.query(
        `SELECT
          a.id as appointment_id,
          a.feedback_rating as rating,
          a.feedback_comment as comment,
          a.feedback_date as date,
          u.full_name as patient_name,
          u.profile_image_url as patient_image
         FROM appointments a
         JOIN patients p ON a.patient_id = p.id
         JOIN users u ON p.user_id = u.id
         WHERE a.doctor_id = $1 AND a.feedback_rating IS NOT NULL
         ORDER BY a.feedback_date DESC
         LIMIT 50`,
        [doctorId]
      );

      // Get doctor's average rating
      const ratingResult = await db.query(
        'SELECT rating, total_reviews FROM doctors WHERE id = $1',
        [doctorId]
      );

      const doctorRating = ratingResult.rows[0];

      res.json({
        averageRating: parseFloat(doctorRating?.rating) || 0,
        totalReviews: parseInt(doctorRating?.total_reviews) || 0,
        reviews: reviews.rows.map(review => ({
          appointmentId: review.appointment_id,
          rating: review.rating,
          comment: review.comment,
          date: review.date,
          patientName: review.patient_name,
          patientImage: review.patient_image
        }))
      });

    } catch (error) {
      console.error('Get reviews error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  return router;
};