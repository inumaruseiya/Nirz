import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 通報ダイアログで選べるプリセット理由（実装計画 Phase 10-2-2、FR-MOD-02）。
const List<({String id, String label})> kReportPresetReasons = <({String id, String label})>[
  (id: 'spam', label: 'スパム・宣伝'),
  (id: 'harassment', label: '嫌がらせ・誹謗中傷'),
  (id: 'illegal', label: '違法・危険な内容'),
  (id: 'other', label: 'その他'),
];

/// プリセット選択と任意の自由記述をまとめた通報理由（DB の `reason` に渡す文字列）。
final class ReportReasonDraft {
  const ReportReasonDraft({
    required this.presetId,
    required this.presetLabel,
    required this.detailText,
  });

  final String presetId;
  final String presetLabel;

  /// ユーザーが入力した補足（トリム済みで空可）。
  final String detailText;

  /// `reports.reason` 用。自由記述があるときは `ラベル: 詳細` 形式。
  String get reasonForStorage {
    final d = detailText.trim();
    if (d.isEmpty) return presetLabel;
    return '${presetLabel}: $d';
  }
}

/// プリセット理由＋自由記述の通報 UI。確定時のみ [ReportReasonDraft] を返す（キャンセルは null）。
Future<ReportReasonDraft?> showReportReasonDialog(
  BuildContext context, {
  required String title,
}) {
  return showDialog<ReportReasonDraft>(
    context: context,
    builder: (ctx) => _ReportReasonDialog(title: title),
  );
}

class _ReportReasonDialog extends StatefulWidget {
  const _ReportReasonDialog({required this.title});

  final String title;

  @override
  State<_ReportReasonDialog> createState() => _ReportReasonDialogState();
}

class _ReportReasonDialogState extends State<_ReportReasonDialog> {
  int _selectedIndex = 0;
  final _detailController = TextEditingController();

  static const int _maxDetailLength = 500;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _submit() {
    final item = kReportPresetReasons[_selectedIndex];
    Navigator.of(context).pop(
      ReportReasonDraft(
        presetId: item.id,
        presetLabel: item.label,
        detailText: _detailController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '理由を選んでください',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppTokens.spaceUnit),
            ...List.generate(kReportPresetReasons.length, (i) {
              final item = kReportPresetReasons[i];
              return RadioListTile<int>(
                title: Text(item.label),
                value: i,
                groupValue: _selectedIndex,
                onChanged: (v) {
                  if (v != null) setState(() => _selectedIndex = v);
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: AppTokens.spaceUnit),
            Text(
              '補足（任意）',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppTokens.spaceUnit / 2),
            TextField(
              controller: _detailController,
              maxLines: 4,
              maxLength: _maxDetailLength,
              decoration: const InputDecoration(
                hintText: '詳しい状況があれば入力できます',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('確定'),
        ),
      ],
    );
  }
}
