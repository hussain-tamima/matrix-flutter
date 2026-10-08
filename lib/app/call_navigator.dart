import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/call/cubit/call_cubit.dart';
import 'package:element_x/features/call/view/call_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Layers call UI over the current route instead of pushing a dedicated screen.
class CallNavigator extends StatefulWidget {
  const CallNavigator({super.key, required this.child});

  final Widget child;

  @override
  State<CallNavigator> createState() => _CallNavigatorState();
}

class _CallNavigatorState extends State<CallNavigator> {
  late final MatrixStore _store;
  late final CallCubit _callCubit;

  @override
  void initState() {
    super.initState();
    _store = sl<MatrixStore>();
    _callCubit = sl<CallCubit>();
    _store.addListener(_onStore);
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = _store.call;
    final error = _store.callError;

    return BlocProvider.value(
      value: _callCubit,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (call != null)
            const Positioned.fill(child: CallOverlay()),
          if (call == null && error != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CallErrorBanner(
                message: error,
                onDismiss: _callCubit.dismissFailure,
              ),
            ),
        ],
      ),
    );
  }
}
