import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../application/order_poll.dart';
import '../application/provisioning_steps.dart';
import '../data/models/order.dart';
import '../data/orders_api.dart';
import 'provisioning_progress_view.dart';

/// FR-308: shown while [pollOrderUntilDone] runs, driving the step list on
/// elapsed wall-clock time (there's no sub-`PROCESSING` status to key off --
/// API.md section 6). Resolves [resultCompleter] with the final order, or
/// with the poll's error, then pops itself -- the caller (checkout review)
/// still owns showing the terminal result (FR-309/310/311, not built yet).
/// Back navigation is blocked while provisioning: there's nothing useful to
/// go back to mid-poll.
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({
    super.key,
    required this.ordersApi,
    required this.orderId,
    required this.resultCompleter,
  });

  final OrdersApi ordersApi;
  final String orderId;
  final Completer<Order> resultCompleter;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Duration _elapsed = Duration.zero;
  late final Future<Order> _poll;

  @override
  void initState() {
    super.initState();
    _poll = pollOrderUntilDone(
      widget.ordersApi,
      widget.orderId,
      wait: (delay) async {
        await Future.delayed(delay);
        if (mounted) setState(() => _elapsed += delay);
      },
    );
  }

  void _finish(VoidCallback complete) {
    if (widget.resultCompleter.isCompleted) return;
    complete();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: FutureBuilder<Order>(
                future: _poll,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (snapshot.hasError) {
                        _finish(() => widget.resultCompleter
                            .completeError(snapshot.error!));
                      } else {
                        _finish(() =>
                            widget.resultCompleter.complete(snapshot.data));
                      }
                    });
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Setting up your eSIM',
                          style: AppTypography.headline()),
                      const SizedBox(height: 24),
                      ProvisioningProgressView(
                        currentStep: provisioningStepForElapsed(_elapsed),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
