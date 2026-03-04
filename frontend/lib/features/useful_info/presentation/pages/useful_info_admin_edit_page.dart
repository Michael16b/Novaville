import 'package:flutter/material.dart';
import '../../domain/useful_info.dart';

class UsefulInfoAdminEditPage extends StatefulWidget {
  final UsefulInfo initial;

  const UsefulInfoAdminEditPage({super.key, required this.initial});

  @override
  State<UsefulInfoAdminEditPage> createState() =>
      _UsefulInfoAdminEditPageState();
}

class _UsefulInfoAdminEditPageState extends State<UsefulInfoAdminEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _postal;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _website;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i.cityHallName);
    _address = TextEditingController(text: i.addressLine1);
    _postal = TextEditingController(text: i.postalCode);
    _city = TextEditingController(text: i.city);
    _phone = TextEditingController(text: i.phone ?? "");
    _email = TextEditingController(text: i.email ?? "");
    _website = TextEditingController(text: i.website ?? "");
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _postal.dispose();
    _city.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.initial.copyWith(
      cityHallName: _name.text,
      addressLine1: _address.text,
      postalCode: _postal.text,
      city: _city.text,
      phone: _phone.text,
      email: _email.text,
      website: _website.text,
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier Infos utiles"),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: "Adresse"),
            ),
            TextFormField(
              controller: _postal,
              decoration: const InputDecoration(labelText: "Code postal"),
            ),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: "Ville"),
            ),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: "Téléphone"),
            ),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextFormField(
              controller: _website,
              decoration: const InputDecoration(labelText: "Site web"),
            ),
          ],
        ),
      ),
    );
  }
}
