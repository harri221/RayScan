const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));
app.use(cors({
  origin: '*',
  credentials: true
}));

// Trust proxy for Replit/cloud deployments
app.set('trust proxy', 1);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Request logging middleware
app.use((req, res, next) => {
  console.log(`🔗 ${req.method} ${req.path} - ${new Date().toLocaleTimeString()}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('📦 Request body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files for uploads
const uploadDir = process.env.UPLOAD_PATH || 'uploads/';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
app.use('/uploads', express.static(uploadDir));

// Database connection
let db;
async function connectDB() {
  try {
    // Support both DATABASE_URL and individual variables
    const dbConfig = process.env.DATABASE_URL
      ? { connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } }
      : {
          host: process.env.DB_HOST,
          user: process.env.DB_USER,
          password: process.env.DB_PASSWORD,
          database: process.env.DB_NAME,
          port: process.env.DB_PORT || 5432,
          ssl: { rejectUnauthorized: false }
        };

    db = new Pool({
      ...dbConfig,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000
    });

    // Test the connection
    const client = await db.connect();
    await client.query('SELECT NOW()');
    client.release();

    console.log('✅ Connected to PostgreSQL database');
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    process.exit(1);
  }
}

// JWT middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// Helper function to generate JWT
const generateToken = (user) => {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      name: user.full_name || user.name
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );
};

// Helper function to generate 6-digit verification code
const generateVerificationCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// AUTHENTICATION ROUTES

// 1. USER SIGNUP
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { name, email, phone, password, dateOfBirth, gender, address } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email and password are required' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Check if user already exists
    const existingUsers = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUsers.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists with this email' });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Insert new user
    const result = await db.query(
      `INSERT INTO users (full_name, email, phone, password_hash, date_of_birth, gender, address, role)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
      [name, email, phone || null, hashedPassword, dateOfBirth || null, gender || null, address || null, 'patient']
    );

    // Get the created user
    const newUser = await db.query(
      'SELECT id, full_name, email, phone, date_of_birth, gender, address, created_at FROM users WHERE id = $1',
      [result.rows[0].id]
    );

    const user = newUser.rows[0];
    const token = generateToken(user);

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user.id,
        name: user.full_name,
        email: user.email,
        phone: user.phone,
        dateOfBirth: user.date_of_birth,
        gender: user.gender,
        address: user.address,
        createdAt: user.created_at
      },
      userType: 'user',
      role: 'patient',
      token
    });

  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 2. USER LOGIN
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const users = await db.query(
      'SELECT * FROM users WHERE email = $1 AND is_active = TRUE',
      [email]
    );

    if (users.rows.length === 0) {
      return res.status(401).json({ error: 'No account found with this email address' });
    }

    const user = users.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Incorrect password. Please try again' });
    }

    const token = generateToken(user);

    // Determine user type for Socket.io authentication
    const userType = user.role === 'doctor' ? 'doctor' : 'user';

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.full_name,
        email: user.email,
        phone: user.phone,
        profileImage: user.profile_image,
        dateOfBirth: user.date_of_birth,
        gender: user.gender,
        address: user.address
      },
      userType: userType,
      role: user.role,
      token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 3. FORGOT PASSWORD - REQUEST RESET
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { contactInfo, contactType } = req.body;

    // Validation
    if (!contactInfo || !contactType) {
      return res.status(400).json({ error: 'Contact info and type are required' });
    }

    if (!['email', 'phone'].includes(contactType)) {
      return res.status(400).json({ error: 'Contact type must be email or phone' });
    }

    // Find user by email or phone
    const field = contactType === 'email' ? 'email' : 'phone';
    const users = await db.query(
      `SELECT id, name, email, phone FROM users WHERE ${field} = $1 AND is_active = TRUE`,
      [contactInfo]
    );

    if (users.rows.length === 0) {
      return res.status(404).json({ error: 'No user found with this contact information' });
    }

    const user = users.rows[0];

    // Generate verification code
    const verificationCode = generateVerificationCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store verification code in database
    await db.query(
      'INSERT INTO password_reset_tokens (user_id, token, contact_info, contact_type, expires_at) VALUES ($1, $2, $3, $4, $5)',
      [user.id, verificationCode, contactInfo, contactType, expiresAt]
    );

    // In production, you would send email/SMS here
    // For development, we'll return the code in response
    console.log(`Verification code for ${contactInfo}: ${verificationCode}`);

    res.json({
      message: 'Verification code sent successfully',
      // Remove this in production
      verificationCode: process.env.NODE_ENV === 'development' ? verificationCode : undefined
    });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 4. VERIFY RESET CODE
app.post('/api/auth/verify-reset-code', async (req, res) => {
  try {
    const { contactInfo, contactType, verificationCode } = req.body;

    // Validation
    if (!contactInfo || !contactType || !verificationCode) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    // Find valid token
    const tokens = await db.query(
      `SELECT * FROM password_reset_tokens
       WHERE contact_info = $1 AND contact_type = $2 AND token = $3
       AND expires_at > NOW() AND is_used = FALSE
       ORDER BY created_at DESC LIMIT 1`,
      [contactInfo, contactType, verificationCode]
    );

    if (tokens.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired verification code' });
    }

    // Generate temporary reset token for password reset
    const resetToken = jwt.sign(
      {
        tokenId: tokens.rows[0].id,
        userId: tokens.rows[0].user_id,
        contactInfo: contactInfo
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    res.json({
      message: 'Verification code verified successfully',
      resetToken
    });

  } catch (error) {
    console.error('Verify code error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 5. RESET PASSWORD
app.post('/api/auth/reset-password', async (req, res) => {
  try {
    const { resetToken, newPassword } = req.body;

    // Validation
    if (!resetToken || !newPassword) {
      return res.status(400).json({ error: 'Reset token and new password are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Verify reset token
    let decoded;
    try {
      decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
    } catch (err) {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }

    // Check if token is still valid in database
    const tokens = await db.query(
      'SELECT * FROM password_reset_tokens WHERE id = $1 AND is_used = FALSE AND expires_at > NOW()',
      [decoded.tokenId]
    );

    if (tokens.rows.length === 0) {
      return res.status(400).json({ error: 'Reset token has been used or expired' });
    }

    // Hash new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update user password
    await db.query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
      [hashedPassword, decoded.userId]
    );

    // Mark token as used
    await db.query(
      'UPDATE password_reset_tokens SET is_used = TRUE WHERE id = $1',
      [decoded.tokenId]
    );

    res.json({
      message: 'Password reset successfully'
    });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 6. DOCTOR SIGNUP
app.post('/api/auth/doctor/signup', async (req, res) => {
  try {
    const {
      fullName,
      email,
      phone,
      password,
      gender,
      pmdcNumber,
      specialization,
      qualification,
      experienceYears,
      consultationFee,
      clinicAddress,
      clinicPhone,
      bio
    } = req.body;

    // Validation
    if (!fullName || !email || !password || !pmdcNumber || !specialization) {
      return res.status(400).json({
        error: 'Full name, email, password, PMDC number and specialization are required'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Check if user already exists
    const existingUsers = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUsers.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists with this email' });
    }

    // Check if PMDC number already exists
    const existingPMDC = await db.query(
      'SELECT id FROM doctors WHERE pmdc_number = $1',
      [pmdcNumber]
    );

    if (existingPMDC.rows.length > 0) {
      return res.status(400).json({ error: 'PMDC number already registered' });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Start transaction
    const client = await db.connect();

    try {
      await client.query('BEGIN');

      // Insert user
      const userResult = await client.query(
        `INSERT INTO users (full_name, email, phone, password_hash, gender, role)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
        [fullName, email, phone || null, hashedPassword, gender || null, 'doctor']
      );

      const userId = userResult.rows[0].id;

      // Insert doctor profile
      await client.query(
        `INSERT INTO doctors (
          user_id, pmdc_number, specialization, qualification, experience_years,
          consultation_fee, clinic_address, clinic_phone, bio, full_name
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [
          userId,
          pmdcNumber,
          specialization,
          qualification || null,
          experienceYears || 0,
          consultationFee || 0.00,
          clinicAddress || null,
          clinicPhone || null,
          bio || null,
          fullName
        ]
      );

      await client.query('COMMIT');

      // Get the created user
      const newUser = await db.query(
        'SELECT id, full_name, email, phone, gender, created_at FROM users WHERE id = $1',
        [userId]
      );

      const user = newUser.rows[0];
      const token = generateToken(user);

      res.status(201).json({
        message: 'Doctor account created successfully',
        user: {
          id: user.id,
          name: user.full_name,
          email: user.email,
          phone: user.phone,
          gender: user.gender,
          role: 'doctor',
          createdAt: user.created_at
        },
        userType: 'doctor',
        role: 'doctor',
        token
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Doctor signup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 7. GET USER PROFILE
app.get('/api/user/profile', authenticateToken, async (req, res) => {
  try {
    const users = await db.query(
      'SELECT id, full_name, email, phone, profile_image, date_of_birth, gender, address, created_at FROM users WHERE id = $1 AND is_active = TRUE',
      [req.user.id]
    );

    if (users.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = users.rows[0];
    res.json({
      user: {
        id: user.id,
        name: user.full_name,
        email: user.email,
        phone: user.phone,
        profileImage: user.profile_image,
        dateOfBirth: user.date_of_birth,
        gender: user.gender,
        address: user.address,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Profile fetch error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Import route modules
const doctorsRoutes = require('./routes/doctors');
const doctorProfileRoutes = require('./routes/doctor_profile');
const usersRoutes = require('./routes/users');
const appointmentsRoutes = require('./routes/appointments');
const chatRoutes = require('./routes/chat');
const reportsRoutes = require('./routes/reports');
const pharmacyRoutes = require('./routes/pharmacy');
const mlPredictionRoutes = require('./routes/ml_prediction');
const adminRoutes = require('./routes/admin');

// Socket.io connection handling
const connectedUsers = new Map();

io.on('connection', (socket) => {
  console.log(`👤 User connected: ${socket.id}`);

  // Handle user authentication for socket
  socket.on('authenticate', (data) => {
    const { userId, userType = 'user' } = data;
    socket.userId = userId;
    socket.userType = userType;

    // Join user to their room
    socket.join(`${userType}_${userId}`);
    connectedUsers.set(userId, { socketId: socket.id, userType });

    console.log(`✅ ${userType} ${userId} authenticated`);
  });

  // Handle joining conversation room
  socket.on('join_conversation', (conversationId) => {
    socket.join(`conversation_${conversationId}`);
    console.log(`📞 User ${socket.userId} joined conversation ${conversationId}`);
  });

  // Handle leaving conversation room
  socket.on('leave_conversation', (conversationId) => {
    socket.leave(`conversation_${conversationId}`);
    console.log(`📴 User ${socket.userId} left conversation ${conversationId}`);
  });

  // Handle typing indicators
  socket.on('typing_start', (data) => {
    socket.to(`conversation_${data.conversationId}`).emit('user_typing', {
      userId: socket.userId,
      userName: data.userName || 'User'
    });
  });

  socket.on('typing_stop', (data) => {
    socket.to(`conversation_${data.conversationId}`).emit('user_stop_typing', {
      userId: socket.userId
    });
  });

  // Handle video/audio call signaling
  socket.on('call_request', async (data) => {
    const { targetUserId, conversationId, callType, callerName, roomId } = data;

    console.log(`📞 Call request from user ${socket.userId} to target ${targetUserId}, type: ${callType}`);

    // Track call in database
    try {
      // IMPORTANT: targetUserId might be a doctor ID (from doctors table)
      // We need to convert it to the actual user_id
      let actualTargetUserId = targetUserId;
      let targetUserType = 'user';

      // Check if targetUserId is a doctor by looking up in doctors table
      const doctorCheck = await db.query(
        'SELECT user_id FROM doctors WHERE id = $1',
        [targetUserId]
      );

      if (doctorCheck.rows.length > 0) {
        // This is a doctor ID, convert to user_id
        actualTargetUserId = doctorCheck.rows[0].user_id;
        targetUserType = 'doctor';
        console.log(`🔄 Converted doctor ID ${targetUserId} to user ID ${actualTargetUserId}`);
      } else {
        // Check if it's a patient by verifying in users table
        const userCheck = await db.query(
          'SELECT id FROM users WHERE id = $1',
          [targetUserId]
        );
        if (userCheck.rows.length > 0) {
          actualTargetUserId = targetUserId;
          targetUserType = 'user';
        }
      }

      const targetUser = connectedUsers.get(actualTargetUserId);

      const result = await db.query(
        `INSERT INTO call_logs (conversation_id, caller_user_id, receiver_user_id, call_type, status, channel_name, started_at)
         VALUES ($1, $2, $3, $4, $5, $6, NOW())
         RETURNING id`,
        [conversationId, socket.userId, actualTargetUserId, callType, 'ringing', roomId]
      );

      const callLogId = result.rows[0].id;
      console.log(`📝 Call log created: ${callLogId} for user ${actualTargetUserId}`);

      if (targetUser) {
        const callPayload = {
          callLogId: callLogId,
          callerId: socket.userId,
          conversationId: conversationId,
          callerName: callerName,
          callType: callType,
          roomId: roomId
        };

        // Emit to target user's socket
        io.to(targetUser.socketId).emit('incoming_call', callPayload);

        // ALSO emit to target user's room (for redundancy)
        io.to(`${targetUserType}_${actualTargetUserId}`).emit('incoming_call', callPayload);

        console.log(`✅ Call notification sent to ${targetUserType}_${actualTargetUserId} (socket: ${targetUser.socketId})`);
      } else {
        console.log(`❌ Target user ${actualTargetUserId} (${targetUserType}) not connected - marking as missed`);
        // Mark as missed immediately if user not connected
        await db.query(
          'UPDATE call_logs SET status = $1, ended_at = NOW() WHERE id = $2',
          ['missed', callLogId]
        );
      }
    } catch (error) {
      console.error('Error tracking call:', error);
    }
  });

  socket.on('call_response', async (data) => {
    const { callerId, accepted, callLogId } = data;
    const caller = connectedUsers.get(callerId);

    console.log(`📞 Call response from user ${socket.userId}: ${accepted ? 'accepted' : 'rejected'}`);

    // Update call log
    if (callLogId) {
      try {
        const status = accepted ? 'answered' : 'rejected';
        await db.query(
          'UPDATE call_logs SET status = $1, updated_at = NOW() WHERE id = $2',
          [status, callLogId]
        );

        if (!accepted) {
          await db.query(
            'UPDATE call_logs SET ended_at = NOW() WHERE id = $1',
            [callLogId]
          );
        }
      } catch (error) {
        console.error('Error updating call log:', error);
      }
    }

    if (caller) {
      io.to(caller.socketId).emit('call_response', {
        accepted: accepted,
        responderId: socket.userId,
        callLogId: callLogId
      });
    }
  });

  // Handle call end
  socket.on('call_ended', async (data) => {
    const { callLogId, duration } = data;

    if (callLogId) {
      try {
        await db.query(
          'UPDATE call_logs SET status = $1, duration = $2, ended_at = NOW() WHERE id = $3',
          ['ended', duration || 0, callLogId]
        );
        console.log(`📞 Call ${callLogId} ended, duration: ${duration}s`);
      } catch (error) {
        console.error('Error ending call:', error);
      }
    }
  });

  socket.on('disconnect', () => {
    if (socket.userId) {
      connectedUsers.delete(socket.userId);
    }
    console.log(`❌ User disconnected: ${socket.id}`);
  });
});

// Routes will be initialized after database connection

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'RayScan Backend API is running',
    timestamp: new Date().toISOString(),
    connectedUsers: connectedUsers.size
  });
});

// Error handlers will be moved after route initialization

// Start server
const PORT = process.env.PORT || 3000;

async function startServer() {
  await connectDB();

  // Initialize routes after database connection
  console.log('🔄 Initializing routes...');
  try {
    app.use('/api/doctors', authenticateToken, doctorsRoutes(db));
    console.log('✅ Doctors route initialized');

    app.use('/api/doctor', authenticateToken, doctorProfileRoutes(db));
    console.log('✅ Doctor Profile route initialized');

    app.use('/api/users', authenticateToken, usersRoutes(db));
    console.log('✅ Users route initialized');

    app.use('/api/appointments', authenticateToken, appointmentsRoutes(db));
    console.log('✅ Appointments route initialized');

    app.use('/api/chat', authenticateToken, chatRoutes(db, io));
    console.log('✅ Chat route initialized');

    app.use('/api/reports', authenticateToken, reportsRoutes(db));
    console.log('✅ Reports route initialized');

    app.use('/api/pharmacy', authenticateToken, pharmacyRoutes(db));
    console.log('✅ Pharmacy route initialized');

    app.use('/api/ml', authenticateToken, mlPredictionRoutes(db));
    console.log('✅ ML Prediction route initialized');

    app.use('/api/admin', adminRoutes(db));
    console.log('✅ Admin route initialized');

    console.log('🎉 All routes initialized successfully');
  } catch (error) {
    console.error('❌ Error initializing routes:', error);
  }

  // Add error handlers AFTER routes
  // Error handling middleware
  app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
  });

  // 404 handler (must be last)
  app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
  });

  server.listen(PORT, () => {
    console.log(`🚀 RayScan Backend Server running on port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
    console.log(`🔌 Socket.io enabled for real-time features`);
    console.log(`📁 Environment: ${process.env.NODE_ENV || 'development'}`);
  });
}

startServer().catch(console.error);