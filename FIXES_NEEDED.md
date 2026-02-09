# COMPLETE FIX LIST FOR FLUTTER APP

## ✅ COMPLETED FIXES:
1. **Password visibility toggle (patient login)** - DONE ✓

---

## 🔧 FIXES TO IMPLEMENT:

### HIGH PRIORITY (User-facing issues):

#### 1. **Change "Welcome back" to "Welcome"**
**File**: `lib/screens/login_screen.dart`
**Line**: 48
**Current**: `'Welcome back, ${response.user.name}!'`
**Fix**: Change to `'Welcome, ${response.user.name}!'`

---

#### 2. **Remove hardcoded vitals from patient profile**
**File**: `lib/screens/profile_screen.dart`
**Lines**: 142-171
**Current**: Shows hardcoded `215bpm`, `756cal`, `103lbs`
**Fix**: Either remove the entire vitals section OR fetch real data from backend

**Code to remove**:
```dart
// Lines 142-171 - Delete or comment out this entire section:
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _buildMetric(Icons.favorite, '215', 'bpm', Colors.red),
    _buildMetric(Icons.flash_on, '756', 'cal', Colors.orange),
    _buildMetric(Icons.fitness_center, '103', 'lbs', Colors.blue),
  ],
),
```

---

#### 3. **Fix chat message order**
**File**: `lib/screens/chat_screen.dart`
**Line**: 359
**Current**: `reverse: true` - makes latest messages at top
**Fix**: Remove `reverse: true` to make messages bottom-up

Also need to update scroll logic at lines 123-130 and line 92.

---

#### 4. **Add Terms & Conditions dialog**
**File**: `lib/screens/signup_screen.dart`
**Lines**: 295-318

**Current code** (non-functional):
```dart
Text.rich(
  TextSpan(
    text: 'I agree to the ',
    children: [
      TextSpan(
        text: 'Terms of Service',
        style: TextStyle(
          color: Color(0xFF0E807F),
          fontWeight: FontWeight.bold,
        ),
      ),
      // ... more text
    ],
  ),
)
```

**Fix**: Make text actually clickable by wrapping in GestureDetector:
```dart
GestureDetector(
  onTap: () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text('YOUR TERMS TEXT HERE'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  },
  child: Text.rich(...),
)
```

---

### MEDIUM PRIORITY:

#### 5. **Add profile picture upload for patients**
**File**: `lib/screens/profile_screen.dart`
**Lines**: 100-130

**Current**: Camera icon is visible but does nothing

**Fix needed**:
1. Add ImagePicker package (already in dependencies)
2. Add state variable for selected image
3. Implement `_pickImage()` method
4. Implement `_uploadProfileImage()` method
5. Update UI to show selected image

**Reference implementation**: See `lib/screens/doctor_profile_edit_screen.dart` lines 64-101

---

#### 6. **Add image/document upload to chat**
**File**: `lib/screens/chat_screen.dart`
**Lines**: 372-428

**Current**: Only text input exists

**Fix needed**:
1. Add attachment button next to send button
2. Use ImagePicker for images
3. Use FilePicker for documents
4. Update message model to support attachments
5. Update backend API to handle file uploads
6. Update UI to display images/files in chat

This is a MAJOR feature - requires backend changes too.

---

#### 7. **Make doctor dashboard stats clickable**
**File**: `lib/screens/doctor_home_screen.dart`
**Lines**: 323-367

**Current**: Stats cards are display-only

**Fix**: Wrap each card in `InkWell` or `GestureDetector`:
```dart
InkWell(
  onTap: () {
    // Navigate to today's appointments
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentsListScreen(filter: 'today'),
      ),
    );
  },
  child: _buildStatCard(...),
)
```

---

#### 8. **Add content to "Learn More" button**
**File**: `lib/screens/patient_home.dart`
**Lines**: 218-231

**Current**: Shows snackbar saying "Learn more clicked"

**Fix options**:
- Option A: Navigate to informational screen about kidney stones
- Option B: Show dialog with health tips
- Option C: Open external URL with resources

**Simple fix**:
```dart
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HealthEducationScreen(),
    ),
  );
},
```

---

### REQUIRES BACKEND INVESTIGATION:

#### 9. **Fix doctor search (shows "No results found")**
**Files**:
- `lib/screens/search_results_screen.dart` (lines 27-46)
- `lib/services/doctor_service.dart` (search method)
- Backend API: `/doctors/search`

**Debugging needed**:
1. Check if backend API is working
2. Check search query format
3. Check response parsing
4. Add console logs to see what's being sent/received

**Add debug logs**:
```dart
debugPrint('Search query: ${widget.query}');
debugPrint('Search results: ${result.length} doctors found');
debugPrint('Response data: ${response.data}');
```

---

#### 10. **Fix pharmacy phone numbers (showing random numbers)**
**File**: `lib/screens/pharmacy_screen.dart`
**Lines**: 32-59

**Issue**: OpenStreetMap API may not return phone numbers for all pharmacies

**Possible fixes**:
- Check if `pharmacy['tags']` contains actual phone data
- If no phone available, show "Contact for phone number"
- Validate phone numbers before displaying
- Use a different data source (Google Places API)

**Debug first**:
```dart
debugPrint('Pharmacy data: ${pharmacy['tags']}');
debugPrint('Phone: ${pharmacy['tags']?['phone'] ?? 'No phone'}');
```

---

## 🔍 INVESTIGATION NEEDED:

### Doctor Search Issue
**Steps to debug**:
1. Open Flutter DevTools console
2. Search for a doctor
3. Check network tab for API call
4. Check if API returns data
5. Check if data is being parsed correctly

### Pharmacy Numbers Issue
**Steps to debug**:
1. Print pharmacy data to console
2. Check OpenStreetMap response format
3. Verify phone number field exists
4. Consider alternative: hide phone if not available

---

## 📝 IMPLEMENTATION ORDER (RECOMMENDED):

### Quick Wins (5 min each):
1. ✅ Password visibility toggle - DONE
2. Change "Welcome back" to "Welcome" - 1 line
3. Remove hardcoded vitals - Delete section

### Medium (15-30 min each):
4. Add Terms dialog
5. Fix chat message order
6. Make dashboard stats clickable
7. Add Learn More content

### Complex (1-2 hours each):
8. Add patient profile picture upload
9. Debug and fix doctor search
10. Fix/validate pharmacy phone numbers
11. Add chat attachments (requires backend)

---

## 🛠️ TOOLS NEEDED:

- **ImagePicker**: Already in dependencies ✓
- **FilePicker**: May need to add for documents
- **Backend access**: For search/pharmacy debugging

---

## 📌 NEXT STEPS:

Tell me which fixes you want to prioritize:
- A. Start with all quick wins (items 2-3)
- B. Focus on user-visible issues (welcome message, vitals, chat)
- C. Debug backend issues first (search, pharmacy)
- D. Implement complex features (file upload, clickable dashboard)

Let me know what you want to tackle first!
