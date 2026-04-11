import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nirz/application/posts/create_post_use_case.dart';
import 'package:nirz/domain/core/failure.dart';
import 'package:nirz/domain/core/result.dart';
import 'package:nirz/domain/entities/post.dart';
import 'package:nirz/domain/repositories/ng_word_list_repository.dart';
import 'package:nirz/domain/repositories/post_repository.dart';
import 'package:nirz/domain/repositories/storage_repository.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/obfuscated_location.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/user_id.dart';

class _MockPostRepository extends Mock implements PostRepository {}

class _MockStorageRepository extends Mock implements StorageRepository {}

class _MockNgWordListRepository extends Mock implements NgWordListRepository {}

void main() {
  final location = ObfuscatedLocation(
    GeoCoordinate(latitude: 35.0, longitude: 139.0),
  );

  late _MockPostRepository posts;
  late _MockStorageRepository storage;
  late _MockNgWordListRepository ngWords;
  late CreatePostUseCase useCase;

  Post samplePost({Uri? imageUrl, String content = 'hello'}) {
    return Post(
      id: PostId.parse('11111111-1111-4111-8111-111111111111'),
      authorId: UserId.parse('22222222-2222-4222-8222-222222222222'),
      content: content,
      imageUrl: imageUrl,
      location: location,
      createdAt: DateTime.utc(2026, 4, 1),
      expiresAt: DateTime.utc(2026, 4, 2),
    );
  }

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      ObfuscatedLocation(GeoCoordinate(latitude: 0, longitude: 0)),
    );
  });

  setUp(() {
    posts = _MockPostRepository();
    storage = _MockStorageRepository();
    ngWords = _MockNgWordListRepository();
    useCase = CreatePostUseCase(posts, storage, ngWords);
  });

  group('CreatePostUseCase', () {
    test('returns post without calling storage when no image', () async {
      when(() => ngWords.loadNgWords()).thenAnswer((_) async => const Ok([]));
      when(
        () => posts.createPost(
          content: 'hello',
          imageUrl: null,
          location: location,
        ),
      ).thenAnswer((_) async => Ok(samplePost()));

      final result = await useCase(
        content: 'hello',
        obfuscatedLocation: location,
      );

      expect(result, isA<Ok<Post, Failure>>());
      expect((result as Ok).value, samplePost());
      verifyNever(() => storage.uploadPostImage(any(), any()));
      verify(
        () => posts.createPost(
          content: 'hello',
          imageUrl: null,
          location: location,
        ),
      ).called(1);
    });

    test('uploads image then createPost receives public URL', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final uri = Uri.parse('https://example.com/bucket/obj.png');
      when(() => ngWords.loadNgWords()).thenAnswer((_) async => const Ok([]));
      when(
        () => storage.uploadPostImage(bytes, 'image/png'),
      ).thenAnswer((_) async => Ok(uri));
      when(
        () => posts.createPost(
          content: 'with pic',
          imageUrl: uri,
          location: location,
        ),
      ).thenAnswer(
        (_) async => Ok(samplePost(imageUrl: uri, content: 'with pic')),
      );

      final result = await useCase(
        content: 'with pic',
        imageBytes: bytes,
        imageContentType: 'image/png',
        obfuscatedLocation: location,
      );

      expect(result, isA<Ok<Post, Failure>>());
      verify(() => storage.uploadPostImage(bytes, 'image/png')).called(1);
      verify(
        () => posts.createPost(
          content: 'with pic',
          imageUrl: uri,
          location: location,
        ),
      ).called(1);
    });

    test('returns validation failure when NG word matches', () async {
      when(
        () => ngWords.loadNgWords(),
      ).thenAnswer((_) async => const Ok(['spam']));
      final result = await useCase(
        content: 'eat spam today',
        obfuscatedLocation: location,
      );
      expect(result, isA<Err<Post, Failure>>());
      expect((result as Err).error, isA<ValidationFailure>());
      verifyNever(() => storage.uploadPostImage(any(), any()));
      verifyZeroInteractions(posts);
    });

    test('propagates failure when NG word list load fails', () async {
      when(
        () => ngWords.loadNgWords(),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      final result = await useCase(content: 'ok', obfuscatedLocation: location);
      expect(result, isA<Err<Post, Failure>>());
      expect((result as Err).error, isA<NetworkFailure>());
      verifyNever(() => storage.uploadPostImage(any(), any()));
      verifyZeroInteractions(posts);
    });

    test('requires imageContentType when imageBytes is set', () async {
      when(() => ngWords.loadNgWords()).thenAnswer((_) async => const Ok([]));
      final result = await useCase(
        content: 'x',
        imageBytes: Uint8List.fromList([0]),
        imageContentType: null,
        obfuscatedLocation: location,
      );
      expect(result, isA<Err<Post, Failure>>());
      expect(
        (result as Err).error,
        const ValidationFailure(
          'imageContentType is required when imageBytes is set',
        ),
      );
      verifyNever(() => storage.uploadPostImage(any(), any()));
      verifyZeroInteractions(posts);
    });

    test('propagates storage upload failure', () async {
      when(() => ngWords.loadNgWords()).thenAnswer((_) async => const Ok([]));
      when(
        () => storage.uploadPostImage(any(), any()),
      ).thenAnswer((_) async => const Err(ServerFailure()));
      final result = await useCase(
        content: 'x',
        imageBytes: Uint8List.fromList([9]),
        imageContentType: 'image/jpeg',
        obfuscatedLocation: location,
      );
      expect(result, isA<Err<Post, Failure>>());
      expect((result as Err).error, isA<ServerFailure>());
      verifyZeroInteractions(posts);
    });

    test('propagates createPost failure', () async {
      when(() => ngWords.loadNgWords()).thenAnswer((_) async => const Ok([]));
      when(
        () => posts.createPost(
          content: 'hello',
          imageUrl: null,
          location: location,
        ),
      ).thenAnswer((_) async => const Err(ServerFailure()));
      final result = await useCase(
        content: 'hello',
        obfuscatedLocation: location,
      );
      expect(result, isA<Err<Post, Failure>>());
      expect((result as Err).error, isA<ServerFailure>());
    });
  });
}
