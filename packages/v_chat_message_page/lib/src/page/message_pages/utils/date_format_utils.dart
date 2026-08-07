// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:intl/intl.dart';

/// Utility class for date formatting in message lists
class DateFormatUtils {
  DateFormatUtils._();

  /// Format date for date divider display
  /// Shows "Today", "Yesterday", or formatted date
  static String formatDateDivider(
    DateTime dateTime, {
    required String today,
    required String yesterday,
  }) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (messageDate == todayDate) {
      return today;
    }
    if (messageDate == yesterdayDate) {
      return yesterday;
    }
    // Check if same year
    if (dateTime.year == now.year) {
      return DateFormat('MMMM d').format(dateTime);
    }
    return DateFormat('MMMM d, y').format(dateTime);
  }
}
