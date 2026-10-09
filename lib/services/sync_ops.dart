/// Drops queued writes that a later clear would erase.
List<Map<String, dynamic>> compactSyncOps(List<Map<String, dynamic>> ops) {
  final lastClear = ops.lastIndexWhere((op) => op['op'] == 'clear');
  if (lastClear <= 0) return List<Map<String, dynamic>>.from(ops);
  return ops.sublist(lastClear);
}
