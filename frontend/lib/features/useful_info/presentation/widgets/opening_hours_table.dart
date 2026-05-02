import 'package:flutter/material.dart';

class OpeningHoursTable extends StatelessWidget {
  const OpeningHoursTable({super.key, required this.openingHours});
  final Map<String, List<String>> openingHours;

  // Order of days as they should appear
  static const _dayOrder = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  Widget build(BuildContext context) {
    // Sort entries by day order
    final sortedEntries = openingHours.entries.toList()
      ..sort((a, b) {
        final indexA = _dayOrder.indexOf(a.key);
        final indexB = _dayOrder.indexOf(b.key);
        // Days not in list go to end
        return (indexA == -1 ? _dayOrder.length : indexA).compareTo(
          indexB == -1 ? _dayOrder.length : indexB,
        );
      });

    return Column(
      children: sortedEntries.map((entry) {
        final day = entry.key;
        final slots = entry.value;
        final text = slots.isEmpty ? 'Fermé' : slots.join(' - ');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(day)),
              Expanded(child: Text(text, textAlign: TextAlign.right)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
