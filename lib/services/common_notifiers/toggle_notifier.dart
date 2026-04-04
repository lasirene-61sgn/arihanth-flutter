import 'package:flutter_riverpod/legacy.dart';

final actionsExpandedProvider = StateNotifierProvider<_ActionsExpandedNotifier, bool>((ref) {
  return _ActionsExpandedNotifier();
});

class _ActionsExpandedNotifier extends StateNotifier<bool> {
  _ActionsExpandedNotifier() : super(false);
  void toggle() => state = !state;
}
