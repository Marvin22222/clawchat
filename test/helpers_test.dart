import 'package:flutter_test/flutter_test.dart';
import 'package:clawchat/core/utils/helpers.dart';
import 'package:clawchat/core/utils/crypto_utils.dart';

void main() {
  group('StringUtils', () {
    test('truncate should cut long strings', () {
      expect(StringUtils.truncate('Hello World', 5), 'Hello...');
      expect(StringUtils.truncate('Hi', 10), 'Hi');
    });

    test('capitalize should work', () {
      expect(StringUtils.capitalize('hello'), 'Hello');
      expect(StringUtils.capitalize('HELLO'), 'Hello');
      expect(StringUtils.capitalize(''), '');
    });

    test('isValidUrl should detect URLs', () {
      expect(StringUtils.isValidUrl('https://example.com'), true);
      expect(StringUtils.isValidUrl('not a url'), false);
    });
  });

  group('Validators', () {
    test('validateRequired should detect empty strings', () {
      expect(Validators.validateRequired(null, 'Field'), 'Field ist erforderlich');
      expect(Validators.validateRequired('', 'Field'), 'Field ist erforderlich');
      expect(Validators.validateRequired('test', 'Field'), null);
    });

    test('validateToken should check token length', () {
      expect(Validators.validateToken(null), 'Token ist erforderlich');
      expect(Validators.validateToken('short'), 'Token ist zu kurz');
      expect(Validators.validateToken('valid_token_123'), null);
    });

    test('validateEmail should detect invalid emails', () {
      expect(Validators.validateEmail(null), 'E-Mail ist erforderlich');
      expect(Validators.validateEmail('notemail'), 'Ungültige E-Mail-Adresse');
      expect(Validators.validateEmail('test@example.com'), null);
    });
  });

  group('CryptoUtils', () {
    test('hash should generate consistent hash', () {
      final hash1 = CryptoUtils.hash('test');
      final hash2 = CryptoUtils.hash('test');
      expect(hash1, hash2);
    });

    test('generateShortId should generate unique IDs', () {
      final id1 = CryptoUtils.generateShortId('test1');
      final id2 = CryptoUtils.generateShortId('test2');
      expect(id1, isNot(id2));
    });

    test('maskToken should show partial token', () {
      expect(CryptoUtils.maskToken('abcdefghijklmnop'), 'abcd...mnop');
      expect(CryptoUtils.maskToken('short'), 'short');
    });
  });

  group('DateTimeUtils', () {
    test('formatMessageTime should format correctly', () {
      // These would need mocking of DateTime.now() for proper testing
      // Just verify no exceptions are thrown
      expect(DateTimeUtils.formatMessageTime(DateTime.now()), isNotEmpty);
    });
  });
}
