import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/constants/app_strings.dart';
import 'package:rapidoo/core/constants/validation_patterns.dart';
import 'package:rapidoo/core/utils/validators.dart';

void main() {
  group('dzPhone', () {
    test('accepts 05, 06 and 07 mobiles of 10 digits', () {
      expect(Validators.dzPhone('0551234567'), isNull);
      expect(Validators.dzPhone('0661234567'), isNull);
      expect(Validators.dzPhone('0771234567'), isNull);
    });

    test('requires a number', () {
      expect(Validators.dzPhone(null), AppStrings.phoneEmpty);
      expect(Validators.dzPhone(''), AppStrings.phoneEmpty);
    });

    test('rejects other prefixes and lengths', () {
      expect(Validators.dzPhone('0861234567'), AppStrings.phoneInvalid);
      expect(Validators.dzPhone('066123456'), AppStrings.phoneInvalid);
      expect(Validators.dzPhone('06612345678'), AppStrings.phoneInvalid);
    });
  });

  group('dzPhonePartial', () {
    test('stays quiet while the typed prefix can still be valid', () {
      expect(Validators.dzPhonePartial(''), isNull);
      expect(Validators.dzPhonePartial('0'), isNull);
      expect(Validators.dzPhonePartial('06'), isNull);
      expect(Validators.dzPhonePartial('0661'), isNull);
    });

    test('flags a wrong start as soon as it is typed', () {
      expect(Validators.dzPhonePartial('6'), 'Number must start with 0');
      expect(Validators.dzPhonePartial('08'),
          'Number must start with 05, 06, or 07');
    });
  });

  group('name', () {
    test('accepts letters, spaces, apostrophes and hyphens', () {
      for (final name in ['Amina', 'Ben Ali', "O'Neil", 'Jean-Luc', 'Élodie']) {
        expect(Validators.name(name), '', reason: name);
      }
    });

    test('names the field when it is empty', () {
      expect(Validators.name(''), 'Full name is required');
      expect(Validators.name('', field: 'First Name'),
          'First Name is required');
    });

    test('rejects short names and non-letters', () {
      expect(Validators.name('A'), 'Name must be at least 2 characters');
      expect(Validators.name('Amina2'), 'Name must contain letters only');
      expect(Validators.name('Ben  Ali'), 'Name must contain letters only');
    });

    test('accepts Arabic names, as the server does', () {
      expect(Validators.name('أمينة'), '');
      expect(Validators.name('محمد بن علي'), '');
    });
  });

  group('name input filter', () {
    String typed(String text) =>
        FilteringTextInputFormatter.allow(ValidationPatterns.nameInputChars)
            .formatEditUpdate(
                TextEditingValue.empty, TextEditingValue(text: text))
            .text;

    test('lets letters of any script through', () {
      expect(typed("Jean-Luc O'Neil"), "Jean-Luc O'Neil");
      expect(typed('أمينة بن علي'), 'أمينة بن علي');
    });

    test('drops digits and symbols', () {
      expect(typed('Amina2!'), 'Amina');
      expect(typed('أمينة_7'), 'أمينة');
    });
  });

  group('email', () {
    test('is optional', () => expect(Validators.email(''), ''));

    test('accepts a normal address and rejects malformed ones', () {
      expect(Validators.email('amina@example.dz'), '');
      expect(Validators.email('amina@example'), 'Enter a valid email address');
      expect(Validators.email('amina example@x.dz'),
          'Enter a valid email address');
    });
  });

  group('plate', () {
    test('accepts the formatted plate and its looser variants', () {
      for (final plate in [
        '12345-123-16',
        '123456-123-16',
        '12345 123 16',
        '1234512316',
      ]) {
        expect(Validators.plate(plate), '', reason: plate);
      }
    });

    test('requires a well-formed plate', () {
      expect(Validators.plate(''), AppStrings.plateRequired);
      expect(Validators.plate('1234-123-16'), AppStrings.plateInvalid);
    });
  });

  group('vehicleText', () {
    test('requires at least two characters, ignoring spaces', () {
      expect(Validators.vehicleText('  ', 'Model'), 'Model is required');
      expect(Validators.vehicleText('A', 'Model'),
          'Model must be at least 2 characters');
      expect(Validators.vehicleText('C3', 'Model'), '');
    });
  });
}
