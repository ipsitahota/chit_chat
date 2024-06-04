import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyDateUtil {
  static String getFormattedTime({required BuildContext context, required DateTime time}) {
    return _formatDateTime(time);
  }

  static String getFormattedmsgTime({required BuildContext context, required DateTime time}) {
    return _formatMessageTime(time);
  }

  static String getLastMessageTime({
    required BuildContext context,
    required DateTime time,
    bool showYear = false,
    required TextStyle style,
  }) {
    return _formatMessageTime(time);
  }

  static String getLastActiveTime({required BuildContext context, required DateTime? lastActive}) {
    if (lastActive == null) return 'Last seen not available';
    return _formatDateTime(lastActive);
  }

  static String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Last seen Today at ${DateFormat.jm().format(dateTime)}'; // Format: Yesterday 5:30 PM
     // return DateFormat.jm().format(dateTime); // Format: 5:30 PM
    } else if (difference.inDays == 1) {
      return 'Last seen Yesterday at ${DateFormat.jm().format(dateTime)}'; // Format: Yesterday 5:30 PM
    } else if (difference.inDays < 7) {
      return 'Last seen ${DateFormat.E().format(dateTime)} at ${DateFormat.jm().format(dateTime)}'; // Format: Mon 5:30 PM
    } else {
      return 'Last seen ${DateFormat('dd/MM/yyyy hh:mm a').format(dateTime)}'; // Format: Mon 5:30 PM
     // return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime); // Format: 01/01/2023 5:30 PM
    }
  }

  static String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime); // Format: 5:30 PM
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(dateTime); // Format: Mon, Tue, etc.
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime); // Format: 01/01/2023
    }
  }
  }
