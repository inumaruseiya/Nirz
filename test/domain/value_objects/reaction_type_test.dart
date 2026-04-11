import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/reaction_type.dart';

void main() {
  group('ReactionType.parse', () {
    test('maps known storage strings (lowercase)', () {
      expect(ReactionType.parse('like'), ReactionType.like);
      expect(ReactionType.parse('look'), ReactionType.look);
      expect(ReactionType.parse('fire'), ReactionType.fire);
    });

    test('trims and lowercases input', () {
      expect(ReactionType.parse('  LIKE  '), ReactionType.like);
      expect(ReactionType.parse('Look'), ReactionType.look);
      expect(ReactionType.parse('FIRE'), ReactionType.fire);
    });

    test('throws FormatException for unknown values', () {
      expect(
        () => ReactionType.parse('love'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Unknown reaction type',
          ),
        ),
      );
      expect(() => ReactionType.parse(''), throwsA(isA<FormatException>()));
    });
  });

  group('ReactionType.storageValue', () {
    test('matches enum name for Supabase', () {
      expect(ReactionType.like.storageValue, 'like');
      expect(ReactionType.look.storageValue, 'look');
      expect(ReactionType.fire.storageValue, 'fire');
    });
  });
}
