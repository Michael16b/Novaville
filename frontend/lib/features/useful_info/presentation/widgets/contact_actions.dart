import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_useful_info.dart';

class ContactActions extends StatelessWidget {
  const ContactActions({super.key, this.phone, this.email, this.website});
  final String? phone;
  final String? email;
  final String? website;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((email ?? '').isNotEmpty)
          Row(
            children: [
              const Icon(Icons.email, size: 20),
              const SizedBox(width: 8),
              Text(
                '${UsefulInfoTexts.emailLabel} $email',
                style: textTheme.bodyMedium,
              ),
            ],
          ),

        if ((phone ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.call, size: 20),
              const SizedBox(width: 8),
              Text(
                '${UsefulInfoTexts.phoneLabel} $phone',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ],

        if ((website ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.public, size: 20),
              const SizedBox(width: 8),
              Text(
                '${UsefulInfoTexts.websiteLabel} $website',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
