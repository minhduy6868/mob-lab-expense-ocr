import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/services/sync_ops.dart';

void main() {
  test('compactSyncOps drops writes that a later clear erases', () {
    final ops = [
      {'op': 'upsert', 'item': {'id': 'a'}},
      {'op': 'delete', 'id': 'a'},
      {'op': 'clear'},
      {'op': 'upsert', 'item': {'id': 'b'}},
    ];

    final compacted = compactSyncOps(ops);

    expect(compacted.length, 2);
    expect(compacted.first['op'], 'clear');
    expect(compacted.last['op'], 'upsert');
  });

  test('compactSyncOps keeps a queue that never clears', () {
    final ops = [
      {'op': 'upsert', 'item': {'id': 'a'}},
      {'op': 'delete', 'id': 'b'},
    ];

    expect(compactSyncOps(ops), ops);
  });
}
