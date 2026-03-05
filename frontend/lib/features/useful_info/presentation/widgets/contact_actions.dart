import 'package:flutter/material.dart';

class ContactActions extends StatelessWidget {
  final String? phone;
  final String? email;
  final String? website;

  const ContactActions({super.key, this.phone, this.email, this.website});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((email ?? "").isNotEmpty)
          Row(
            children: [
              const Icon(Icons.email, size: 20),
              const SizedBox(width: 8),
              Text("E-mail : $email"),
            ],
          ),

        if ((phone ?? "").isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.call, size: 20),
              const SizedBox(width: 8),
              Text("Téléphone : $phone"),
            ],
          ),
        ],

        if ((website ?? "").isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.public, size: 20),
              const SizedBox(width: 8),
              Text("Site web : $website"),
            ],
          ),
        ],
      ],
    );
  }
}
