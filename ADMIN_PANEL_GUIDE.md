# Admin Panel Setup & Usage Guide

## Quick Start

### Method 1: Using Startup Script (EASIEST)

1. **Make sure backend is running** (should already be running)
2. **Double-click**: `START_ADMIN_PANEL.bat`
3. **Wait** for it to compile (takes ~10-15 seconds first time)
4. **Open browser**: http://localhost:5173
5. **Login with**:
   - Username: `admin`
   - Password: `admin123`

### Method 2: Manual Start

```bash
# Navigate to admin portal folder
cd med-admin-vista-main\med-admin-vista-main

# Start dev server
npm run dev
```

Then open: http://localhost:5173

---

## Admin Panel Features

### 1. Dashboard
- **Stats Overview**:
  - Total Doctors (real data from database)
  - Total Patients (real data from database)
  - Scans Completed (real data from database)
  - Today's Appointments (real data from database)

- **Recent Activities Feed**: Shows latest doctor registrations and appointments

- **Quick Stats**: Pending verifications, system health, etc.

### 2. Doctors Management
- View all registered doctors
- Filter by status:
  - **All** - Show all doctors
  - **Pending** - Doctors awaiting verification
  - **Verified** - Approved doctors
  - **Rejected** - Rejected applications

- **Actions**:
  - ✅ Accept (verify) doctor
  - ❌ Reject doctor
  - 🔍 Check PMDC (opens external verification site)

### 3. Patients Management
- View all registered patients
- Search by name or email
- View patient statistics
- Filter by status (Active/Inactive)

---

## Login Credentials

**Default Admin Account**:
- Username: `admin`
- Password: `admin123`

**IMPORTANT**: Change these in production!

---

## API Endpoints Being Used

The admin panel connects to your backend at `http://localhost:3002/api`

### Authentication
- `POST /api/admin/auth/login` - Admin login

### Dashboard
- `GET /api/admin/stats` - Dashboard statistics
- `GET /api/admin/activities` - Recent activities
- `GET /api/admin/quick-stats` - Quick stats panel

### Doctors
- `GET /api/admin/doctors?status=Pending` - List doctors
- `PATCH /api/admin/doctors/:id/status` - Verify/Reject doctor

### Patients
- `GET /api/admin/patients?search=John` - List/search patients
- `GET /api/admin/patients/stats` - Patient statistics

---

## Testing the Integration

### Test 1: Login
1. Open http://localhost:5173
2. Should see login page
3. Enter: admin / admin123
4. Should redirect to dashboard

### Test 2: View Real Data
1. Dashboard should show actual counts from your database
2. Check if numbers match what's in your database

### Test 3: Doctor Management
1. Go to "Doctors" page (left sidebar)
2. Filter by "Pending"
3. Click "Accept" on a pending doctor
4. Check database to verify `is_verified = true`

### Test 4: Patient Search
1. Go to "Patients" page
2. Use search box to find a patient
3. Should filter results in real-time

---

## Troubleshooting

### Problem: Can't access http://localhost:5173
**Solution**: Admin panel not started. Run `START_ADMIN_PANEL.bat`

### Problem: "Network Error" or "Connection Refused"
**Solution**: Backend not running. Start backend first:
```bash
cd backend
node server.js
```

### Problem: Login doesn't work
**Solution**: Check browser console (F12) for errors. Verify backend is on port 3002.

### Problem: Dashboard shows 0 for everything
**Solution**:
1. Check backend logs for errors
2. Verify database has data
3. Check browser console (F12) for API errors

### Problem: CORS errors in browser console
**Solution**: Backend already configured for localhost:5173, but if you see CORS errors, check `backend/server.js` CORS configuration.

---

## Current Status

✅ **Backend API**: Fully integrated with PostgreSQL database
✅ **Frontend Setup**: React + TypeScript + Vite ready
✅ **API Client**: Axios configured with auth interceptors
✅ **Frontend Pages**: All pages now using real backend data!

---

## What's Working Now

All admin panel features are fully integrated with your PostgreSQL database:

1. **Login (AuthContext.tsx)** - Real authentication via `/api/admin/auth/login`
   - Stores JWT token in localStorage
   - Auto-redirects on 401 errors
   - Persists login session

2. **Dashboard (Dashboard.tsx)** - Real-time statistics
   - Total doctors/patients/scans from database
   - Recent activities feed
   - Quick stats panel with pending verifications
   - All data fetched from backend APIs

3. **Doctors Management (Doctors.tsx)** - Full CRUD operations
   - Fetches real doctors from database
   - Filter by status (All/Pending/Verified/Rejected)
   - Accept/Reject doctor verification
   - Updates database in real-time
   - PMDC verification link

4. **Patients Management (Patients.tsx)** - Complete patient data
   - Real patient list from database
   - Live search with 500ms debounce
   - Patient statistics (total, active, new this month)
   - All data from backend APIs

---

## Architecture

```
Admin Panel (Port 5173)
    ↓
API Calls (axios)
    ↓
Backend (Port 3002)
    ↓
PostgreSQL Database
```

---

## Ports Summary

- **Flutter App**: Uses Android emulator (10.0.2.2:3002)
- **Backend API**: http://localhost:3002
- **Admin Panel**: http://localhost:5173

---

## Support

If you encounter issues:
1. Check backend is running: http://localhost:3002/api/health
2. Check browser console (F12) for errors
3. Check backend terminal for error logs
4. Verify database connection is working

**Ready to test!** 🎉

Just run `START_ADMIN_PANEL.bat` and open http://localhost:5173
