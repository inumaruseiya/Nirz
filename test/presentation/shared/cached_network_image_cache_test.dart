import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/file.dart' hide FileSystem;
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1×1 PNG（透明）— デコード可能な最小例。
final Uint8List _kOnePixelPng = Uint8List.fromList(<int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  10,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  0,
  1,
  0,
  0,
  5,
  0,
  1,
  13,
  10,
  45,
  180,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

/// 固定 PNG を返す [FileServiceResponse]（HTTP クライアント不要）。
final class _PngFileServiceResponse implements FileServiceResponse {
  _PngFileServiceResponse(this._bytes);

  final Uint8List _bytes;

  @override
  Stream<List<int>> get content => Stream<List<int>>.value(_bytes);

  @override
  int? get contentLength => _bytes.length;

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 1));

  @override
  String? get eTag => '"test"';

  @override
  String get fileExtension => 'png';
}

/// [FileService.get] の呼び出し回数。キャッシュヒット後は増えない想定（Phase 12-6-5）。
final class _CountingPngFileService extends FileService {
  int getCalls = 0;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    getCalls++;
    return _PngFileServiceResponse(_kOnePixelPng);
  }
}

/// [path_provider] を使わずメモリ上にキャッシュファイルを置く（Widget テスト用）。
final class _MemoryFileSystemAdapter implements FileSystem {
  _MemoryFileSystemAdapter(this._root);

  final Directory _root;

  @override
  Future<File> createFile(String name) async => _root.childFile(name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'CachedNetworkImage はキャッシュ済み URL で FileService.get を繰り返さない (12-6-5)',
    (tester) async {
      final mem = MemoryFileSystem();
      final root = mem.directory('/cache_test')..createSync(recursive: true);
      final metaFile = root.childFile('cache_meta.json');

      final fileService = _CountingPngFileService();
      final cacheManager = CacheManager(
        Config(
          'test_cached_network_image_12_6_5',
          fileSystem: _MemoryFileSystemAdapter(root),
          repo: JsonCacheInfoRepository.withFile(metaFile),
          fileService: fileService,
        ),
      );

      const url = 'https://example.invalid/phase-12-6-5-cache-probe.png';

      try {
        await cacheManager.getSingleFile(url);
        expect(fileService.getCalls, 1);

        Widget buildImage() {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: CachedNetworkImage(
              imageUrl: url,
              cacheManager: cacheManager,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, _) => const SizedBox.expand(),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image_outlined),
            ),
          );
        }

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: buildImage())),
        );
        await tester.pump();
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(RawImage).evaluate().isNotEmpty) break;
        }
        expect(fileService.getCalls, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: buildImage())),
        );
        await tester.pump();
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(RawImage).evaluate().isNotEmpty) break;
        }
        expect(fileService.getCalls, 1);
      } finally {
        await cacheManager.dispose();
        // CacheStore は DB 読み取り後に 10 秒後のクリーンアップ用 Timer を積むため、テスト終了前に進める。
        await tester.pump(const Duration(seconds: 11));
      }
    },
  );
}
