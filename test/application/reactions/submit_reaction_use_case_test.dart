import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nirz/application/reactions/submit_reaction_use_case.dart';
import 'package:nirz/domain/core/failure.dart';
import 'package:nirz/domain/core/result.dart';
import 'package:nirz/domain/repositories/reaction_repository.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/reaction_type.dart';

class _MockReactionRepository extends Mock implements ReactionRepository {}

void main() {
  final postId = PostId.parse('11111111-1111-4111-8111-111111111111');

  late _MockReactionRepository repo;
  late SubmitReactionUseCase useCase;

  setUpAll(() {
    registerFallbackValue(postId);
    registerFallbackValue(ReactionType.like);
  });

  setUp(() {
    repo = _MockReactionRepository();
    useCase = SubmitReactionUseCase(repo);
  });

  group('SubmitReactionUseCase', () {
    test('delegates to upsertReaction and returns Ok', () async {
      when(() => repo.upsertReaction(postId, ReactionType.fire))
          .thenAnswer((_) async => const Ok<void, Failure>(null));

      final result = await useCase(postId, ReactionType.fire);

      expect(result, const Ok<void, Failure>(null));
      verify(() => repo.upsertReaction(postId, ReactionType.fire)).called(1);
    });

    test('propagates repository failure', () async {
      when(() => repo.upsertReaction(any(), any()))
          .thenAnswer((_) async => const Err(ServerFailure()));

      final result = await useCase(postId, ReactionType.look);

      expect(result, isA<Err<void, Failure>>());
      expect((result as Err).error, isA<ServerFailure>());
      verify(() => repo.upsertReaction(postId, ReactionType.look)).called(1);
    });
  });
}
