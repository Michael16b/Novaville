import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:frontend/features/agenda/presentation/helpers/calendar_export_helper.dart';
import 'package:frontend/features/users/data/models/user.dart';

void main() {
  const testUser = User(
    id: 1,
    username: 'agent',
    firstName: 'Agent',
    lastName: 'Test',
  );

  group('CalendarExportHelper.formatGoogleDate', () {
    test('formats a UTC date correctly', () {
      final date = DateTime.utc(2026, 3, 7, 14, 0);
      expect(CalendarExportHelper.formatGoogleDate(date), '20260307T140000Z');
    });

    test('pads month, day, hour, minute, second with leading zeros', () {
      final date = DateTime.utc(2026, 1, 5, 8, 3, 9);
      expect(CalendarExportHelper.formatGoogleDate(date), '20260105T080309Z');
    });

    test('converts local time to UTC before formatting', () {
      // Build a local DateTime and verify the formatted output matches .toUtc().
      final local = DateTime(2025, 12, 31, 23, 59, 59);
      final expectedUtc = local.toUtc();
      final expected =
          '${expectedUtc.year}'
          '${expectedUtc.month.toString().padLeft(2, '0')}'
          '${expectedUtc.day.toString().padLeft(2, '0')}'
          'T'
          '${expectedUtc.hour.toString().padLeft(2, '0')}'
          '${expectedUtc.minute.toString().padLeft(2, '0')}'
          '${expectedUtc.second.toString().padLeft(2, '0')}'
          'Z';
      expect(CalendarExportHelper.formatGoogleDate(local), expected);
    });

    test('always ends with Z', () {
      final date = DateTime.utc(2026, 6, 21, 10, 30);
      expect(CalendarExportHelper.formatGoogleDate(date), endsWith('Z'));
    });
  });

  group('CalendarExportHelper.escapeIcs', () {
    test('escapes backslashes', () {
      expect(CalendarExportHelper.escapeIcs(r'a\b'), r'a\\b');
    });

    test('escapes commas', () {
      expect(CalendarExportHelper.escapeIcs('a,b'), r'a\,b');
    });

    test('escapes semicolons', () {
      expect(CalendarExportHelper.escapeIcs('a;b'), r'a\;b');
    });

    test('escapes newlines', () {
      expect(CalendarExportHelper.escapeIcs('a\nb'), r'a\nb');
    });

    test('escapes multiple special characters in one string', () {
      expect(
        CalendarExportHelper.escapeIcs('réunion,publique;local\ninfo'),
        r'réunion\,publique\;local\ninfo',
      );
    });

    test('returns plain text unchanged', () {
      const text = 'Réunion publique';
      expect(CalendarExportHelper.escapeIcs(text), text);
    });
  });

  group('CalendarExportHelper.generateIcs', () {
    final event = CommunityEvent(
      id: 42,
      title: 'Fête de la musique',
      description: 'Concert en plein air',
      startDate: DateTime.utc(2026, 6, 21, 18, 0),
      endDate: DateTime.utc(2026, 6, 21, 22, 0),
      createdBy: testUser,
    );

    late String ics;

    setUp(() {
      ics = CalendarExportHelper.generateIcs(event);
    });

    test('starts with BEGIN:VCALENDAR and ends with END:VCALENDAR', () {
      expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
      expect(ics, endsWith('END:VCALENDAR\r\n'));
    });

    test('contains correct DTSTART', () {
      expect(ics, contains('DTSTART:20260621T180000Z\r\n'));
    });

    test('contains correct DTEND', () {
      expect(ics, contains('DTEND:20260621T220000Z\r\n'));
    });

    test('contains correct UID with event id', () {
      expect(ics, contains('UID:event-42@novaville\r\n'));
    });

    test('contains SUMMARY with title (special chars escaped)', () {
      expect(ics, contains('SUMMARY:Fête de la musique\r\n'));
    });

    test('contains DESCRIPTION', () {
      expect(ics, contains('DESCRIPTION:Concert en plein air\r\n'));
    });

    test('escapes title with special characters', () {
      final specialEvent = event.copyWith(title: 'Réunion,publique;local');
      final result = CalendarExportHelper.generateIcs(specialEvent);
      expect(result, contains(r'SUMMARY:Réunion\,publique\;local'));
    });

    test('uses CRLF line endings throughout', () {
      // Remove all proper CRLF pairs; no bare \n should remain.
      expect(ics.replaceAll('\r\n', ''), isNot(contains('\n')));
    });

    test('contains mandatory ICS fields', () {
      expect(ics, contains('VERSION:2.0\r\n'));
      expect(ics, contains('BEGIN:VEVENT\r\n'));
      expect(ics, contains('END:VEVENT\r\n'));
      expect(ics, contains('STATUS:CONFIRMED\r\n'));
    });
  });
}
