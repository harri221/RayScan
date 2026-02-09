const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();

// Chat and messaging API routes
module.exports = (db, io) => {

  // Configure multer for file uploads (chat attachments)
  const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      const uploadPath = path.join(process.env.UPLOAD_PATH || 'uploads/', 'chat');
      if (!fs.existsSync(uploadPath)) {
        fs.mkdirSync(uploadPath, { recursive: true });
      }
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, `chat-${uniqueSuffix}${path.extname(file.originalname)}`);
    }
  });

  const upload = multer({
    storage: storage,
    limits: {
      fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10485760 // 10MB
    },
    fileFilter: (req, file, cb) => {
      // Allow images, audio, and documents
      const allowedTypes = /jpeg|jpg|png|gif|mp3|wav|m4a|pdf|doc|docx/;
      const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
      const mimetype = allowedTypes.test(file.mimetype);

      if (mimetype && extname) {
        return cb(null, true);
      } else {
        cb(new Error('Invalid file type'));
      }
    }
  });

  // 1. CREATE OR GET CONVERSATION
  router.post('/conversations', async (req, res) => {
    try {
      const { doctorId, type = 'consultation' } = req.body;

      // Validation
      if (!doctorId) {
        return res.status(400).json({ error: 'Doctor ID is required' });
      }

      // Check if doctor exists and get user_id (PostgreSQL)
      const doctors = await db.query(
        'SELECT id, user_id FROM doctors WHERE id = $1',
        [doctorId]
      );

      if (doctors.rows.length === 0) {
        return res.status(404).json({ error: 'Doctor not found or not available' });
      }

      const doctorUserId = doctors.rows[0].user_id;

      // Check if conversation already exists
      const existingConversations = await db.query(
        'SELECT id FROM conversations WHERE user_id = $1 AND doctor_id = $2 AND status = $3',
        [req.user.id, doctorId, 'active']
      );

      let conversationId;

      if (existingConversations.rows.length > 0) {
        conversationId = existingConversations.rows[0].id;
      } else {
        // Create new conversation with both doctor_id and doctor_user_id
        const result = await db.query(
          'INSERT INTO conversations (user_id, doctor_id, doctor_user_id, type) VALUES ($1, $2, $3, $4) RETURNING id',
          [req.user.id, doctorId, doctorUserId, type]
        );
        conversationId = result.rows[0].id;
      }

      // Get conversation details
      const conversations = await db.query(
        `SELECT
          c.*,
          d.full_name as doctor_name,
          d.specialization as doctor_specialty,
          d.profile_image_url as doctor_image,
          u.full_name as user_name
         FROM conversations c
         JOIN doctors d ON c.doctor_id = d.id
         JOIN users u ON c.user_id = u.id
         WHERE c.id = $1`,
        [conversationId]
      );

      const conversation = conversations.rows[0];

      res.json({
        conversation: {
          id: conversation.id,
          userId: conversation.user_id,
          userName: conversation.user_name,
          doctorId: conversation.doctor_id,
          doctorName: conversation.doctor_name,
          doctorSpecialty: conversation.doctor_specialty,
          doctorImage: conversation.doctor_image,
          type: conversation.type,
          status: conversation.status,
          createdAt: conversation.created_at,
          updatedAt: conversation.updated_at
        }
      });

    } catch (error) {
      console.error('Create conversation error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 2. GET USER CONVERSATIONS
  router.get('/conversations', async (req, res) => {
    try {
      const conversations = await db.query(
        `SELECT
          c.*,
          d.id as doctor_id,
          d.full_name as doctor_name,
          d.specialization as doctor_specialty,
          d.profile_image_url as doctor_image,
          (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message,
          (SELECT created_at FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message_time,
          (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND sender_type = 'doctor' AND is_read = FALSE) as unread_count
         FROM conversations c
         JOIN doctors d ON c.doctor_id = d.id
         WHERE c.user_id = $1
         ORDER BY c.updated_at DESC`,
        [req.user.id]
      );

      res.json({
        conversations: conversations.rows.map(conversation => ({
          id: conversation.id,
          doctor: {
            id: conversation.doctor_id,
            name: conversation.doctor_name,
            specialization: conversation.doctor_specialty,
            profileImage: conversation.doctor_image
          },
          lastMessage: conversation.last_message ? {
            content: conversation.last_message,
            createdAt: conversation.last_message_time
          } : null,
          unreadCount: parseInt(conversation.unread_count) || 0,
          createdAt: conversation.created_at,
          updatedAt: conversation.updated_at
        }))
      });

    } catch (error) {
      console.error('Get conversations error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 2b. GET DOCTOR CONVERSATIONS
  router.get('/doctor/conversations', async (req, res) => {
    try {
      // req.user.id is the doctor's USER ID, need to match with doctor_user_id
      const conversations = await db.query(
        `SELECT
          c.*,
          u.id as user_id,
          u.full_name as user_name,
          u.profile_image as user_image,
          (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message,
          (SELECT created_at FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message_time,
          (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND sender_type = 'user' AND is_read = FALSE) as unread_count
         FROM conversations c
         JOIN users u ON c.user_id = u.id
         WHERE c.doctor_user_id = $1
         ORDER BY c.updated_at DESC`,
        [req.user.id]
      );

      res.json({
        conversations: conversations.rows.map(conversation => ({
          id: conversation.id,
          doctor: {
            id: req.user.id,
            name: req.user.name || 'Doctor',
            specialization: req.user.specialization || '',
            profileImage: req.user.profile_image_url || null
          },
          patient: {
            id: conversation.user_id,
            name: conversation.user_name,
            profileImage: conversation.user_image
          },
          lastMessage: conversation.last_message ? {
            content: conversation.last_message,
            createdAt: conversation.last_message_time
          } : null,
          unreadCount: parseInt(conversation.unread_count) || 0,
          createdAt: conversation.created_at,
          updatedAt: conversation.updated_at
        }))
      });

    } catch (error) {
      console.error('Get doctor conversations error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 3. GET CONVERSATION MESSAGES (works for both patient and doctor)
  router.get('/conversations/:conversationId/messages', async (req, res) => {
    try {
      const { conversationId } = req.params;
      const { page = 1, limit = 50 } = req.query;

      // Check if user has access to this conversation (as patient OR doctor)
      // For doctors, match against doctor_user_id instead of doctor_id
      const conversations = await db.query(
        'SELECT id, user_id, doctor_id, doctor_user_id FROM conversations WHERE id = $1 AND (user_id = $2 OR doctor_user_id = $2)',
        [conversationId, req.user.id]
      );

      if (conversations.rows.length === 0) {
        return res.status(404).json({ error: 'Conversation not found' });
      }

      const conversation = conversations.rows[0];
      const isDoctor = conversation.doctor_user_id === req.user.id;

      // Get messages with pagination
      const offset = (page - 1) * limit;
      const messages = await db.query(
        `SELECT * FROM messages
         WHERE conversation_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3`,
        [conversationId, parseInt(limit), offset]
      );

      // Mark messages as read based on user type
      const markReadType = isDoctor ? 'user' : 'doctor';
      await db.query(
        'UPDATE messages SET is_read = TRUE WHERE conversation_id = $1 AND sender_type = $2',
        [conversationId, markReadType]
      );

      res.json({
        messages: messages.rows.map(message => ({
          id: message.id,
          conversationId: message.conversation_id,
          senderId: message.sender_id,
          senderType: message.sender_type,
          messageType: message.message_type,
          content: message.content,
          fileUrl: message.file_url,
          isRead: message.is_read,
          createdAt: message.created_at
        })),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          hasMore: messages.rows.length === parseInt(limit)
        }
      });

    } catch (error) {
      console.error('Get messages error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 4. SEND MESSAGE (works for both patient and doctor)
  router.post('/conversations/:conversationId/messages', async (req, res) => {
    try {
      const { conversationId } = req.params;
      const { content, messageType = 'text' } = req.body;

      // Check if user has access to this conversation (as patient OR doctor)
      // For doctors, match against doctor_user_id
      const conversations = await db.query(
        `SELECT c.*,
                d.full_name as doctor_name,
                u.full_name as user_name
         FROM conversations c
         JOIN doctors d ON c.doctor_id = d.id
         JOIN users u ON c.user_id = u.id
         WHERE c.id = $1 AND (c.user_id = $2 OR c.doctor_user_id = $2)`,
        [conversationId, req.user.id]
      );

      if (conversations.rows.length === 0) {
        return res.status(404).json({ error: 'Conversation not found' });
      }

      const conversation = conversations.rows[0];

      if (conversation.status === 'closed') {
        return res.status(400).json({ error: 'Cannot send message to closed conversation' });
      }

      // Validation
      if (!content && messageType === 'text') {
        return res.status(400).json({ error: 'Message content is required' });
      }

      // Determine sender type - check against doctor_user_id
      const isDoctor = conversation.doctor_user_id === req.user.id;
      const senderType = isDoctor ? 'doctor' : 'user';

      // Insert message
      const result = await db.query(
        `INSERT INTO messages (conversation_id, sender_id, sender_type, message_type, content)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [conversationId, req.user.id, senderType, messageType, content]
      );

      // Update conversation timestamp
      await db.query(
        'UPDATE conversations SET updated_at = NOW() WHERE id = $1',
        [conversationId]
      );

      // Get the inserted message
      const message = result.rows[0];
      const messageData = {
        id: message.id,
        conversationId: message.conversation_id,
        senderId: message.sender_id,
        senderType: message.sender_type,
        messageType: message.message_type,
        content: message.content,
        fileUrl: message.file_url,
        isRead: message.is_read,
        createdAt: message.created_at
      };

      // Emit real-time message via Socket.io
      if (io) {
        const messagePayload = {
          ...messageData,
          senderName: isDoctor ? conversation.doctor_name : conversation.user_name,
          conversationId: conversationId
        };

        // Emit to conversation room
        io.to(`conversation_${conversationId}`).emit('new_message', messagePayload);

        // ALSO emit to individual user rooms to ensure delivery
        // Emit to patient's room
        io.to(`user_${conversation.user_id}`).emit('new_message', messagePayload);
        // Emit to doctor's room
        io.to(`doctor_${conversation.doctor_user_id}`).emit('new_message', messagePayload);

        console.log(`📨 Message emitted to conversation_${conversationId}, user_${conversation.user_id}, doctor_${conversation.doctor_user_id}`);
      }

      res.status(201).json({
        message: 'Message sent successfully',
        data: messageData
      });

    } catch (error) {
      console.error('Send message error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 5. SEND MESSAGE WITH FILE ATTACHMENT
  router.post('/conversations/:conversationId/messages/file', upload.single('file'), async (req, res) => {
    try {
      const { conversationId } = req.params;
      const { messageType = 'image' } = req.body;

      if (!req.file) {
        return res.status(400).json({ error: 'File is required' });
      }

      // Check if user has access to this conversation
      const conversations = await db.query(
        `SELECT c.*, d.full_name as doctor_name FROM conversations c
         JOIN doctors d ON c.doctor_id = d.id
         WHERE c.id = $1 AND c.user_id = $2`,
        [conversationId, req.user.id]
      );

      if (conversations.rows.length === 0) {
        return res.status(404).json({ error: 'Conversation not found' });
      }

      const conversation = conversations.rows[0];

      if (conversation.status === 'closed') {
        return res.status(400).json({ error: 'Cannot send message to closed conversation' });
      }

      const fileUrl = `/uploads/chat/${req.file.filename}`;

      // Insert message with file
      const result = await db.query(
        `INSERT INTO messages (conversation_id, sender_id, sender_type, message_type, content, file_url)
         VALUES ($1, $2, 'user', $3, $4, $5) RETURNING *`,
        [conversationId, req.user.id, messageType, req.file.originalname, fileUrl]
      );

      // Update conversation timestamp
      await db.query(
        'UPDATE conversations SET updated_at = NOW() WHERE id = $1',
        [conversationId]
      );

      // Get the inserted message
      const message = result.rows[0];
      const messageData = {
        id: message.id,
        conversationId: message.conversation_id,
        senderId: message.sender_id,
        senderType: message.sender_type,
        messageType: message.message_type,
        content: message.content,
        fileUrl: message.file_url,
        isRead: message.is_read,
        createdAt: message.created_at
      };

      // Emit real-time message via Socket.io
      if (io) {
        io.to(`doctor_${conversation.doctor_id}`).emit('new_message', {
          ...messageData,
          userName: req.user.name,
          conversationId: conversationId
        });
      }

      res.status(201).json({
        message: 'File message sent successfully',
        data: messageData
      });

    } catch (error) {
      console.error('Send file message error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 6. CLOSE CONVERSATION
  router.put('/conversations/:conversationId/close', async (req, res) => {
    try {
      const { conversationId } = req.params;

      // Check if user has access to this conversation
      const conversations = await db.query(
        'SELECT id FROM conversations WHERE id = $1 AND user_id = $2',
        [conversationId, req.user.id]
      );

      if (conversations.rows.length === 0) {
        return res.status(404).json({ error: 'Conversation not found' });
      }

      // Close conversation
      await db.query(
        'UPDATE conversations SET status = $1, updated_at = NOW() WHERE id = $2',
        ['closed', conversationId]
      );

      res.json({
        message: 'Conversation closed successfully'
      });

    } catch (error) {
      console.error('Close conversation error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 7. GET UNREAD MESSAGE COUNT
  router.get('/unread-count', async (req, res) => {
    try {
      const result = await db.query(
        `SELECT COUNT(*) as unread_count
         FROM messages m
         JOIN conversations c ON m.conversation_id = c.id
         WHERE c.user_id = $1 AND m.sender_type = $2 AND m.is_read = FALSE`,
        [req.user.id, 'doctor']
      );

      res.json({
        unreadCount: result.rows[0].unread_count
      });

    } catch (error) {
      console.error('Get unread count error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 8. GET DOCTOR'S CONVERSATIONS (Doctor-side view of all patient conversations)
  router.get('/doctor/conversations-detailed', async (req, res) => {
    try {
      // Get all conversations where this doctor is involved
      // Use doctor_user_id to match against req.user.id
      const conversationsResult = await db.query(
        `SELECT
          c.id,
          c.user_id as "userId",
          c.doctor_id as "doctorId",
          c.type,
          c.status,
          c.created_at as "createdAt",
          c.updated_at as "updatedAt",
          u.full_name as "patientName",
          u.email as "patientEmail",
          u.phone as "patientPhone",
          u.profile_image as "patientImage"
         FROM conversations c
         LEFT JOIN users u ON c.user_id = u.id
         WHERE c.doctor_user_id = $1
         ORDER BY c.updated_at DESC`,
        [req.user.id]
      );

      // For each conversation, get the last message and unread count
      const conversations = await Promise.all(
        conversationsResult.rows.map(async (conv) => {
          // Get last message
          const lastMessageResult = await db.query(
            `SELECT content, sender_type, created_at
             FROM messages
             WHERE conversation_id = $1
             ORDER BY created_at DESC
             LIMIT 1`,
            [conv.id]
          );

          // Get unread count (messages from patient that doctor hasn't read)
          const unreadResult = await db.query(
            `SELECT COUNT(*) as count
             FROM messages
             WHERE conversation_id = $1
             AND sender_type = 'user'
             AND is_read = FALSE`,
            [conv.id]
          );

          return {
            id: conv.id,
            userId: conv.userId,
            doctorId: conv.doctorId,
            type: conv.type,
            status: conv.status,
            createdAt: conv.createdAt,
            updatedAt: conv.updatedAt,
            patient: {
              id: conv.userId,
              name: conv.patientName,
              email: conv.patientEmail,
              phone: conv.patientPhone,
              profileImage: conv.patientImage
            },
            lastMessage: lastMessageResult.rows.length > 0
              ? {
                  content: lastMessageResult.rows[0].content,
                  senderType: lastMessageResult.rows[0].sender_type,
                  createdAt: lastMessageResult.rows[0].created_at
                }
              : null,
            unreadCount: parseInt(unreadResult.rows[0].count)
          };
        })
      );

      res.json({
        conversations: conversations
      });

    } catch (error) {
      console.error('Get doctor conversations error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 9. GET MISSED CALLS (for both patients and doctors)
  router.get('/calls/missed', async (req, res) => {
    try {
      const result = await db.query(
        `SELECT
          cl.*,
          caller.full_name as caller_name,
          receiver.full_name as receiver_name
         FROM call_logs cl
         JOIN users caller ON cl.caller_user_id = caller.id
         JOIN users receiver ON cl.receiver_user_id = receiver.id
         WHERE (cl.receiver_user_id = $1 AND cl.status = 'missed')
         ORDER BY cl.created_at DESC
         LIMIT 50`,
        [req.user.id]
      );

      res.json({
        missedCalls: result.rows.map(call => ({
          id: call.id,
          conversationId: call.conversation_id,
          callerId: call.caller_user_id,
          callerName: call.caller_name,
          receiverId: call.receiver_user_id,
          receiverName: call.receiver_name,
          callType: call.call_type,
          status: call.status,
          channelName: call.channel_name,
          duration: call.duration,
          startedAt: call.started_at,
          endedAt: call.ended_at,
          createdAt: call.created_at
        }))
      });

    } catch (error) {
      console.error('Get missed calls error:', error);
      res.status(500).json({ error: 'Failed to fetch missed calls' });
    }
  });

  // 10. GET MISSED CALLS COUNT
  router.get('/calls/missed/count', async (req, res) => {
    try {
      const result = await db.query(
        `SELECT COUNT(*) as count
         FROM call_logs
         WHERE receiver_user_id = $1 AND status = 'missed'`,
        [req.user.id]
      );

      res.json({
        count: parseInt(result.rows[0].count) || 0
      });

    } catch (error) {
      console.error('Get missed calls count error:', error);
      res.status(500).json({ error: 'Failed to fetch missed calls count' });
    }
  });

  // 11. GET CALL HISTORY (all calls for the current user)
  router.get('/calls/history', async (req, res) => {
    try {
      const { page = 1, limit = 50 } = req.query;
      const offset = (page - 1) * limit;

      const result = await db.query(
        `SELECT
          cl.*,
          caller.full_name as caller_name,
          receiver.full_name as receiver_name,
          CASE
            WHEN cl.caller_user_id = $1 THEN 'outgoing'
            ELSE 'incoming'
          END as call_direction
         FROM call_logs cl
         JOIN users caller ON cl.caller_user_id = caller.id
         JOIN users receiver ON cl.receiver_user_id = receiver.id
         WHERE (cl.caller_user_id = $1 OR cl.receiver_user_id = $1)
         ORDER BY cl.created_at DESC
         LIMIT $2 OFFSET $3`,
        [req.user.id, parseInt(limit), offset]
      );

      res.json({
        callHistory: result.rows.map(call => ({
          id: call.id,
          conversationId: call.conversation_id,
          callerId: call.caller_user_id,
          callerName: call.caller_name,
          receiverId: call.receiver_user_id,
          receiverName: call.receiver_name,
          callType: call.call_type,
          status: call.status,
          direction: call.call_direction,
          channelName: call.channel_name,
          duration: call.duration,
          startedAt: call.started_at,
          endedAt: call.ended_at,
          createdAt: call.created_at
        })),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          hasMore: result.rows.length === parseInt(limit)
        }
      });

    } catch (error) {
      console.error('Get call history error:', error);
      res.status(500).json({ error: 'Failed to fetch call history' });
    }
  });

  // 12. MARK MISSED CALLS AS SEEN
  router.put('/calls/missed/mark-seen', async (req, res) => {
    try {
      const { callIds } = req.body;

      if (!callIds || !Array.isArray(callIds) || callIds.length === 0) {
        return res.status(400).json({ error: 'callIds array is required' });
      }

      // Update status from 'missed' to 'seen_missed' or add a 'seen' flag
      await db.query(
        `UPDATE call_logs
         SET updated_at = NOW()
         WHERE id = ANY($1::int[]) AND receiver_user_id = $2`,
        [callIds, req.user.id]
      );

      res.json({
        message: 'Missed calls marked as seen',
        count: callIds.length
      });

    } catch (error) {
      console.error('Mark missed calls as seen error:', error);
      res.status(500).json({ error: 'Failed to mark missed calls as seen' });
    }
  });

  return router;
};