

import 'package:flutter_riverpod/legacy.dart';

class SidebarState {
  final bool isCollapsed;
  SidebarState({required this.isCollapsed});

  SidebarState copyWith({bool? isCollapsed}) {
    return SidebarState(
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }
}

class SidebarNotifier extends StateNotifier<SidebarState> {
  SidebarNotifier() : super(SidebarState(isCollapsed: false));

  void toggle() {
    state = state.copyWith(isCollapsed: !state.isCollapsed);
  }

  void collapse() {
    state = state.copyWith(isCollapsed: true);
  }

  void expand() {
    state = state.copyWith(isCollapsed: false);
  }
}

// ✅ Global provider
final sidebarProvider = StateNotifierProvider<SidebarNotifier, SidebarState>((ref) {
  return SidebarNotifier();
});
