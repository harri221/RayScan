const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const axios = require('axios');
const FormData = require('form-data');

// Configure multer for ultrasound image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/ultrasound/';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'ultrasound-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|image/i;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    // Accept if EITHER extension OR mimetype matches (or if mimetype contains 'image')
    if (mimetype || extname || file.mimetype.startsWith('image/')) {
      return cb(null, true);
    } else {
      cb(new Error('Only image files (JPEG, JPG, PNG) are allowed'));
    }
  }
});

// ML Service Configuration
const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://127.0.0.1:5000';

// ML Prediction API routes
module.exports = (db) => {

  // 1. PREDICT KIDNEY STONE FROM ULTRASOUND IMAGE
  router.post('/predict/kidney-stone', upload.single('image'), async (req, res) => {
    let imagePath = null;

    try {
      const userId = req.user.id;

      if (!req.file) {
        return res.status(400).json({ error: 'No image file uploaded' });
      }

      imagePath = req.file.path;

      console.log(`Processing kidney stone prediction for user ${userId}`);
      console.log(`Image saved at: ${imagePath}`);

      // Call ML service
      console.log(`Calling ML service at ${ML_SERVICE_URL}/predict`);
      const formData = new FormData();
      formData.append('image', fs.createReadStream(imagePath));

      let mlResponse;
      try {
        mlResponse = await axios.post(`${ML_SERVICE_URL}/predict`, formData, {
          headers: {
            ...formData.getHeaders()
          },
          timeout: 60000 // 60 second timeout (increased for slow predictions)
        });
        console.log('ML service responded successfully');
      } catch (mlError) {
        console.error('ML service error:', mlError.message);
        throw new Error(`ML service failed: ${mlError.message}`);
      }

      if (!mlResponse.data || !mlResponse.data.success) {
        console.error('Invalid ML response:', mlResponse.data);
        throw new Error('ML service returned invalid response');
      }

      const predictionData = mlResponse.data.data;
      console.log('Prediction data:', predictionData);

      // Save image URL (relative path)
      const imageUrl = `/uploads/ultrasound/${req.file.filename}`;

      // Determine result status
      const result = predictionData.has_kidney_stone ? 'detected' : 'not_detected';
      const aiAnalysis = `${predictionData.prediction}. Confidence: ${predictionData.confidence}%`;

      // Save ultrasound report to database
      const reportResult = await db.query(
        `INSERT INTO ultrasound_reports
         (user_id, scan_type, image_url, ai_analysis, result, confidence_score, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [
          userId,
          'kidney',
          imageUrl,
          aiAnalysis,
          result,
          predictionData.confidence_score,
          'completed'
        ]
      );

      const report = reportResult.rows[0];
      console.log('Report saved to database:', report);

      // Return prediction results
      console.log('Sending response to client...');
      res.json({
        success: true,
        report: {
          id: report.id,
          scanType: report.scan_type,
          imageUrl: imageUrl,
          prediction: predictionData.prediction,
          result: result,
          confidence: predictionData.confidence,
          confidenceScore: predictionData.confidence_score,
          hasKidneyStone: predictionData.has_kidney_stone,
          aiAnalysis: aiAnalysis,
          createdAt: report.created_at
        }
      });

    } catch (error) {
      console.error('Kidney stone prediction error:', error);

      // Clean up uploaded file if prediction failed
      if (imagePath && fs.existsSync(imagePath)) {
        try {
          fs.unlinkSync(imagePath);
        } catch (cleanupError) {
          console.error('Error cleaning up file:', cleanupError);
        }
      }

      // Check if error is from ML service
      if (error.code === 'ECONNREFUSED') {
        return res.status(503).json({
          error: 'ML service is not available. Please ensure the ML service is running on port 5000.'
        });
      }

      res.status(500).json({
        error: 'Failed to process ultrasound image',
        details: error.message
      });
    }
  });

  // 2. GET ULTRASOUND REPORTS FOR USER
  router.get('/reports', async (req, res) => {
    try {
      const userId = req.user.id;
      const { scanType } = req.query;

      let query = `
        SELECT
          id, scan_type, image_url, ai_analysis, result,
          confidence_score, status, created_at, updated_at
        FROM ultrasound_reports
        WHERE user_id = $1
      `;

      const params = [userId];

      if (scanType) {
        query += ' AND scan_type = $2';
        params.push(scanType);
      }

      query += ' ORDER BY created_at DESC';

      const result = await db.query(query, params);

      res.json({
        reports: result.rows.map(report => ({
          id: report.id,
          scanType: report.scan_type,
          imageUrl: report.image_url,
          aiAnalysis: report.ai_analysis,
          result: report.result,
          confidenceScore: parseFloat(report.confidence_score || 0),
          status: report.status,
          createdAt: report.created_at,
          updatedAt: report.updated_at
        }))
      });

    } catch (error) {
      console.error('Get reports error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 3. GET SINGLE REPORT DETAILS
  router.get('/reports/:id', async (req, res) => {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      const result = await db.query(
        `SELECT * FROM ultrasound_reports
         WHERE id = $1 AND user_id = $2`,
        [id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }

      const report = result.rows[0];

      res.json({
        report: {
          id: report.id,
          scanType: report.scan_type,
          imageUrl: report.image_url,
          aiAnalysis: report.ai_analysis,
          result: report.result,
          confidenceScore: parseFloat(report.confidence_score || 0),
          status: report.status,
          createdAt: report.created_at,
          updatedAt: report.updated_at
        }
      });

    } catch (error) {
      console.error('Get report details error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 4. HEALTH CHECK FOR ML SERVICE
  router.get('/ml-service/health', async (req, res) => {
    try {
      const response = await axios.get(`${ML_SERVICE_URL}/health`, {
        timeout: 5000
      });

      res.json({
        mlService: response.data,
        status: 'connected'
      });

    } catch (error) {
      res.status(503).json({
        error: 'ML service is not available',
        status: 'disconnected',
        details: error.message
      });
    }
  });

  return router;
};
