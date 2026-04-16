import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'platform_adaptive_dialogs.dart';
import '../theme/app_tokens.dart';

/// 通報ダイアログで選べるプリセット理由（実装計画 Phase 10-2-2、FR-MOD-02）。
const List<({String id, String label})> kReportPresetReasons =
    <({String id, String label})>[
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
    return '$presetLabel: $d';
  }
}

/// プリセット理由＋自由記述の通報 UI。確定時のみ [ReportReasonDraft] を返す（キャンセルは null）。
Future<ReportReasonDraft?> showReportReasonDialog(
  BuildContext context, {
  required String title,
}) {
  return showAppDialog<ReportReasonDraft>(
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
    if (useCupertinoDialogs) {
      return CupertinoAlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '理由を選んでください',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              const SizedBox(height: AppTokens.spaceUnit),
              ...List.generate(kReportPresetReasons.length, (i) {
                final item = kReportPresetReasons[i];
                final selected = _selectedIndex == i;
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _selectedIndex = i),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                          size: 22,
                        ),
                        const SizedBox(width: AppTokens.spaceUnit),
                        Expanded(child: Text(item.label)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppTokens.spaceUnit),
              Text(
                '補足（任意）',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              const SizedBox(height: AppTokens.spaceUnit / 2),
              CupertinoTextField(
                controller: _detailController,
                maxLines: 4,
                maxLength: _maxDetailLength,
                placeholder: '詳しい状況があれば入力できます',
                padding: const EdgeInsets.all(10),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: _submit,
            child: const Text('確定'),
          ),
        ],
      );
    }

    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('理由を選んでください', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.spaceUnit),
            ...List.generate(kReportPresetReasons.length, (i) {
              final item = kReportPresetReasons[i];
              final selected = _selectedIndex == i;
              return InkWell(
                onTap: () => setState(() => _selectedIndex = i),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 22,
                      ),
                      const SizedBox(width: AppTokens.spaceUnit),
                      Expanded(child: Text(item.label)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppTokens.spaceUnit),
            Text('補足（任意）', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.spaceUnit / 2),
            TextField(
              controller: _detailController,
              maxLines: 4,
              maxLength: _maxDetailLength,
              decoration: const InputDecoration(hintText: '詳しい状況があれば入力できます'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('確定')),
      ],
    );
  }
}
