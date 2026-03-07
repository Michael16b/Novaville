import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

/// Helper to export a [CommunityEvent] to an external calendar.
class CalendarExportHelper {
  CalendarExportHelper._();

  /// Opens Google Calendar with a pre-filled event creation form.
  static Future<bool> exportToGoogleCalendar(CommunityEvent event) async {
    final start = formatGoogleDate(event.startDate);
    final end = formatGoogleDate(event.endDate);
    final title = Uri.encodeComponent(event.title);
    final description = Uri.encodeComponent(event.description);

    final url = Uri.parse(
      'https://calendar.google.com/calendar/render'
      '?action=TEMPLATE'
      '&text=$title'
      '&dates=$start/$end'
      '&details=$description',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Generates and downloads an ICS file for Apple Calendar / any
  /// ICS-compatible calendar app.
  ///
  /// On web: creates a Blob and triggers a file download via an
  /// invisible anchor element (bypasses canLaunchUrl limitation).
  /// On mobile: opens a data: URI which the OS handles natively.
  static Future<bool> exportToIcsCalendar(CommunityEvent event) async {
    final icsContent = generateIcs(event);

    try {
      if (kIsWeb) {
        _downloadIcsWeb(icsContent, event.title);
      } else {
        final bytes = utf8.encode(icsContent);
        final base64Data = base64Encode(bytes);
        final dataUri = Uri.parse(
          'data:text/calendar;base64,$base64Data',
        );
        await launchUrl(dataUri);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Downloads an ICS file on the web using a Blob + anchor click.
  /// Explicitly sets charset=utf-8 so accented characters are preserved.
  static void _downloadIcsWeb(String icsContent, String eventTitle) {
    // Encode content as UTF-8 bytes for the Blob
    final bytes = utf8.encode(icsContent);
    final blob = html.Blob(
      <List<int>>[bytes],
      'text/calendar;charset=utf-8',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    // Keep accented chars in filename, only remove truly unsafe chars
    final safeTitle = eventTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '$safeTitle.ics')
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  /// Formats a [DateTime] to Google Calendar date format (UTC).
  /// Example: 20260307T140000Z
  @visibleForTesting
  static String formatGoogleDate(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

  /// Generates ICS file content for the given event.
  @visibleForTesting
  static String generateIcs(CommunityEvent event) {
    final now = DateTime.now().toUtc();
    final stamp = formatGoogleDate(now);
    final start = formatGoogleDate(event.startDate);
    final end = formatGoogleDate(event.endDate);

    // Escape special characters for ICS format
    final title = escapeIcs(event.title);
    final description = escapeIcs(event.description);

    return 'BEGIN:VCALENDAR\r\n'
        'VERSION:2.0\r\n'
        'PRODID:-//Novaville//Agenda//FR\r\n'
        'CALSCALE:GREGORIAN\r\n'
        'METHOD:PUBLISH\r\n'
        'BEGIN:VEVENT\r\n'
        'DTSTART:$start\r\n'
        'DTEND:$end\r\n'
        'DTSTAMP:$stamp\r\n'
        'UID:event-${event.id}@novaville\r\n'
        'SUMMARY:$title\r\n'
        'DESCRIPTION:$description\r\n'
        'STATUS:CONFIRMED\r\n'
        'END:VEVENT\r\n'
        'END:VCALENDAR\r\n';
  }

  /// Escapes special ICS characters.
  @visibleForTesting
  static String escapeIcs(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll('\n', r'\n');
  }
}


