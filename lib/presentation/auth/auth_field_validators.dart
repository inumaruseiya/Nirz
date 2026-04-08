/// 認証フォームのバリデーション（実装計画 Phase 5-2-4、詳細設計 4.2）。
abstract final class AuthFieldValidators {
  AuthFieldValidators._();

  /// Supabase の一般的な下限に合わせた目安（クライアント側の早期フィードバック用）。
  static const int passwordMinLength = 8;

  static const int passwordMaxLength = 128;

  /// プロフィール表示名（`profiles.name`）。登録・設定で共通（FR-AUTH-02）。
  static const int nicknameMaxLength = 50;

  /// 実用的な簡易メール形式（厳密な RFC 検証はサーバ側に委ねる）。
  static final RegExp _emailLoose = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z]{2,})+$',
  );

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!_emailLoose.hasMatch(v)) {
      return 'メールアドレスの形式が正しくありません';
    }
    return null;
  }

  static String? password(String? value) {
    final p = value ?? '';
    if (p.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (p.length < passwordMinLength) {
      return 'パスワードは$passwordMinLength文字以上にしてください';
    }
    if (p.length > passwordMaxLength) {
      return 'パスワードは$passwordMaxLength文字以内にしてください';
    }
    return null;
  }

  /// ニックネーム（空不可・最大 [nicknameMaxLength]）。
  static String? nickname(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'ニックネームを入力してください';
    }
    if (v.length > nicknameMaxLength) {
      return 'ニックネームは$nicknameMaxLength文字以内にしてください';
    }
    return null;
  }
}
