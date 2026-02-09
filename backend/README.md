# RayScan Backend API

Complete Node.js backend for the RayScan Healthcare Flutter application with MySQL database, JWT authentication, and Socket.io for real-time features.

## 🚀 Features

- **Authentication System**: JWT-based login, signup, forgot password with email/SMS verification
- **Doctor Management**: Doctor listings, search, specialties, availability checking
- **Appointment Booking**: Create, view, cancel, reschedule appointments with payment tracking
- **Real-time Chat**: Socket.io powered messaging between users and doctors
- **File Upload**: Ultrasound image upload with mock AI analysis
- **Pharmacy Finder**: Location-based pharmacy search with product availability
- **Security**: Helmet, CORS, rate limiting, password hashing

## 📋 Prerequisites

- Node.js (v16 or higher)
- MySQL/XAMPP
- npm or yarn

## 🔧 Installation & Setup

### 1. Database Setup
1. Start XAMPP and ensure MySQL is running
2. Open phpMyAdmin (http://localhost/phpmyadmin)
3. Import the database schema:
   ```sql
   -- Execute the contents of database/schema.sql
   ```

### 2. Environment Configuration
1. Copy `.env.example` to `.env` (if exists) or use the existing `.env` file
2. Update database credentials:
   ```
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=
   DB_NAME=rayscan_db
   DB_PORT=3306
   ```

### 3. Install Dependencies
```bash
cd backend
npm install
```

### 4. Start the Server
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

The server will start on http://localhost:3000

## 📡 API Endpoints

### Authentication (`/api/auth/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/signup` | Create new user account |
| POST | `/login` | User login |
| POST | `/forgot-password` | Request password reset code |
| POST | `/verify-reset-code` | Verify password reset code |
| POST | `/reset-password` | Reset password with token |

### User Profile (`/api/user/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/profile` | Get user profile |

### Doctors (`/api/doctors/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get all doctors (with filters) |
| GET | `/:id` | Get doctor details |
| GET | `/specialties/list` | Get all specialties |
| GET | `/search/:query` | Search doctors |
| GET | `/:id/availability/:date` | Get doctor availability for date |

### Appointments (`/api/appointments/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/` | Book new appointment |
| GET | `/` | Get user appointments |
| GET | `/:id` | Get appointment details |
| PUT | `/:id/cancel` | Cancel appointment |
| PUT | `/:id/reschedule` | Reschedule appointment |
| PUT | `/:id/payment` | Update payment status |

### Chat & Messaging (`/api/chat/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/conversations` | Create/get conversation |
| GET | `/conversations` | Get user conversations |
| GET | `/conversations/:id/messages` | Get conversation messages |
| POST | `/conversations/:id/messages` | Send message |
| POST | `/conversations/:id/messages/file` | Send file message |
| PUT | `/conversations/:id/close` | Close conversation |
| GET | `/unread-count` | Get unread message count |

### Ultrasound Reports (`/api/reports/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/upload` | Upload ultrasound image |
| GET | `/` | Get user reports |
| GET | `/:id` | Get report details |
| DELETE | `/:id` | Delete report |
| GET | `/stats/summary` | Get report statistics |

### Pharmacy (`/api/pharmacy/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get pharmacies (location-based) |
| GET | `/:id` | Get pharmacy details |
| GET | `/search/:query` | Search pharmacies |
| GET | `/:id/products` | Get pharmacy products |
| GET | `/products/search/:query` | Search products across pharmacies |
| GET | `/categories/list` | Get product categories |
| GET | `/nearby-with-product/:name` | Find nearby pharmacies with product |

## 🔌 Socket.io Events

### Client to Server
- `authenticate`: Authenticate user for real-time features
- `join_conversation`: Join conversation room
- `leave_conversation`: Leave conversation room
- `typing_start`: Start typing indicator
- `typing_stop`: Stop typing indicator
- `call_request`: Request video/audio call
- `call_response`: Respond to call request

### Server to Client
- `new_message`: New message received
- `user_typing`: User started typing
- `user_stop_typing`: User stopped typing
- `incoming_call`: Incoming call notification
- `call_response`: Call response (accepted/declined)

## 📝 Request/Response Examples

### Authentication

**POST /api/auth/signup**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "password123",
  "dateOfBirth": "1990-01-01",
  "gender": "male",
  "address": "123 Main St"
}
```

**POST /api/auth/login**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

### Booking Appointment

**POST /api/appointments/**
```json
{
  "doctorId": 1,
  "appointmentDate": "2024-01-15",
  "appointmentTime": "14:00",
  "reason": "Regular checkup"
}
```

### Sending Message

**POST /api/chat/conversations/1/messages**
```json
{
  "content": "Hello doctor, I have a question about my test results",
  "messageType": "text"
}
```

### Uploading Ultrasound

**POST /api/reports/upload** (multipart/form-data)
```
ultrasound: [image file]
scanType: "kidney"
```

## 🔐 Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

## 📱 Frontend Integration

To connect your Flutter app to this backend:

1. Update the base URL in your Flutter HTTP client
2. Implement JWT token storage and management
3. Add Socket.io client for real-time features
4. Handle file uploads for ultrasound images

## 🗄️ Database Schema

The MySQL database includes these main tables:
- `users` - User accounts and profiles
- `doctors` - Doctor information and ratings
- `doctor_availability` - Doctor scheduling
- `appointments` - Appointment booking and status
- `conversations` - Chat conversations
- `messages` - Chat messages
- `ultrasound_reports` - Ultrasound scans and AI analysis
- `pharmacies` - Pharmacy locations
- `pharmacy_products` - Pharmacy inventory
- `password_reset_tokens` - Password reset verification
- `user_health_metrics` - User health data
- `notifications` - User notifications

## 🚀 Deployment

For production deployment:

1. Set `NODE_ENV=production`
2. Use a proper secret key for `JWT_SECRET`
3. Configure email service for password reset
4. Set up proper CORS origins
5. Use a reverse proxy (nginx)
6. Enable SSL/HTTPS

## 📊 Health Check

Visit http://localhost:3000/api/health to check if the API is running.

## 🛠️ Development

- File uploads are stored in `uploads/` directory
- Mock AI analysis is generated for ultrasound reports
- Socket.io rooms are used for real-time chat
- Rate limiting is applied to prevent abuse

## 🔧 Troubleshooting

1. **Database Connection Issues**: Check XAMPP MySQL service is running
2. **CORS Errors**: Update `SOCKET_CORS_ORIGIN` in .env file
3. **File Upload Errors**: Ensure uploads directory has write permissions
4. **JWT Errors**: Verify `JWT_SECRET` is set properly

## 📞 Support

This backend is designed to work seamlessly with the RayScan Flutter application. All endpoints follow RESTful conventions and include proper error handling.