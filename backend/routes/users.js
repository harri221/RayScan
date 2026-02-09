const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for profile image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/profiles/';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
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

// User Profile API routes
module.exports = (db) => {

  // GET USER PROFILE
  router.get('/profile', async (req, res) => {
    try {
      const userId = req.user.id;

      const result = await db.query(
        `SELECT id, full_name, email, phone, profile_image,
                date_of_birth, gender, address, role, created_at
         FROM users
         WHERE id = $1 AND is_active = true`,
        [userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      const user = result.rows[0];

      res.json({
        user: {
          id: user.id,
          fullName: user.full_name,
          email: user.email,
          phone: user.phone,
          profileImage: user.profile_image,
          dateOfBirth: user.date_of_birth,
          gender: user.gender,
          address: user.address,
          role: user.role,
          createdAt: user.created_at
        }
      });

    } catch (error) {
      console.error('Get user profile error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // UPDATE USER PROFILE
  router.put('/profile', async (req, res) => {
    try {
      const userId = req.user.id;
      const { fullName, phone, dateOfBirth, gender, address } = req.body;

      const updates = [];
      const values = [];
      let paramCount = 1;

      if (fullName !== undefined) {
        updates.push(`full_name = $${paramCount++}`);
        values.push(fullName);
      }
      if (phone !== undefined) {
        updates.push(`phone = $${paramCount++}`);
        values.push(phone);
      }
      if (dateOfBirth !== undefined) {
        updates.push(`date_of_birth = $${paramCount++}`);
        values.push(dateOfBirth);
      }
      if (gender !== undefined) {
        updates.push(`gender = $${paramCount++}`);
        values.push(gender);
      }
      if (address !== undefined) {
        updates.push(`address = $${paramCount++}`);
        values.push(address);
      }

      if (updates.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }

      updates.push(`updated_at = CURRENT_TIMESTAMP`);
      values.push(userId);

      const query = `
        UPDATE users
        SET ${updates.join(', ')}
        WHERE id = $${paramCount} AND is_active = true
        RETURNING id, full_name, email, phone, profile_image,
                  date_of_birth, gender, address, role, created_at
      `;

      const result = await db.query(query, values);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      const user = result.rows[0];

      res.json({
        user: {
          id: user.id,
          fullName: user.full_name,
          email: user.email,
          phone: user.phone,
          profileImage: user.profile_image,
          dateOfBirth: user.date_of_birth,
          gender: user.gender,
          address: user.address,
          role: user.role,
          createdAt: user.created_at
        }
      });

    } catch (error) {
      console.error('Update user profile error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // UPLOAD PROFILE IMAGE
  router.post('/profile/image', upload.single('profileImage'), async (req, res) => {
    try {
      const userId = req.user.id;

      if (!req.file) {
        return res.status(400).json({ error: 'No image file uploaded' });
      }

      const imageUrl = `/uploads/profiles/${req.file.filename}`;

      // Get old image to delete it
      const oldUser = await db.query(
        'SELECT profile_image FROM users WHERE id = $1',
        [userId]
      );

      // Update user with new image
      const result = await db.query(
        `UPDATE users
         SET profile_image = $1, updated_at = CURRENT_TIMESTAMP
         WHERE id = $2 AND is_active = true
         RETURNING id, full_name, email, phone, profile_image,
                   date_of_birth, gender, address, role, created_at`,
        [imageUrl, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      // Delete old image if exists
      if (oldUser.rows[0]?.profile_image) {
        const oldImagePath = path.join(__dirname, '..', oldUser.rows[0].profile_image);
        if (fs.existsSync(oldImagePath)) {
          try {
            fs.unlinkSync(oldImagePath);
          } catch (err) {
            console.error('Error deleting old image:', err);
          }
        }
      }

      const user = result.rows[0];

      res.json({
        user: {
          id: user.id,
          fullName: user.full_name,
          email: user.email,
          phone: user.phone,
          profileImage: user.profile_image,
          dateOfBirth: user.date_of_birth,
          gender: user.gender,
          address: user.address,
          role: user.role,
          createdAt: user.created_at
        }
      });

    } catch (error) {
      console.error('Upload profile image error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  return router;
};
