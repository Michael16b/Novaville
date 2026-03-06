import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_useful_info.dart';
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
        title: const Text(UsefulInfoTexts.editTitle),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '${UsefulInfoTexts.nameLabel} *',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return UsefulInfoTexts.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: '${UsefulInfoTexts.addressLabel} *',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return UsefulInfoTexts.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _postal,
              decoration: const InputDecoration(
                labelText: '${UsefulInfoTexts.postalCodeLabel} *',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return UsefulInfoTexts.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(
                labelText: '${UsefulInfoTexts.cityLabel} *',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return UsefulInfoTexts.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(
                labelText: UsefulInfoTexts.phoneLabel.replaceAll(' :', ''),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(
                labelText: UsefulInfoTexts.emailLabel.replaceAll(' :', ''),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _website,
              decoration: InputDecoration(
                labelText: UsefulInfoTexts.websiteLabel.replaceAll(' :', ''),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  AppTextsGeneral.requiredFieldsHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
