import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/useful_info/domain/useful_info.dart';

void main() {
  group('UsefulInfo', () {
    const info = UsefulInfo(
      cityHallName: 'Mairie de Novaville',
      addressLine1: '1 place de la Mairie',
      postalCode: '75000',
      city: 'Novaville',
      phone: '0102030405',
      email: 'contact@novaville.fr',
      website: 'https://novaville.fr',
      instagram: 'https://instagram.com/novaville',
      facebook: 'https://facebook.com/novaville',
      x: 'https://x.com/novaville',
      openingHours: {},
      additionalInfo: 'Accueil sur rendez-vous',
    );

    test('copyWith can clear nullable social network fields', () {
      final updated = info.copyWith(instagram: null, facebook: null, x: null);

      expect(updated.instagram, isNull);
      expect(updated.facebook, isNull);
      expect(updated.x, isNull);
    });

    test('copyWith keeps nullable fields when they are omitted', () {
      final updated = info.copyWith(city: 'Nouvelle Novaville');

      expect(updated.city, 'Nouvelle Novaville');
      expect(updated.instagram, info.instagram);
      expect(updated.facebook, info.facebook);
      expect(updated.x, info.x);
      expect(updated.additionalInfo, info.additionalInfo);
    });
  });
}
