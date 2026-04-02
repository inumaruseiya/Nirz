import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/value_objects/post_id.dart';

final class DeletePostUseCase {
  DeletePostUseCase(this._posts);

  final PostRepository _posts;

  Future<Result<void, Failure>> call(PostId id) => _posts.deletePost(id);
}
