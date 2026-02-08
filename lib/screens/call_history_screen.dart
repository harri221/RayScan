import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/call_service.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  List<Map<String, dynamic>> _callHistory = [];
  List<Map<String, dynamic>> _missedCalls = [];
  bool _isLoading = true;
  bool _showMissedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadCallData();
  }

  Future<void> _loadCallData() async {
    try {
      setState(() => _isLoading = true);

      final historyResult = await CallService.getCallHistory();
      final missedResult = await CallService.getMissedCalls();

      setState(() {
        _callHistory = List<Map<String, dynamic>>.from(
          historyResult['callHistory'] ?? []
        );
        _missedCalls = List<Map<String, dynamic>>.from(
          missedResult['missedCalls'] ?? []
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading call history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _showMissedOnly ? _missedCalls : _callHistory;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E807F),
        foregroundColor: Colors.white,
        title: const Text('Call History'),
        actions: [
          if (_missedCalls.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showMissedOnly = !_showMissedOnly;
                });
              },
              icon: Icon(
                _showMissedOnly ? Icons.history : Icons.phone_missed,
                color: Colors.white,
              ),
              label: Text(
                _showMissedOnly ? 'All' : 'Missed',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCallData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showMissedOnly ? Icons.phone_missed : Icons.call,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showMissedOnly
                            ? 'No missed calls'
                            : 'No call history yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCallData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final call = displayList[index];
                      return _buildCallHistoryCard(call);
                    },
                  ),
                ),
    );
  }

  Widget _buildCallHistoryCard(Map<String, dynamic> call) {
    final String direction = call['direction'] ?? 'incoming';
    final String callType = call['callType'] ?? 'audio';
    final String status = call['status'] ?? 'unknown';
    final String callerName = call['callerName'] ?? 'Unknown';
    final String receiverName = call['receiverName'] ?? 'Unknown';
    final int duration = call['duration'] ?? 0;
    final String createdAt = call['createdAt'] ?? '';

    // Determine the display name based on direction
    final String displayName = direction == 'outgoing' ? receiverName : callerName;

    // Choose icon and color based on status and direction
    IconData iconData;
    Color iconColor;

    if (status == 'missed') {
      iconData = Icons.phone_missed;
      iconColor = Colors.red;
    } else if (status == 'rejected') {
      iconData = Icons.call_end;
      iconColor = Colors.orange;
    } else if (direction == 'outgoing') {
      iconData = Icons.call_made;
      iconColor = Colors.green;
    } else {
      iconData = Icons.call_received;
      iconColor = Colors.blue;
    }

    // Parse timestamp
    final DateTime timestamp = createdAt.isNotEmpty
        ? DateTime.parse(createdAt)
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              callType == 'video' ? Icons.videocam : Icons.phone,
              size: 18,
              color: Colors.grey[600],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  CallService.getCallStatusText(status),
                  style: TextStyle(
                    color: status == 'missed' ? Colors.red : Colors.grey[700],
                    fontSize: 13,
                    fontWeight:
                        status == 'missed' ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (duration > 0) ...[
                  Text(
                    ' • ${CallService.formatDuration(duration)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              timeago.format(timestamp),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: direction == 'outgoing'
            ? Icon(Icons.arrow_upward, size: 20, color: Colors.grey[400])
            : Icon(Icons.arrow_downward, size: 20, color: Colors.grey[400]),
      ),
    );
  }
}
