import 'package:flutter/material.dart';
import '../services/doctor_profile_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Map<String, List<Map<String, dynamic>>> _scheduleByDay = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final scheduleList = await DoctorProfileService.getDoctorSchedule();

      // Group slots by day
      final scheduleMap = <String, List<Map<String, dynamic>>>{};
      for (var slot in scheduleList) {
        final day = slot['dayOfWeek'] as String;
        if (!scheduleMap.containsKey(day)) {
          scheduleMap[day] = [];
        }
        scheduleMap[day]!.add(slot);
      }

      // Sort slots by start time for each day
      scheduleMap.forEach((day, slots) {
        slots.sort((a, b) => a['startTime'].toString().compareTo(b['startTime'].toString()));
      });

      if (!mounted) return;
      setState(() {
        _scheduleByDay = scheduleMap;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schedule: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addTimeSlot(String day) async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Time Slot for $day'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Start Time'),
                    trailing: Text(
                      startTime?.format(context) ?? 'Select',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0E807F),
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startTime = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Time'),
                    trailing: Text(
                      endTime?.format(context) ?? 'Select',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0E807F),
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endTime = picked;
                        });
                      }
                    },
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
                    if (startTime == null || endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select both start and end times')),
                      );
                      return;
                    }

                    // Validate end time is after start time
                    final startMinutes = startTime!.hour * 60 + startTime!.minute;
                    final endMinutes = endTime!.hour * 60 + endTime!.minute;

                    if (endMinutes <= startMinutes) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('End time must be after start time')),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    await _saveTimeSlot(day, startTime!, endTime!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E807F),
                  ),
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveTimeSlot(String day, TimeOfDay start, TimeOfDay end) async {
    setState(() => _isSaving = true);
    try {
      await DoctorProfileService.addScheduleSlot(
        dayOfWeek: day,
        startTime: _formatTimeOfDay(start),
        endTime: _formatTimeOfDay(end),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Time slot added for $day')),
      );
      await _loadSchedule();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add time slot: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editTimeSlot(Map<String, dynamic> slot) async {
    TimeOfDay? startTime = _parseTimeOfDay(slot['startTime']);
    TimeOfDay? endTime = _parseTimeOfDay(slot['endTime']);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Time Slot - ${slot['dayOfWeek']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Start Time'),
                    trailing: Text(
                      startTime?.format(context) ?? '--:--',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0E807F),
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startTime = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Time'),
                    trailing: Text(
                      endTime?.format(context) ?? '--:--',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0E807F),
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endTime = picked;
                        });
                      }
                    },
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
                    if (startTime == null || endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select both times')),
                      );
                      return;
                    }

                    // Validate
                    final startMinutes = startTime!.hour * 60 + startTime!.minute;
                    final endMinutes = endTime!.hour * 60 + endTime!.minute;

                    if (endMinutes <= startMinutes) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('End time must be after start time')),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    await _updateTimeSlot(slot['id'], startTime!, endTime!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E807F),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateTimeSlot(int slotId, TimeOfDay start, TimeOfDay end) async {
    setState(() => _isSaving = true);
    try {
      await DoctorProfileService.updateScheduleSlot(
        slotId: slotId,
        startTime: _formatTimeOfDay(start),
        endTime: _formatTimeOfDay(end),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slot updated')),
      );
      await _loadSchedule();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteTimeSlot(Map<String, dynamic> slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Slot'),
        content: Text(
          'Delete ${_formatTimeDisplay(slot['startTime'])} - ${_formatTimeDisplay(slot['endTime'])} on ${slot['dayOfWeek']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await DoctorProfileService.deleteScheduleSlot(slot['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slot deleted')),
      );
      await _loadSchedule();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAllSlotsForDay(String day) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Time Slots'),
        content: Text('Delete all time slots for $day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await DoctorProfileService.deleteScheduleDay(day);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All slots deleted for $day')),
      );
      await _loadSchedule();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  String _formatTimeDisplay(String time) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E807F),
        title: const Text(
          'Manage Schedule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _daysOfWeek.length,
                  itemBuilder: (context, index) {
                    final day = _daysOfWeek[index];
                    final slots = _scheduleByDay[day] ?? [];
                    final hasSlots = slots.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                          // Day Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: hasSlots
                                  ? const Color(0xFF0E807F).withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasSlots ? Icons.check_circle : Icons.access_time,
                                  color: hasSlots ? const Color(0xFF0E807F) : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (hasSlots)
                                  Text(
                                    '${slots.length} slot${slots.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Color(0xFF0E807F),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0E807F)),
                                  onPressed: () => _addTimeSlot(day),
                                  tooltip: 'Add time slot',
                                ),
                                if (hasSlots)
                                  IconButton(
                                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                                    onPressed: () => _deleteAllSlotsForDay(day),
                                    tooltip: 'Delete all',
                                  ),
                              ],
                            ),
                          ),

                          // Time Slots List
                          if (hasSlots)
                            ...slots.map((slot) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 20, color: Color(0xFF0E807F)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${_formatTimeDisplay(slot['startTime'])} - ${_formatTimeDisplay(slot['endTime'])}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: Color(0xFF0E807F)),
                                        onPressed: () => _editTimeSlot(slot),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () => _deleteTimeSlot(slot),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ))
                          else
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No time slots set',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }
}
