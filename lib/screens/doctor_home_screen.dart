import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/doctor_profile_service.dart';
import '../services/socket_service.dart';
import '../services/call_notification_service.dart';
import '../services/call_service.dart';
import 'role_selection_screen.dart';
import 'doctor_profile_edit_screen.dart';
import 'doctor_schedule_screen.dart';
import 'doctor_appointments_list_screen.dart';
import 'doctor_conversations_list_screen.dart';
import 'doctor_patients_screen.dart';
import 'call_history_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure Socket.io connection is active when doctor home screen loads
    _ensureSocketConnection();
    // Initialize global call notification service for incoming calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallNotificationService.initialize(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reconnect socket when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _ensureSocketConnection();
    }
  }

  Future<void> _ensureSocketConnection() async {
    if (!SocketService.isConnected) {
      print('🔄 Doctor home screen: Reconnecting Socket.io...');
      await SocketService.connect();
    } else {
      print('✅ Doctor home screen: Socket.io already connected');
    }
  }

  final List<Widget> _screens = [
    const DoctorDashboardTab(),
    const DoctorAppointmentsTab(),
    const DoctorConversationsListScreen(), // Chat/Messages screen for doctors
    const DoctorPatientsScreen(), // Patients list screen
    const DoctorAccountTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on dashboard tab, go to dashboard first
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        // If on dashboard, show exit confirmation
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0E807F),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        ),
      ),
    );
  }
}

// Dashboard Tab
class DoctorDashboardTab extends StatefulWidget {
  const DoctorDashboardTab({super.key});

  @override
  State<DoctorDashboardTab> createState() => _DoctorDashboardTabState();
}

class _DoctorDashboardTabState extends State<DoctorDashboardTab> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recentAppointments = [];
  bool _isLoading = true;
  int missedCallsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadStats(),
      _loadRecentAppointments(),
      _loadMissedCallsCount(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DoctorProfileService.getDoctorStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentAppointments() async {
    try {
      final appointments = await DoctorProfileService.getDoctorAppointments();
      if (!mounted) return;
      setState(() {
        // Get only first 3 appointments for dashboard
        _recentAppointments = appointments.take(3).toList();
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadMissedCallsCount() async {
    try {
      final count = await CallService.getMissedCallsCount();
      if (mounted) {
        setState(() {
          missedCallsCount = count;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E807F),
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          // Call History with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.phone_in_talk, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CallHistoryScreen(),
                    ),
                  );
                  // Reload missed calls count when returning
                  _loadMissedCallsCount();
                },
              ),
              if (missedCallsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      missedCallsCount > 9 ? '9+' : '$missedCallsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E807F), Color(0xFF2E8B57)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E807F).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back, Doctor!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Today is ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Today\'s\nAppointments',
                    '${_stats?['todayAppointments'] ?? 0}',
                    Icons.calendar_today,
                    const Color(0xFF4CAF50),
                    onTap: () {
                      // Navigate to Appointments tab
                      final homeState = context.findAncestorStateOfType<_DoctorHomeScreenState>();
                      homeState?.setState(() {
                        homeState._selectedIndex = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total\nPatients',
                    '${_stats?['totalPatients'] ?? 0}',
                    Icons.people,
                    const Color(0xFF2196F3),
                    onTap: () {
                      // Navigate to Patients tab
                      final homeState = context.findAncestorStateOfType<_DoctorHomeScreenState>();
                      homeState?.setState(() {
                        homeState._selectedIndex = 2;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Monthly\nEarnings',
                    'PKR ${(_stats?['monthlyEarnings'] ?? 0).toStringAsFixed(0)}',
                    Icons.attach_money,
                    const Color(0xFFFF9800),
                    onTap: () {
                      // Show earnings details
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Earnings details coming soon!'),
                          backgroundColor: Color(0xFF0E807F),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rating',
                    '${(_stats?['rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                    Icons.star,
                    const Color(0xFFF44336),
                    onTap: () {
                      // Show ratings details
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rating details coming soon!'),
                          backgroundColor: Color(0xFF0E807F),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Appointments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Appointments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E807F),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Appointments tab
                    final homeState = context.findAncestorStateOfType<_DoctorHomeScreenState>();
                    homeState?.setState(() {
                      homeState._selectedIndex = 1;
                    });
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Color(0xFF0E807F)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_recentAppointments.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No appointments scheduled',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...List.generate(
                _recentAppointments.length,
                (index) => _buildAppointmentCard(_recentAppointments[index]),
              ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E807F),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Schedule',
                    Icons.schedule,
                    const Color(0xFF9C27B0),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorScheduleScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'Patients',
                    Icons.people,
                    const Color(0xFF607D8B),
                    () {
                      // Navigate to Patients tab
                      final homeState = context.findAncestorStateOfType<_DoctorHomeScreenState>();
                      homeState?.setState(() {
                        homeState._selectedIndex = 3;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'Messages',
                    Icons.chat_bubble_outline,
                    const Color(0xFF795548),
                    () {
                      // Navigate to Messages tab
                      final homeState = context.findAncestorStateOfType<_DoctorHomeScreenState>();
                      homeState?.setState(() {
                        homeState._selectedIndex = 2;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final patientName = appointment['patient_name'] ?? 'Patient';
    final appointmentType = appointment['appointment_type'] ?? 'Consultation';
    final appointmentDate = appointment['appointment_date'] ?? '';
    final appointmentTime = appointment['appointment_time'] ?? '';
    final status = appointment['status'] ?? 'pending';

    // Format time display
    String timeDisplay = appointmentTime;
    if (appointmentDate.isNotEmpty) {
      try {
        final date = DateTime.parse(appointmentDate);
        final now = DateTime.now();
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          timeDisplay = 'Today $appointmentTime';
        } else {
          timeDisplay = '${date.day}/${date.month} $appointmentTime';
        }
      } catch (e) {
        timeDisplay = appointmentTime;
      }
    }

    Color statusColor = Colors.orange;
    if (status == 'confirmed') statusColor = Colors.green;
    if (status == 'completed') statusColor = Colors.blue;
    if (status == 'cancelled') statusColor = Colors.red;

    return GestureDetector(
      onTap: () {
        // Navigate to Appointments tab
        final homeState = context.findAncestorStateOfType<_DoctorHomeScreenState>();
        homeState?.setState(() {
          homeState._selectedIndex = 1;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0E807F).withValues(alpha: 0.1),
              child: Text(
                patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Color(0xFF0E807F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        appointmentType,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              timeDisplay,
              style: const TextStyle(
                color: Color(0xFF0E807F),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Appointments Tab
class DoctorAppointmentsTab extends StatelessWidget {
  const DoctorAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DoctorAppointmentsListScreen();
  }
}

// Patients Tab

// Account Tab
class DoctorAccountTab extends StatefulWidget {
  const DoctorAccountTab({super.key});

  @override
  State<DoctorAccountTab> createState() => _DoctorAccountTabState();
}

class _DoctorAccountTabState extends State<DoctorAccountTab> {
  Map<String, dynamic>? _doctorProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final profile = await DoctorProfileService.getDoctorProfile();
      if (!mounted) return;
      setState(() {
        _doctorProfile = profile['doctor'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E807F),
        title: const Text(
          'Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoleSelectionScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF0E807F).withValues(alpha: 0.1),
                          backgroundImage: _doctorProfile?['profileImage'] != null
                              ? NetworkImage(_doctorProfile!['profileImage'])
                              : null,
                          child: _doctorProfile?['profileImage'] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF0E807F),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _doctorProfile?['name'] ?? 'Doctor',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0E807F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _doctorProfile?['specialization'] ?? 'Specialist',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PMDC Verified',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu Items
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person,
                    title: 'Edit Profile',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorProfileEditScreen(),
                        ),
                      );
                      // Reload profile after edit
                      _loadDoctorProfile();
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.schedule,
                    title: 'Availability Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorScheduleScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.attach_money,
                    title: 'Consultation Fees',
                    onTap: () => _showConsultationFeesDialog(context),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () => _showNotificationsSettings(context),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.help,
                    title: 'Help & Support',
                    onTap: () => _showHelpSupport(context),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.info,
                    title: 'About',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
    );
  }

  void _showConsultationFeesDialog(BuildContext context) {
    final feeController = TextEditingController(
      text: _doctorProfile?['consultation_fee']?.toString() ?? '500',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Fees'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fee (PKR)',
                prefixText: 'PKR ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This fee will be shown to patients when booking appointments.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save fee logic would go here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Consultation fee updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E807F),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool appointmentNotif = true;
          bool messageNotif = true;
          bool callNotif = true;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Appointment Reminders'),
                  subtitle: const Text('Get notified about upcoming appointments'),
                  value: appointmentNotif,
                  activeColor: const Color(0xFF0E807F),
                  onChanged: (val) => setModalState(() => appointmentNotif = val),
                ),
                SwitchListTile(
                  title: const Text('New Messages'),
                  subtitle: const Text('Get notified when patients send messages'),
                  value: messageNotif,
                  activeColor: const Color(0xFF0E807F),
                  onChanged: (val) => setModalState(() => messageNotif = val),
                ),
                SwitchListTile(
                  title: const Text('Incoming Calls'),
                  subtitle: const Text('Get notified for video/audio calls'),
                  value: callNotif,
                  activeColor: const Color(0xFF0E807F),
                  onChanged: (val) => setModalState(() => callNotif = val),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF0E807F)),
              title: const Text('Email Support'),
              subtitle: const Text('support@rayscan.com'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email client...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF0E807F)),
              title: const Text('Phone Support'),
              subtitle: const Text('+92 300 1234567'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening phone dialer...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF0E807F)),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live chat coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF0E807F)),
              title: const Text('FAQs'),
              subtitle: const Text('Frequently asked questions'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RayScan Healthcare Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '1. Data Collection\n'
                'We collect information you provide directly to us, including personal information, medical records, and usage data.\n\n'
                '2. Data Usage\n'
                'Your data is used to provide healthcare services, improve our platform, and communicate with you about appointments.\n\n'
                '3. Data Protection\n'
                'We implement industry-standard security measures to protect your personal and medical information.\n\n'
                '4. Data Sharing\n'
                'We do not sell or share your personal information with third parties except as required by law or with your consent.\n\n'
                '5. Your Rights\n'
                'You have the right to access, correct, or delete your personal data at any time.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0E807F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medical_services,
                color: Color(0xFF0E807F),
              ),
            ),
            const SizedBox(width: 12),
            const Text('RayScan'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'RayScan is a comprehensive healthcare platform connecting patients with qualified doctors for consultations, appointments, and AI-powered medical imaging analysis.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Video & Audio Consultations'),
            Text('• AI Kidney Stone Detection'),
            Text('• Appointment Management'),
            Text('• Secure Messaging'),
            Text('• Digital Prescriptions'),
            SizedBox(height: 16),
            Text(
              '© 2024 RayScan Healthcare',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0E807F)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}