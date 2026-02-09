const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();

// Ultrasound reports API routes
module.exports = (db) => {

  // Configure multer for ultrasound image uploads
  const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      const uploadPath = path.join(process.env.UPLOAD_PATH || 'uploads/', 'ultrasound');
      if (!fs.existsSync(uploadPath)) {
        fs.mkdirSync(uploadPath, { recursive: true });
      }
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, `ultrasound-${req.user.id}-${uniqueSuffix}${path.extname(file.originalname)}`);
    }
  });

  const upload = multer({
    storage: storage,
    limits: {
      fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10485760 // 10MB
    },
    fileFilter: (req, file, cb) => {
      // Only allow image files
      const allowedTypes = /jpeg|jpg|png|gif|bmp|tiff/;
      const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
      const mimetype = allowedTypes.test(file.mimetype);

      if (mimetype && extname) {
        return cb(null, true);
      } else {
        cb(new Error('Only image files are allowed for ultrasound scans'));
      }
    }
  });

  // 1. UPLOAD ULTRASOUND SCAN
  router.post('/upload', upload.single('ultrasound'), async (req, res) => {
    try {
      const { scanType } = req.body;

      // Validation
      if (!req.file) {
        return res.status(400).json({ error: 'Ultrasound image is required' });
      }

      if (!scanType || !['kidney', 'breast'].includes(scanType)) {
        return res.status(400).json({ error: 'Valid scan type (kidney or breast) is required' });
      }

      const imageUrl = `/uploads/ultrasound/${req.file.filename}`;

      // Create ultrasound report record
      const [result] = await db.execute(
        `INSERT INTO ultrasound_reports (user_id, scan_type, image_url, status)
         VALUES (?, ?, ?, 'processing')`,
        [req.user.id, scanType, imageUrl]
      );

      // Simulate AI analysis (in production, this would call actual AI service)
      setTimeout(async () => {
        try {
          const mockAnalysis = generateMockAIAnalysis(scanType);

          await db.execute(
            `UPDATE ultrasound_reports
             SET ai_analysis = ?, result = ?, confidence_score = ?, status = 'completed'
             WHERE id = ?`,
            [mockAnalysis.analysis, mockAnalysis.result, mockAnalysis.confidence, result.insertId]
          );

          // If abnormal result detected, recommend a doctor
          if (mockAnalysis.result === 'abnormal' || mockAnalysis.result === 'detected') {
            const specialty = scanType === 'kidney' ? 'Urologist' : 'Radiologist';
            const [doctors] = await db.execute(
              'SELECT id FROM doctors WHERE specialty = ? AND is_available = TRUE ORDER BY rating DESC LIMIT 1',
              [specialty]
            );

            if (doctors.length > 0) {
              await db.execute(
                'UPDATE ultrasound_reports SET recommended_doctor_id = ? WHERE id = ?',
                [doctors[0].id, result.insertId]
              );
            }
          }

        } catch (error) {
          console.error('AI analysis error:', error);
          await db.execute(
            'UPDATE ultrasound_reports SET status = "failed" WHERE id = ?',
            [result.insertId]
          );
        }
      }, 3000); // 3 second delay to simulate processing

      res.status(201).json({
        message: 'Ultrasound scan uploaded successfully',
        reportId: result.insertId,
        status: 'processing'
      });

    } catch (error) {
      console.error('Upload ultrasound error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 2. GET USER REPORTS
  router.get('/', async (req, res) => {
    try {
      const { scanType, status } = req.query;

      let query = `
        SELECT
          ur.*,
          d.name as recommended_doctor_name,
          d.specialty as recommended_doctor_specialty,
          d.profile_image as recommended_doctor_image
        FROM ultrasound_reports ur
        LEFT JOIN doctors d ON ur.recommended_doctor_id = d.id
        WHERE ur.user_id = ?
      `;
      const params = [req.user.id];

      if (scanType) {
        query += ' AND ur.scan_type = ?';
        params.push(scanType);
      }

      if (status) {
        query += ' AND ur.status = ?';
        params.push(status);
      }

      query += ' ORDER BY ur.created_at DESC';

      const [reports] = await db.execute(query, params);

      res.json({
        reports: reports.map(report => ({
          id: report.id,
          userId: report.user_id,
          scanType: report.scan_type,
          imageUrl: report.image_url,
          aiAnalysis: report.ai_analysis,
          result: report.result,
          confidenceScore: report.confidence_score ? parseFloat(report.confidence_score) : null,
          status: report.status,
          recommendedDoctor: report.recommended_doctor_id ? {
            id: report.recommended_doctor_id,
            name: report.recommended_doctor_name,
            specialty: report.recommended_doctor_specialty,
            profileImage: report.recommended_doctor_image
          } : null,
          createdAt: report.created_at,
          updatedAt: report.updated_at
        }))
      });

    } catch (error) {
      console.error('Get reports error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 3. GET REPORT BY ID
  router.get('/:id', async (req, res) => {
    try {
      const { id } = req.params;

      const [reports] = await db.execute(
        `SELECT
          ur.*,
          d.name as recommended_doctor_name,
          d.specialty as recommended_doctor_specialty,
          d.profile_image as recommended_doctor_image,
          d.phone as recommended_doctor_phone,
          d.consultation_fee as recommended_doctor_fee
         FROM ultrasound_reports ur
         LEFT JOIN doctors d ON ur.recommended_doctor_id = d.id
         WHERE ur.id = ? AND ur.user_id = ?`,
        [id, req.user.id]
      );

      if (reports.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }

      const report = reports[0];

      res.json({
        report: {
          id: report.id,
          userId: report.user_id,
          scanType: report.scan_type,
          imageUrl: report.image_url,
          aiAnalysis: report.ai_analysis,
          result: report.result,
          confidenceScore: report.confidence_score ? parseFloat(report.confidence_score) : null,
          status: report.status,
          recommendedDoctor: report.recommended_doctor_id ? {
            id: report.recommended_doctor_id,
            name: report.recommended_doctor_name,
            specialty: report.recommended_doctor_specialty,
            profileImage: report.recommended_doctor_image,
            phone: report.recommended_doctor_phone,
            consultationFee: report.recommended_doctor_fee ? parseFloat(report.recommended_doctor_fee) : null
          } : null,
          createdAt: report.created_at,
          updatedAt: report.updated_at
        }
      });

    } catch (error) {
      console.error('Get report error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 4. DELETE REPORT
  router.delete('/:id', async (req, res) => {
    try {
      const { id } = req.params;

      // Check if report exists and belongs to user
      const [reports] = await db.execute(
        'SELECT id, image_url FROM ultrasound_reports WHERE id = ? AND user_id = ?',
        [id, req.user.id]
      );

      if (reports.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }

      const report = reports[0];

      // Delete the image file
      const imagePath = path.join(process.env.UPLOAD_PATH || 'uploads/', 'ultrasound', path.basename(report.image_url));
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }

      // Delete report from database
      await db.execute(
        'DELETE FROM ultrasound_reports WHERE id = ?',
        [id]
      );

      res.json({
        message: 'Report deleted successfully'
      });

    } catch (error) {
      console.error('Delete report error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 5. GET REPORT STATISTICS
  router.get('/stats/summary', async (req, res) => {
    try {
      const [stats] = await db.execute(
        `SELECT
          COUNT(*) as total_reports,
          COUNT(CASE WHEN scan_type = 'kidney' THEN 1 END) as kidney_scans,
          COUNT(CASE WHEN scan_type = 'breast' THEN 1 END) as breast_scans,
          COUNT(CASE WHEN result = 'normal' THEN 1 END) as normal_results,
          COUNT(CASE WHEN result IN ('abnormal', 'detected') THEN 1 END) as abnormal_results,
          COUNT(CASE WHEN status = 'processing' THEN 1 END) as processing_reports
         FROM ultrasound_reports
         WHERE user_id = ?`,
        [req.user.id]
      );

      res.json({
        statistics: {
          totalReports: stats[0].total_reports,
          kidneyScans: stats[0].kidney_scans,
          breastScans: stats[0].breast_scans,
          normalResults: stats[0].normal_results,
          abnormalResults: stats[0].abnormal_results,
          processingReports: stats[0].processing_reports
        }
      });

    } catch (error) {
      console.error('Get stats error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  return router;
};

// Mock AI analysis generator (replace with actual AI service in production)
function generateMockAIAnalysis(scanType) {
  const kidneyAnalyses = [
    {
      analysis: "Kidney structure appears normal with no visible stones or abnormalities. Both kidneys are of normal size and echogenicity.",
      result: "normal",
      confidence: 0.92
    },
    {
      analysis: "Small kidney stone detected in the right kidney. Stone appears to be approximately 4mm in size. Recommend follow-up with urologist.",
      result: "detected",
      confidence: 0.87
    },
    {
      analysis: "Mild hydronephrosis observed in left kidney. Further evaluation recommended to determine underlying cause.",
      result: "abnormal",
      confidence: 0.78
    }
  ];

  const breastAnalyses = [
    {
      analysis: "Breast tissue appears normal with no visible masses or suspicious areas. Regular mammography screening recommended.",
      result: "normal",
      confidence: 0.91
    },
    {
      analysis: "Small hypoechoic mass detected in upper outer quadrant. Recommend immediate consultation with radiologist for further evaluation.",
      result: "detected",
      confidence: 0.84
    },
    {
      analysis: "Fibrocystic changes observed. Benign appearing but recommend follow-up imaging in 6 months.",
      result: "abnormal",
      confidence: 0.79
    }
  ];

  const analyses = scanType === 'kidney' ? kidneyAnalyses : breastAnalyses;
  return analyses[Math.floor(Math.random() * analyses.length)];
}