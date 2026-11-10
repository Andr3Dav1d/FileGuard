import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Tela inicial (Início) - Estrutura de fundação visual alinhada com o Figma.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.shield_outlined),
        title: const Text('FileGuard'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.space16,
            bottom: AppSpacing.space24,
          ),
          child: const Center(
            child: Text('Início'),
          ),
        ),
      ),
    );
  }
}
