import 'package:element_x/core/di/di.dart';

import 'package:element_x/core/matrix/matrix_models.dart';

import 'package:element_x/core/matrix/matrix_store.dart';

import 'package:element_x/core/routes/route_paths.dart';

import 'package:flutter/widgets.dart';

import 'package:go_router/go_router.dart';

/// Opens the call screen for active calls and leaves it when the call ends.

class CallNavigator extends StatefulWidget {
  const CallNavigator({super.key, required this.child});

  final Widget child;

  @override
  State<CallNavigator> createState() => _CallNavigatorState();
}

class _CallNavigatorState extends State<CallNavigator> {
  late final MatrixStore _store;

  MatrixCall? _lastCall;
  String? _lastError;

  @override
  void initState() {
    super.initState();

    _store = sl<MatrixStore>();

    _lastCall = _store.call;
    _lastError = _store.callError;

    _store.addListener(_onStore);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncRoute();
      }
    });
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);

    super.dispose();
  }

  void _onStore() {
    final call = _store.call;

    final error = _store.callError;

    final previous = _lastCall;

    final previousError = _lastError;

    _lastCall = call;

    _lastError = error;

    final becameActive = call != null && previous == null;

    final statusChanged =
        call != null && previous != null && call.status != previous.status;

    final ended = previous != null && call == null;

    final errorCleared = previousError != null && error == null;

    if (!becameActive && !statusChanged && !ended && !errorCleared) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncRoute();
      }
    });
  }

  void _syncRoute() {
    final router = sl<GoRouter>();

    final onCall = router.state.uri.path == RoutePaths.call;

    final call = _store.call;

    if (call != null && !onCall) {
      router.push(RoutePaths.call);

      return;
    }

    if (call == null && onCall && _store.callError == null && router.canPop()) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
