const express = require('express');
const router = express.Router();

// Admin API routes for the Med-Admin-Vista portal
module.exports = (db) => {

  // Admin Authentication
  router.post('/auth/login', async (req, res) => {
    try {
      const { username, password } = req.body;

      // For now, using simple admin credentials
      // TODO: Hash passwords and store in database
      if (username === 'admin' && password === 'admin123') {
        // Generate a simple token (in production, use JWT)
        const token = Buffer.from(`${username}:${Date.now()}`).toString('base64');

        res.json({
          success: true,
          token: token,
          adminId: 1,
          adminName: 'System Administrator',
          email: 'admin@rayscan.com',
          role: 'admin'
        });
      } else {
        res.status(401).json({ error: 'Invalid credentials' });
      }
    } catch (error) {
      console.error('Admin login error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Get Dashboard Statistics
  router.get('/stats', async (req, res) => {
    try {
      // Get total doctors
      const doctorsResult = await db.query('SELECT COUNT(*) as count FROM doctors');
      const totalDoctors = parseInt(doctorsResult.rows[0].count);

      // Get total patients/users (only role='patient', not doctors)
      const patientsResult = await db.query("SELECT COUNT(*) as count FROM users WHERE role = 'patient'");
      const totalPatients = parseInt(patientsResult.rows[0].count);

      // Get scans completed (from reports)
      const scansResult = await db.query('SELECT COUNT(*) as count FROM reports');
      const scansCompleted = parseInt(scansResult.rows[0].count);

      // Get today's appointments
      const appointmentsResult = await db.query(
        `SELECT COUNT(*) as count FROM appointments
         WHERE DATE(appointment_date) = CURRENT_DATE`
      );
      const appointmentsToday = parseInt(appointmentsResult.rows[0].count);

      res.json({
        totalDoctors,
        totalPatients,
        scansCompleted,
        appointmentsToday
      });
    } catch (error) {
      console.error('Get admin stats error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Get Recent Activities
  router.get('/activities', async (req, res) => {
    try {
      const limit = parseInt(req.query.limit) || 10;

      // Get recent doctor registrations
      const recentDoctors = await db.query(
        `SELECT 'doctor_registration' as type, u.full_name as name, u.created_at as timestamp
         FROM doctors d
         INNER JOIN users u ON d.user_id = u.id
         WHERE u.role = 'doctor'
         ORDER BY u.created_at DESC
         LIMIT $1`,
        [Math.floor(limit / 2)]
      );

      // Get recent appointments
      const recentAppointments = await db.query(
        `SELECT 'appointment' as type,
                u.full_name as name,
                a.created_at as timestamp
         FROM appointments a
         JOIN users u ON a.user_id = u.id
         ORDER BY a.created_at DESC
         LIMIT $1`,
        [Math.floor(limit / 2)]
      );

      // Combine and sort activities
      const activities = [
        ...recentDoctors.rows.map(row => ({
          id: Math.random(),
          type: 'New doctor registration',
          description: `Dr. ${row.name}`,
          timestamp: row.timestamp
        })),
        ...recentAppointments.rows.map(row => ({
          id: Math.random(),
          type: 'Patient appointment scheduled',
          description: row.name,
          timestamp: row.timestamp
        }))
      ].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

      res.json(activities.slice(0, limit));
    } catch (error) {
      console.error('Get activities error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Get Quick Stats
  router.get('/quick-stats', async (req, res) => {
    try {
      // Count all doctors as pending since verification system not yet implemented
      const pendingResult = await db.query(
        `SELECT COUNT(*) as count FROM doctors`
      );
      const pendingVerifications = parseInt(pendingResult.rows[0].count);

      // Active sessions (approximate - could implement proper session tracking)
      const activeSessions = 0; // TODO: Implement session tracking

      // System health (placeholder - could implement health checks)
      const systemHealth = '98.5%';

      // Storage used (placeholder - could calculate actual storage)
      const storageUsed = '67%';

      res.json({
        pendingVerifications,
        activeSessions,
        systemHealth,
        storageUsed
      });
    } catch (error) {
      console.error('Get quick stats error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Get All Doctors with Filtering
  router.get('/doctors', async (req, res) => {
    try {
      const { status, page = 1, limit = 10 } = req.query;
      const offset = (page - 1) * limit;

      let query = `
        SELECT
          d.id,
          u.full_name as "fullName",
          u.email,
          u.phone,
          d.specialization as specialty,
          d.qualification,
          d.experience_years as "experienceYears",
          d.pmdc_number as "pmdcNumber",
          d.consultation_fee as "consultationFee",
          d.clinic_address as "clinicAddress",
          d.clinic_phone as "clinicPhone",
          d.bio,
          u.gender,
          u.created_at as "dateRegistered"
        FROM doctors d
        INNER JOIN users u ON d.user_id = u.id
        WHERE u.is_active = true AND u.role = 'doctor'
      `;

      const params = [];

      // For now, show all doctors as "Pending" since verification system not yet implemented
      // Filter will just return all or empty
      if (status && status === 'Rejected') {
        query += ' AND 1=0'; // Return empty for rejected
      }

      query += ` ORDER BY u.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
      params.push(parseInt(limit), offset);

      const result = await db.query(query, params);

      // Get total count
      let countQuery = 'SELECT COUNT(*) as count FROM doctors d INNER JOIN users u ON d.user_id = u.id WHERE u.is_active = true';
      if (status && status === 'Rejected') {
        countQuery += ' AND 1=0';
      }
      const countResult = await db.query(countQuery);
      const total = parseInt(countResult.rows[0].count);

      // Map database fields to frontend expected format
      const doctors = result.rows.map(doctor => ({
        id: doctor.id,
        fullName: doctor.fullName,
        fatherName: 'N/A', // Not in database - could add later
        pmdcNumber: doctor.pmdcNumber || 'N/A',
        status: status === 'Verified' ? 'Verified' : 'Pending', // Default to Pending
        specialty: doctor.specialty,
        dateRegistered: doctor.dateRegistered,
        email: doctor.email,
        phone: doctor.phone,
        gender: doctor.gender,
        qualification: doctor.qualification,
        experienceYears: doctor.experienceYears,
        consultationFee: doctor.consultationFee,
        clinicAddress: doctor.clinicAddress,
        clinicPhone: doctor.clinicPhone,
        bio: doctor.bio
      }));

      res.json({
        doctors,
        total,
        page: parseInt(page),
        limit: parseInt(limit)
      });
    } catch (error) {
      console.error('Get doctors error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Update Doctor Status (Verify/Reject)
  router.patch('/doctors/:id/status', async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (!['Verified', 'Rejected', 'Pending'].includes(status)) {
        return res.status(400).json({ error: 'Invalid status' });
      }

      // TODO: Add is_verified column to doctors table
      // For now, just return success without actually updating
      await db.query(
        'UPDATE doctors SET updated_at = NOW() WHERE id = $1',
        [id]
      );

      // Get updated doctor
      const result = await db.query(
        `SELECT
          d.id,
          u.full_name as "fullName",
          u.email,
          u.phone,
          d.specialization as specialty,
          d.pmdc_number as "pmdcNumber",
          d.created_at as "dateRegistered"
        FROM doctors d
        INNER JOIN users u ON d.user_id = u.id
        WHERE d.id = $1`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor not found' });
      }

      const doctor = result.rows[0];

      res.json({
        success: true,
        doctor: {
          id: doctor.id,
          fullName: doctor.fullName,
          fatherName: 'N/A',
          pmdcNumber: doctor.pmdcNumber || 'N/A',
          status: status, // Use the requested status
          specialty: doctor.specialty,
          dateRegistered: doctor.dateRegistered,
          email: doctor.email,
          phone: doctor.phone
        }
      });
    } catch (error) {
      console.error('Update doctor status error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Get All Patients with Search and Filtering
  router.get('/patients', async (req, res) => {
    try {
      const { search, status, page = 1, limit = 10 } = req.query;
      const offset = (page - 1) * limit;

      let query = `
        SELECT
          id,
          full_name as name,
          email,
          date_of_birth,
          gender,
          created_at as "dateRegistered",
          phone
        FROM users
        WHERE role = 'patient' AND is_active = true
      `;

      const params = [];

      // Apply search filter
      if (search) {
        params.push(`%${search}%`);
        query += ` AND (full_name ILIKE $${params.length} OR email ILIKE $${params.length})`;
      }

      query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
      params.push(parseInt(limit), offset);

      const result = await db.query(query, params);

      // Get total count
      let countQuery = "SELECT COUNT(*) as count FROM users WHERE role = 'patient' AND is_active = true";
      const countParams = [];
      if (search) {
        countParams.push(`%${search}%`);
        countQuery += ` AND (full_name ILIKE $${countParams.length} OR email ILIKE $${countParams.length})`;
      }
      const countResult = await db.query(countQuery, countParams);
      const total = parseInt(countResult.rows[0].count);

      // Calculate age from date_of_birth
      const patients = result.rows.map(patient => {
        let age = null;
        if (patient.date_of_birth) {
          const birthDate = new Date(patient.date_of_birth);
          const today = new Date();
          age = today.getFullYear() - birthDate.getFullYear();
        }

        return {
          id: patient.id,
          name: patient.name,
          age: age || 0,
          gender: patient.gender || 'Unknown',
          email: patient.email,
          dateRegistered: patient.dateRegistered,
          lastVisit: patient.dateRegistered, // TODO: Get actual last visit from appointments
          status: 'Active' // TODO: Implement proper status tracking
        };
      });

      res.json({
        patients,
        total,
        page: parseInt(page),
        limit: parseInt(limit)
      });
    } catch (error) {
      console.error('Get patients error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Get Patient Statistics
  router.get('/patients/stats', async (req, res) => {
    try {
      // Total patients (only users with role='patient')
      const totalResult = await db.query("SELECT COUNT(*) as count FROM users WHERE role = 'patient'");
      const total = parseInt(totalResult.rows[0].count);

      // Active patients (only users with role='patient' and is_active=true)
      const activeResult = await db.query("SELECT COUNT(*) as count FROM users WHERE role = 'patient' AND is_active = true");
      const active = parseInt(activeResult.rows[0].count);

      // New this month (only patients)
      const newThisMonthResult = await db.query(
        `SELECT COUNT(*) as count FROM users
         WHERE role = 'patient' AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)`
      );
      const newThisMonth = parseInt(newThisMonthResult.rows[0].count);

      res.json({
        totalPatients: total,
        activePatients: active,
        newThisMonth: newThisMonth
      });
    } catch (error) {
      console.error('Get patient stats error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Get Patient Profile by ID
  router.get('/patients/:id', async (req, res) => {
    try {
      const { id } = req.params;

      const result = await db.query(
        `SELECT
          id,
          full_name as name,
          email,
          phone,
          date_of_birth,
          gender,
          address,
          profile_image as "profileImage",
          created_at as "dateRegistered"
        FROM users
        WHERE id = $1 AND is_active = true`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Patient not found' });
      }

      const patient = result.rows[0];

      // Calculate age
      let age = null;
      if (patient.date_of_birth) {
        const birthDate = new Date(patient.date_of_birth);
        const today = new Date();
        age = today.getFullYear() - birthDate.getFullYear();
      }

      // Get recent appointments
      const appointmentsResult = await db.query(
        `SELECT
          a.id,
          a.appointment_date,
          a.status,
          a.notes as reason,
          d.full_name as doctor_name,
          doc.specialization as doctor_specialty
        FROM appointments a
        LEFT JOIN doctors doc ON a.doctor_id = doc.id
        LEFT JOIN users d ON doc.user_id = d.id
        WHERE a.user_id = $1
        ORDER BY a.appointment_date DESC
        LIMIT 5`,
        [id]
      );

      // Get recent reports
      const reportsResult = await db.query(
        `SELECT
          id,
          report_type,
          prediction_result,
          confidence_score,
          created_at
        FROM reports
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT 5`,
        [id]
      );

      res.json({
        patient: {
          id: patient.id,
          name: patient.name,
          email: patient.email,
          phone: patient.phone,
          age: age || 0,
          dateOfBirth: patient.date_of_birth,
          gender: patient.gender || 'Unknown',
          address: patient.address,
          profileImage: patient.profileImage,
          dateRegistered: patient.dateRegistered,
          recentAppointments: appointmentsResult.rows,
          recentReports: reportsResult.rows
        }
      });
    } catch (error) {
      console.error('Get patient profile error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Get Doctor Profile by ID
  router.get('/doctors/:id/profile', async (req, res) => {
    try {
      const { id } = req.params;

      const result = await db.query(
        `SELECT
          d.id,
          u.full_name as "fullName",
          u.email,
          u.phone,
          u.gender,
          d.pmdc_number as "pmdcNumber",
          d.specialization as specialty,
          d.qualification,
          d.experience_years as "experienceYears",
          d.consultation_fee as "consultationFee",
          d.clinic_address as "clinicAddress",
          d.clinic_phone as "clinicPhone",
          d.bio,
          u.profile_image as "profileImage",
          d.created_at as "dateRegistered"
        FROM doctors d
        INNER JOIN users u ON d.user_id = u.id
        WHERE d.id = $1 AND u.is_active = true`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor not found' });
      }

      const doctor = result.rows[0];

      // Get appointment statistics
      const appointmentsResult = await db.query(
        `SELECT
          COUNT(*) as total,
          SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
          SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) as upcoming
        FROM appointments
        WHERE doctor_id = $1`,
        [id]
      );

      const appointmentStats = appointmentsResult.rows[0];

      // Get recent appointments
      const recentAppointmentsResult = await db.query(
        `SELECT
          a.id,
          a.appointment_date,
          a.status,
          a.reason,
          u.full_name as patient_name
        FROM appointments a
        LEFT JOIN users u ON a.user_id = u.id
        WHERE a.doctor_id = $1
        ORDER BY a.appointment_date DESC
        LIMIT 5`,
        [id]
      );

      res.json({
        doctor: {
          id: doctor.id,
          fullName: doctor.fullName,
          email: doctor.email,
          phone: doctor.phone,
          gender: doctor.gender,
          pmdcNumber: doctor.pmdcNumber,
          specialty: doctor.specialty,
          qualification: doctor.qualification,
          experienceYears: doctor.experienceYears,
          consultationFee: doctor.consultationFee,
          clinicAddress: doctor.clinicAddress,
          clinicPhone: doctor.clinicPhone,
          bio: doctor.bio,
          profileImage: doctor.profileImage,
          dateRegistered: doctor.dateRegistered,
          appointmentStats: {
            total: parseInt(appointmentStats.total),
            completed: parseInt(appointmentStats.completed),
            upcoming: parseInt(appointmentStats.upcoming)
          },
          recentAppointments: recentAppointmentsResult.rows
        }
      });
    } catch (error) {
      console.error('Get doctor profile error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Delete Doctor
  router.delete('/doctors/:id', async (req, res) => {
    try {
      const { id } = req.params;

      // Get doctor's user_id before deletion
      const doctorResult = await db.query(
        'SELECT user_id FROM doctors WHERE id = $1',
        [id]
      );

      if (doctorResult.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor not found' });
      }

      const userId = doctorResult.rows[0].user_id;

      // Start transaction
      await db.query('BEGIN');

      try {
        // Delete from doctors table (will cascade to related tables)
        await db.query('DELETE FROM doctors WHERE id = $1', [id]);

        // Delete from users table (this will cascade to appointments, etc.)
        await db.query('DELETE FROM users WHERE id = $1', [userId]);

        await db.query('COMMIT');

        console.log(`✅ Admin deleted doctor ID ${id} (user ID ${userId})`);

        res.json({
          success: true,
          message: 'Doctor deleted successfully'
        });
      } catch (error) {
        await db.query('ROLLBACK');
        throw error;
      }
    } catch (error) {
      console.error('Delete doctor error:', error);
      res.status(500).json({ error: 'Failed to delete doctor' });
    }
  });

  // Delete Patient
  router.delete('/patients/:id', async (req, res) => {
    try {
      const { id } = req.params;

      // Check if patient exists
      const patientResult = await db.query(
        "SELECT id FROM users WHERE id = $1 AND role = 'patient'",
        [id]
      );

      if (patientResult.rows.length === 0) {
        return res.status(404).json({ error: 'Patient not found' });
      }

      // Delete patient (cascades will handle related data)
      await db.query('DELETE FROM users WHERE id = $1', [id]);

      console.log(`✅ Admin deleted patient ID ${id}`);

      res.json({
        success: true,
        message: 'Patient deleted successfully'
      });
    } catch (error) {
      console.error('Delete patient error:', error);
      res.status(500).json({ error: 'Failed to delete patient' });
    }
  });

  return router;
};
