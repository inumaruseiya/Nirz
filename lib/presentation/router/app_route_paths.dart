/// アプリ全体で共有するルートパス（GoRouter の `path` と一致させる）。
abstract final class AppRoutePaths {
  static const splash = '/splash';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const feed = '/feed';
  static const compose = '/compose';
  static const settings = '/settings';

  static const postDetailPrefix = '/posts/';

  static String postDetail(String postId) => '$postDetailPrefix$postId';
}
