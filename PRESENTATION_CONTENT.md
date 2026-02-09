# RayScan - AI-Powered Medical Diagnostic Application
## Final Year Project Presentation

---

# Chapter 1: Introduction

## 1.1 Project Overview
RayScan is an innovative AI-powered medical diagnostic mobile application designed to assist healthcare professionals and patients in the early detection and diagnosis of kidney stones through CT scan image analysis. The application leverages cutting-edge deep learning technology to provide accurate, instant medical image analysis while facilitating seamless communication between doctors and patients.

## 1.2 Problem Statement
- Delayed diagnosis of kidney stones leads to severe complications and increased healthcare costs
- Limited access to specialist radiologists, especially in remote areas
- Long waiting times for CT scan analysis results
- Lack of integrated platforms connecting patients with urologists
- Inefficient communication channels between healthcare providers and patients

## 1.3 Proposed Solution
RayScan addresses these challenges by providing:
- **AI-Powered Diagnosis**: Instant CT scan analysis using deep learning models
- **100% Accuracy**: Highly trained MobileNetV2 model for kidney stone detection
- **Doctor-Patient Platform**: Integrated consultation and appointment booking system
- **Real-Time Communication**: Chat, voice, and video calling features
- **Nearby Services**: Location-based pharmacy finder

## 1.4 Project Objectives
1. Develop an accurate AI model for kidney stone detection from CT scan images
2. Create a user-friendly mobile application for both patients and doctors
3. Implement secure real-time communication features
4. Provide appointment scheduling and management system
5. Integrate location-based services for finding nearby pharmacies
6. Ensure data security and patient privacy

## 1.5 Scope of Project
### In Scope:
- Kidney stone detection from CT scan images
- Patient and Doctor user roles
- Appointment booking and management
- Real-time chat with file sharing
- Voice and video calling
- Nearby pharmacy locator
- User profile management
- Medical report generation

### Out of Scope:
- Detection of other medical conditions
- Integration with hospital EHR systems
- Insurance claim processing
- Prescription management

## 1.6 Target Users
1. **Patients**: Individuals seeking kidney stone diagnosis and consultation
2. **Doctors/Urologists**: Healthcare professionals providing consultations
3. **Healthcare Facilities**: Clinics and hospitals for diagnostic services

---

# Chapter 2: Functional Requirements (FRs)

## 2.1 User Authentication & Management

| FR ID | Requirement | Description |
|-------|-------------|-------------|
| FR-001 | User Registration | System shall allow patients to register with email, password, name, phone, and personal details |
| FR-002 | Doctor Registration | System shall allow doctors to register with PMDC number, specialization, qualification, and clinic details |
| FR-003 | User Login | System shall authenticate users using email and password |
| FR-004 | Password Recovery | System shall provide forgot password functionality via email verification |
| FR-005 | Role-Based Access | System shall provide different interfaces for patients and doctors |
| FR-006 | Profile Management | Users shall be able to view and update their profile information |
| FR-007 | Profile Picture Upload | Users shall be able to upload and change profile pictures |

## 2.2 AI-Powered Diagnosis

| FR ID | Requirement | Description |
|-------|-------------|-------------|
| FR-008 | CT Scan Upload | Patients shall be able to upload CT scan images for analysis |
| FR-009 | AI Analysis | System shall analyze uploaded images using trained ML model |
| FR-010 | Instant Results | System shall provide diagnosis results within seconds |
| FR-011 | Confidence Score | System shall display prediction confidence percentage |
| FR-012 | Report Generation | System shall generate downloadable medical reports |
| FR-013 | Scan History | Users shall be able to view their previous scan results |

## 2.3 Doctor Discovery & Search

| FR ID | Requirement | Description |
|-------|-------------|-------------|
| FR-014 | Doctor Listing | System shall display list of available doctors |
| FR-015 | Doctor Search | Patients shall be able to search doctors by name, specialty |
| FR-016 | Doctor Profiles | System shall display doctor details including qualification, experience, rating |
| FR-017 | Specialty Filter | Patients shall be able to filter doctors by specialization |
| FR-018 | Availability Status | System shall show real-time doctor availability |

## 2.4 Appointment Management

| FR ID | Requirement | Description |
|-------|-------------|-------------|
| FR-019 | Book Appointment | Patients shall be able to book appointments with doctors |
| FR-020 | Schedule Selection | Patients shall select date and time from doctor's available slots |
| FR-021 | Appointment Types | System shall support different consultation modes (online/in-person) |
| FR-022 | Appointment Confirmation | System shall confirm appointments and notify both parties |
| FR-023 | View Appointments | Users shall be able to view upcoming and past appointments |
| FR-024 | Cancel Appointment | Users shall be able to cancel scheduled appointments |
| FR-025 | Reschedule | Users shall be able to reschedule appointments |
| FR-026 | Doctor Schedule Management | Doctors shall be able to set their availability schedule |

## 2.5 Communication Features

| FR ID | Requirement | Description |
|-------|-------------|-------------|
| FR-027 | Real-Time Chat | System shall provide instant messaging between patients and doctors |
| FR-028 | Message History | System shall store and display chat history |
| FR-029 | Typing Indicator | System shall show when other user is typing |
| FR-030 | Online Status | System shall display user online/offline status |
| FR-031 | File Sharing | Users shall be able to share images and documents in chat |
| FR-032 | Voice Calling | System shall support audio calls between users |
| FR-033 | Video Calling | System shall support video calls for consultations |
| FR-034 | Call History | System shall maintain record of all calls |

## 2.6 Doctor Dashboard

| FR ID | Requirement | Description |
|-------|-------------|-------------|
| FR-035 | Dashboard Statistics | Doctors shall see today's appointments, total patients, earnings |
| FR-036 | Patient List | Doctors shall view list of their patients |
| FR-037 | Patient Search | Doctors shall be able to search patients by name, email, phone |
| FR-038 | Appointment Management | Doctors shall manage appointment statuses |
| FR-039 | Conversation List | Doctors shall see all patient conversations |

## 2.7 Location Services

| FR ID | Requirement | Description |
|-------|-------------|-------------|
| FR-040 | Nearby Pharmacies | System shall show pharmacies within specified radius |
| FR-041 | Pharmacy Details | System shall display pharmacy name, address, phone, distance |
| FR-042 | Map Integration | System shall show pharmacy locations on map |
| FR-043 | Distance Calculation | System shall calculate distance from user's location |

## 2.8 Additional Features

| FR ID | Requirement | Description |
|-------|-------------|-------------|
| FR-044 | Terms & Conditions | System shall display terms of service and privacy policy |
| FR-045 | Health Information | System shall provide educational health content |
| FR-046 | Notifications | System shall send push notifications for appointments and messages |
| FR-047 | Session Management | System shall handle user sessions securely |

---

# Chapter 4: Tools and Technologies

## 4.1 Frontend Development

### 4.1.1 Flutter Framework
- **Version**: 3.x (Latest Stable)
- **Language**: Dart
- **Purpose**: Cross-platform mobile application development
- **Why Chosen**:
  - Single codebase for Android and iOS
  - Hot reload for faster development
  - Rich widget library for beautiful UI
  - Strong community support

### 4.1.2 Key Flutter Packages

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.1.0 | REST API communication |
| `shared_preferences` | ^2.2.2 | Local data storage |
| `image_picker` | ^1.0.7 | Camera and gallery access |
| `file_picker` | ^8.0.0+1 | Document selection |
| `geolocator` | ^10.1.0 | GPS location services |
| `socket_io_client` | ^2.0.3+1 | Real-time communication |
| `flutter_webrtc` | ^0.12.x | Video/Voice calling |
| `permission_handler` | ^11.1.0 | Runtime permissions |
| `url_launcher` | ^6.2.2 | External URL handling |
| `intl` | ^0.19.0 | Date/time formatting |
| `path_provider` | ^2.1.1 | File system paths |

## 4.2 Backend Development

### 4.2.1 Node.js Runtime
- **Version**: 18.x LTS
- **Purpose**: Server-side JavaScript execution
- **Why Chosen**:
  - Non-blocking I/O for high performance
  - Large ecosystem of packages
  - Easy integration with real-time features

### 4.2.2 Express.js Framework
- **Version**: 4.x
- **Purpose**: RESTful API development
- **Features Used**:
  - Routing
  - Middleware
  - Error handling
  - Static file serving

### 4.2.3 Key Node.js Packages

| Package | Purpose |
|---------|---------|
| `express` | Web framework for REST APIs |
| `pg` | PostgreSQL database client |
| `bcryptjs` | Password hashing |
| `jsonwebtoken` | JWT authentication |
| `socket.io` | Real-time bidirectional communication |
| `multer` | File upload handling |
| `cors` | Cross-origin resource sharing |
| `dotenv` | Environment variable management |

## 4.3 Machine Learning

### 4.3.1 Python
- **Version**: 3.10+
- **Purpose**: AI/ML model development and deployment

### 4.3.2 TensorFlow & Keras
- **Version**: TensorFlow 2.x
- **Purpose**: Deep learning model training and inference
- **Model Architecture**: MobileNetV2 (Transfer Learning)
- **Accuracy Achieved**: 100%

### 4.3.3 Flask Framework
- **Purpose**: ML model API deployment
- **Features**:
  - RESTful endpoint for predictions
  - Image preprocessing
  - JSON response formatting

### 4.3.4 Key Python Libraries

| Library | Purpose |
|---------|---------|
| `tensorflow` | Deep learning framework |
| `keras` | High-level neural network API |
| `flask` | Web framework for ML API |
| `numpy` | Numerical computations |
| `pillow` | Image processing |
| `opencv-python` | Computer vision operations |

## 4.4 Database

### 4.4.1 PostgreSQL
- **Version**: 15.x
- **Hosting**: Neon (Cloud PostgreSQL)
- **Purpose**: Primary data storage
- **Why Chosen**:
  - ACID compliance
  - Complex query support
  - Excellent performance
  - JSON support for flexible data

### 4.4.2 Database Schema (Key Tables)

| Table | Purpose |
|-------|---------|
| `users` | User accounts (patients & doctors) |
| `doctors` | Doctor-specific information |
| `patients` | Patient-specific information |
| `appointments` | Appointment bookings |
| `messages` | Chat messages |
| `calls` | Call history |
| `reports` | Medical scan reports |
| `doctor_availability` | Doctor schedule slots |

## 4.5 Real-Time Communication

### 4.5.1 Socket.IO
- **Purpose**: Real-time bidirectional event-based communication
- **Features Used**:
  - Instant messaging
  - Typing indicators
  - Online/offline status
  - Message delivery confirmations

### 4.5.2 WebRTC
- **Purpose**: Peer-to-peer audio/video communication
- **Implementation**: flutter_webrtc package
- **Features**:
  - Voice calls
  - Video calls
  - Screen sharing capability

## 4.6 External APIs

### 4.6.1 OpenStreetMap Nominatim API
- **Purpose**: Nearby pharmacy search
- **Endpoint**: `https://nominatim.openstreetmap.org/search`
- **Features**:
  - Geolocation-based search
  - Pharmacy details retrieval
  - Distance calculation

## 4.7 Cloud Services & Deployment

### 4.7.1 Replit
- **Purpose**: Backend hosting and deployment
- **Features**:
  - Always-on deployment
  - Environment variable management
  - Easy scaling

### 4.7.2 Neon Database
- **Purpose**: Cloud PostgreSQL hosting
- **Features**:
  - Serverless PostgreSQL
  - Auto-scaling
  - Branching for development

## 4.8 Development Tools

### 4.8.1 Version Control
- **Git**: Source code versioning
- **GitHub**: Code repository hosting

### 4.8.2 IDEs & Editors
- **VS Code**: Primary code editor
- **Android Studio**: Android SDK & emulator management

### 4.8.3 API Testing
- **Postman**: API endpoint testing
- **curl**: Command-line API testing

### 4.8.4 Design Tools
- **Figma**: UI/UX design (if applicable)

## 4.9 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    RAYSCAN ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐ │
│  │   Flutter    │     │   Node.js    │     │   Python     │ │
│  │   Mobile     │◄───►│   Backend    │◄───►│   ML API     │ │
│  │     App      │     │   (Express)  │     │   (Flask)    │ │
│  └──────────────┘     └──────────────┘     └──────────────┘ │
│         │                    │                    │          │
│         │                    │                    │          │
│         ▼                    ▼                    ▼          │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐ │
│  │  Socket.IO   │     │  PostgreSQL  │     │  TensorFlow  │ │
│  │  (Real-time) │     │   (Neon)     │     │  MobileNetV2 │ │
│  └──────────────┘     └──────────────┘     └──────────────┘ │
│                                                              │
│  ┌──────────────┐     ┌──────────────┐                      │
│  │   WebRTC     │     │ OpenStreetMap│                      │
│  │(Voice/Video) │     │     API      │                      │
│  └──────────────┘     └──────────────┘                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 4.10 Technology Stack Summary

| Layer | Technology |
|-------|------------|
| **Mobile App** | Flutter (Dart) |
| **Backend API** | Node.js + Express.js |
| **ML API** | Python + Flask |
| **Database** | PostgreSQL (Neon Cloud) |
| **Real-Time** | Socket.IO |
| **Video/Voice** | WebRTC |
| **ML Model** | TensorFlow + MobileNetV2 |
| **Location API** | OpenStreetMap Nominatim |
| **Hosting** | Replit |
| **Authentication** | JWT (JSON Web Tokens) |

---

# Key Features Summary

## For Patients:
1. AI-powered kidney stone detection (100% accuracy)
2. Search and book appointments with urologists
3. Real-time chat with doctors
4. Voice and video consultations
5. Find nearby pharmacies
6. View medical reports and scan history
7. Profile management with photo upload

## For Doctors:
1. Dashboard with statistics
2. Manage appointments
3. View and search patient list
4. Chat with patients
5. Conduct video consultations
6. Set availability schedule
7. Track earnings and ratings

---

# Conclusion

RayScan represents a comprehensive solution for kidney stone diagnosis and healthcare consultation. By combining AI-powered image analysis with modern communication technologies, the application bridges the gap between patients and healthcare providers, enabling faster diagnosis and improved healthcare outcomes.

The use of modern technologies like Flutter, Node.js, TensorFlow, and WebRTC ensures a scalable, maintainable, and user-friendly application that can be extended to support additional medical diagnostic capabilities in the future.

---

**Project By**: [Your Name]
**Supervisor**: [Supervisor Name]
**Institution**: [Your University/College]
**Year**: 2025
