# Quick SQL Commands for FYP Panel Demo

## How to Run These Queries

### Option 1: Using psql (Command Line)
```bash
# Connect to your database
psql -U postgres -d rascan

# Then paste any query below
```

### Option 2: Using pgAdmin
1. Open pgAdmin
2. Connect to your server
3. Right-click database → Query Tool
4. Paste and run queries

### Option 3: Using Neon Console
1. Go to https://console.neon.tech
2. Select your project
3. Click "SQL Editor"
4. Paste and run queries

---

## QUICK DEMO QUERIES (Copy-Paste Ready)

### 1. Show All Tables
```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
```

### 2. Count All Data
```sql
SELECT
    (SELECT COUNT(*) FROM users WHERE role = 'patient') as patients,
    (SELECT COUNT(*) FROM users WHERE role = 'doctor') as doctors,
    (SELECT COUNT(*) FROM appointments) as appointments,
    (SELECT COUNT(*) FROM messages) as messages,
    (SELECT COUNT(*) FROM calls) as calls;
```

### 3. Show All Users
```sql
SELECT id, email, full_name, role, phone, created_at FROM users ORDER BY created_at DESC;
```

### 4. Show All Doctors
```sql
SELECT u.full_name, d.specialty, d.qualification, d.experience_years, d.consultation_fee, d.rating
FROM doctors d
JOIN users u ON d.user_id = u.id
ORDER BY d.rating DESC;
```

### 5. Show All Appointments
```sql
SELECT
    a.id,
    p.full_name as patient,
    doc.full_name as doctor,
    a.appointment_date,
    a.appointment_time,
    a.status,
    a.consultation_fee
FROM appointments a
JOIN users p ON a.user_id = p.id
JOIN doctors d ON a.doctor_id = d.id
JOIN users doc ON d.user_id = doc.id
ORDER BY a.appointment_date DESC
LIMIT 10;
```

### 6. Show Recent Messages
```sql
SELECT
    s.full_name as sender,
    r.full_name as receiver,
    m.message,
    m.created_at
FROM messages m
JOIN users s ON m.sender_id = s.id
JOIN users r ON m.receiver_id = r.id
ORDER BY m.created_at DESC
LIMIT 10;
```

### 7. Show Recent Calls
```sql
SELECT
    c.full_name as caller,
    r.full_name as receiver,
    ca.call_type,
    ca.status,
    ca.duration_seconds
FROM calls ca
JOIN users c ON ca.caller_id = c.id
JOIN users r ON ca.receiver_id = r.id
ORDER BY ca.started_at DESC
LIMIT 10;
```

### 8. Show Appointment Stats by Status
```sql
SELECT status, COUNT(*) as count FROM appointments GROUP BY status;
```

### 9. Show Doctor Ratings
```sql
SELECT
    u.full_name,
    d.specialty,
    d.rating,
    d.total_reviews,
    COUNT(a.id) as total_appointments
FROM doctors d
JOIN users u ON d.user_id = u.id
LEFT JOIN appointments a ON a.doctor_id = d.id
GROUP BY d.id, u.full_name, d.specialty, d.rating, d.total_reviews
ORDER BY d.rating DESC;
```

### 10. Show AI Diagnosis Reports (if table exists)
```sql
SELECT
    u.full_name as patient,
    r.diagnosis_result,
    r.confidence_score,
    r.created_at
FROM reports r
JOIN users u ON r.user_id = u.id
ORDER BY r.created_at DESC
LIMIT 10;
```

---

## TABLE STRUCTURE QUERIES

### Show Users Table Structure
```sql
\d users
-- OR
SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position;
```

### Show Doctors Table Structure
```sql
\d doctors
-- OR
SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'doctors' ORDER BY ordinal_position;
```

### Show Appointments Table Structure
```sql
\d appointments
-- OR
SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'appointments' ORDER BY ordinal_position;
```

### Show Messages Table Structure
```sql
\d messages
-- OR
SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'messages' ORDER BY ordinal_position;
```

---

## PRESENTATION-READY SUMMARY QUERY

### Complete System Overview (Run This!)
```sql
SELECT '📊 RAYSCAN DATABASE STATISTICS' as title;

SELECT 'Users' as category, role as type, COUNT(*) as count
FROM users GROUP BY role
UNION ALL
SELECT 'Appointments', status, COUNT(*)
FROM appointments GROUP BY status
UNION ALL
SELECT 'Calls', call_type, COUNT(*)
FROM calls GROUP BY call_type
ORDER BY category, type;
```

---

## For Windows Command Prompt (if using local PostgreSQL)

```cmd
# Connect to database
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -d rascan

# Run a quick query
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -d rascan -c "SELECT COUNT(*) FROM users;"
```

---

## Expected Output Examples

### Users Table Output:
```
 id |        email         |   full_name    |  role   |     phone      |     created_at
----+----------------------+----------------+---------+----------------+---------------------
  1 | patient@example.com  | Ahmed Khan     | patient | +923001234567  | 2024-01-15 10:30:00
  2 | doctor@example.com   | Dr. Sara Ali   | doctor  | +923007654321  | 2024-01-10 09:00:00
```

### Appointments Table Output:
```
 id |   patient    |    doctor     | appointment_date | status    | fee
----+--------------+---------------+------------------+-----------+------
  1 | Ahmed Khan   | Dr. Sara Ali  | 2024-01-20       | completed | 2000
  2 | Maria Bibi   | Dr. Hassan    | 2024-01-22       | pending   | 1500
```

### Statistics Output:
```
 patients | doctors | appointments | messages | calls
----------+---------+--------------+----------+-------
       15 |       5 |           42 |      156 |    23
```

---

## Tips for Panel

1. **Show tables first** - "Here are all the tables in our database"
2. **Show structure** - "This is the schema of our appointments table"
3. **Show data** - "Here is actual data from our system"
4. **Show relationships** - "This JOIN query shows how tables connect"
5. **Show statistics** - "Our system has X patients, Y doctors, Z appointments"
