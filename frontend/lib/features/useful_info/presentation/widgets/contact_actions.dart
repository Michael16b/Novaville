import 'package:flutter/material.dart';

class ContactActions extends StatelessWidget {
  final String? phone;
  final String? email;
  final String? website;

  const ContactActions({super.key, this.phone, this.email, this.website});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        if ((phone ?? "").isNotEmpty)
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.call),
            label: Text(phone!),
          ),
        if ((email ?? "").isNotEmpty)
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email),
            label: const Text("Email"),
          ),
        if ((website ?? "").isNotEmpty)
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.public),
            label: const Text("Site web"),
          ),
      ],
    );
  }
}
