import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';

class PlanillaScreen extends ConsumerWidget {
  const PlanillaScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const AppGradientScaffold(child: Center(child: Text('Planilla familiar')));
}
