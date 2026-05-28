// ignore_for_file: public_member_api_docs

import 'dart:convert';

/// French labels for password validation errors returned by the backend.
class AppTextsPasswordValidation {
  AppTextsPasswordValidation._();

  static const String passwordRequired = 'Le mot de passe est obligatoire.';
  static const String passwordFieldsRequired =
      'Veuillez remplir tous les champs.';
  static const String incorrectPassword =
      'Le mot de passe actuel est incorrect.';
  static const String forbidden =
      'Vous n’êtes pas autorisé à modifier ce mot de passe.';
  static const String passwordInvalid =
      'Le mot de passe ne respecte pas les règles de sécurité.';
  static const String passwordTooSimilar =
      'Le mot de passe est trop similaire à vos informations personnelles.';
  static const String passwordTooShort =
      'Le mot de passe doit contenir au moins 8 caractères.';
  static const String passwordTooCommon = 'Le mot de passe est trop courant.';
  static const String passwordEntirelyNumeric =
      'Le mot de passe ne peut pas être entièrement numérique.';
  static const String fieldRequired = 'Ce champ est obligatoire.';

  static String fromResponseBody(String responseBody, String fallbackMessage) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final details = decoded['details'];
        if (details is List && details.isNotEmpty) {
          return details.map((error) => localize(error.toString())).join('\n');
        }
        if (details is String && details.isNotEmpty) {
          return localize(details);
        }

        final password = decoded['password'];
        if (password is List && password.isNotEmpty) {
          return password.map((error) => localize(error.toString())).join('\n');
        }
        if (password is String && password.isNotEmpty) {
          return localize(password);
        }

        final code = decoded['code'];
        if (code is String && code.isNotEmpty) {
          return localize(code);
        }

        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return localize(detail);
        }

        for (final value in decoded.values) {
          if (value is List && value.isNotEmpty) {
            return localize(value.first.toString());
          }
          if (value is String && value.isNotEmpty) {
            return localize(value);
          }
        }
      }
    } catch (_) {}

    return fallbackMessage;
  }

  static String localize(String message) {
    final normalized = message.trim().toLowerCase();

    if (normalized.contains('password_fields_required')) {
      return passwordFieldsRequired;
    }
    if (normalized.contains('incorrect_password') ||
        normalized.contains('incorrect password')) {
      return incorrectPassword;
    }
    if (normalized.contains('forbidden')) {
      return forbidden;
    }
    if (normalized.contains('password_required')) {
      return passwordRequired;
    }
    if (normalized.contains('password_invalid') ||
        normalized.contains('password_validation_failed')) {
      return passwordInvalid;
    }
    if (normalized.contains('this field is required')) {
      return fieldRequired;
    }
    if (normalized.contains('too similar')) {
      return passwordTooSimilar;
    }
    if (normalized.contains('too short') ||
        normalized.contains('at least 8 characters')) {
      return passwordTooShort;
    }
    if (normalized.contains('too common')) {
      return passwordTooCommon;
    }
    if (normalized.contains('entirely numeric')) {
      return passwordEntirelyNumeric;
    }

    return message;
  }
}
