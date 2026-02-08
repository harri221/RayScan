import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/appointment_service.dart';
import '../services/chat_service.dart';
import 'appointment_book.dart';
import 'chat_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<TimeSlot> _availableTimeSlots = [];
  bool _isLoadingTimes = false;

  Future<void> _loadAvailableTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingTimes = true;
      _selectedTime = null;
    });

    try {
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final timeSlots = await AppointmentService.getDoctorAvailability(
        widget.doctor.id,
        formattedDate,
      );

      setState(() {
        _availableTimeSlots = timeSlots;
        _isLoadingTimes = false;
      });
    } catch (e) {
      setState(() {
        _availableTimeSlots = [];
        _isLoadingTimes = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load available times: $e')),
        );
      }
    }
  }

  bool _isSelectedSlotBooked() {
    if (_selectedTime == null) return false;

    final selectedTimeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    final matchingSlot = _availableTimeSlots.firstWhere(
      (slot) => slot.time == selectedTimeString,
      orElse: () => TimeSlot(time: selectedTimeString, available: true),
    );

    return !matchingSlot.available;
  }

  Future<void> _startChat() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0E807F)),
        ),
      );

      // Create or get existing conversation
      final conversation = await ChatService.createConversation(
        doctorId: widget.doctor.id,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation['id'],
              doctorName: widget.doctor.name,
              doctorId: widget.doctor.id,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.doctor.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor info section
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.specialty,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(' ${widget.doctor.rating}'),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on, size: 16),
                        Text(' ${widget.doctor.distance}'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // About section
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.doctor.about ?? 'No description available'),
            const SizedBox(height: 24),

            // Chat Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text(
                  'Chat with Doctor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E807F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date selection
            const Text(
              'Available Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final date = DateTime.now().add(Duration(days: index));
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _loadAvailableTimeSlots(date);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedDate?.day == date.day
                            ? Colors.blue
                            : null,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: _selectedDate?.day == date.day
                              ? Colors.white
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Time selection
            const Text(
              'Available Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoadingTimes)
              const Center(child: CircularProgressIndicator())
            else if (_selectedDate == null)
              const Text(
                'Please select a date first',
                style: TextStyle(color: Colors.grey),
              )
            else if (_availableTimeSlots.isEmpty)
              const Text(
                'No available times for this date',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: _availableTimeSlots.map((timeSlot) {
                  final timeParts = timeSlot.time.split(':');
                  final hour = int.parse(timeParts[0]);
                  final minute = int.parse(timeParts[1]);
                  final timeOfDay = TimeOfDay(hour: hour, minute: minute);
                  final isSelected = _selectedTime?.hour == timeOfDay.hour &&
                                   _selectedTime?.minute == timeOfDay.minute;

                  return GestureDetector(
                    onTap: timeSlot.available ? () {
                      setState(() {
                        _selectedTime = timeOfDay;
                      });
                    } : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: !timeSlot.available
                            ? Colors.grey.withOpacity(0.3)
                            : isSelected
                                ? Colors.blue
                                : Colors.transparent,
                        border: Border.all(
                          color: !timeSlot.available
                              ? Colors.grey.withOpacity(0.5)
                              : Colors.grey
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                timeSlot.time,
                                style: TextStyle(
                                  color: !timeSlot.available
                                      ? Colors.grey
                                      : isSelected
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: timeSlot.available
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  timeSlot.available ? 'Free' : 'Booked',
                                  style: TextStyle(
                                    color: timeSlot.available ? Colors.green : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: !timeSlot.available ? Colors.grey : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Book Appointment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDate == null || _selectedTime == null || _isSelectedSlotBooked()
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentBookScreen(
                              doctor: widget.doctor,
                              selectedDate: _selectedDate!,
                              selectedTime: _selectedTime!,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSelectedSlotBooked() ? Colors.grey : null,
                ),
                child: Text(_isSelectedSlotBooked() ? 'Slot Not Available' : 'Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
