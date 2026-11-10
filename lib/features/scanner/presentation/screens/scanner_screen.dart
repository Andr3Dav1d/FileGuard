import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Tela do Analisador - Estrutura de fundação visual alinhada com o Figma.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisador'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.space16,
            bottom: AppSpacing.space24,
          ),
          child: const Center(
            child: Text('Analisador'),
          ),
        ),
      ),
    );
  }
}
