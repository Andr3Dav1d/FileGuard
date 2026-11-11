import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fileguard/app/router/app_routes.dart';
import 'package:fileguard/core/theme/app_shapes.dart';
import 'package:fileguard/core/theme/app_spacing.dart';
import 'package:fileguard/core/theme/app_typography.dart';
import 'package:fileguard/core/theme/file_guard_colors.dart';
import 'package:fileguard/core/widgets/file_guard_app_bar.dart';
import 'package:fileguard/core/widgets/file_guard_button.dart';
import '../providers/onboarding_provider.dart';

/// Tela de Apresentação / Landing Page com fluxo de onboarding em 3 passos conforme Figma.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding({bool goToSettings = true}) async {
    await ref.read(hasSeenOnboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      if (goToSettings) {
        context.go(AppRoutes.settings);
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  String _appBarTitle() {
    switch (_currentPage) {
      case 0:
        return 'Boas-vindas';
      case 1:
        return 'Como funciona';
      case 2:
        return 'Privacidade';
      default:
        return 'FileGuard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FileGuardAppBar(
        title: _appBarTitle(),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar',
                onPressed: _previousPage,
              )
            : null,
        actions: <Widget>[
          TextButton(
            onPressed: () => _finishOnboarding(goToSettings: false),
            child: const Text('Pular'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: <Widget>[
          _buildStep1(context),
          _buildStep2(context),
          _buildStep3(context),
        ],
      ),
    );
  }

  /// Passo 01: Boas-vindas (02 · Boas-vindas)
  Widget _buildStep1(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    return ListView(
      padding: AppSpacing.screenPadding.copyWith(
        top: AppSpacing.space16,
        bottom: AppSpacing.space32,
      ),
      children: <Widget>[
        // Hero Card com Brand Mark
        Container(
          width: double.infinity,
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppShapes.borderLarge,
            border: Border.all(color: theme.colorScheme.outline, width: AppShapes.borderWidth),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 54,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Verifique seus arquivos',
                textAlign: TextAlign.center,
                style: AppTypography.headline.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space24),

        Text(
          'Análise com o VirusTotal',
          style: AppTypography.headline.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        Text(
          'Verifique documentos, downloads e pacotes APK com informações consolidadas do VirusTotal. Você controla cada análise e decide quando enviar.',
          style: AppTypography.body.copyWith(
            color: colors.muted,
            height: 1.5,
          ),
        ),

        const SizedBox(height: AppSpacing.space32),

        // Stepper Label
        Text(
          '01 / 03   •   CONHEÇA SEUS ARQUIVOS',
          style: AppTypography.caption.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space16),

        FileGuardButton(
          label: 'Começar',
          onPressed: _nextPage,
        ),
      ],
    );
  }

  /// Passo 02: Como Funciona (03 · Como funciona)
  Widget _buildStep2(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    return ListView(
      padding: AppSpacing.screenPadding.copyWith(
        top: AppSpacing.space16,
        bottom: AppSpacing.space32,
      ),
      children: <Widget>[
        // Card 1: Consulta SHA-256
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppShapes.borderLarge,
            border: Border.all(color: theme.colorScheme.outline, width: AppShapes.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.fingerprint_rounded, size: 28, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Consulta por SHA-256',
                style: AppTypography.cardTitle.copyWith(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'O FileGuard calcula a impressão digital SHA-256 no próprio dispositivo. Com sua permissão, consulta relatórios existentes no VirusTotal sem enviar o arquivo.',
                style: AppTypography.bodyCompact.copyWith(color: colors.muted, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space12),

        // Card 2: Relatório Existente
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppShapes.borderLarge,
            border: Border.all(color: theme.colorScheme.outline, width: AppShapes.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Relatório Existente',
                style: AppTypography.cardTitle.copyWith(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Veja os diagnósticos de mais de 70 mecanismos de proteção instantaneamente sem precisar transmitir o arquivo original.',
                style: AppTypography.bodyCompact.copyWith(color: colors.muted, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space12),

        // Card 3: Arquivo sem Relatório
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppShapes.borderLarge,
            border: Border.all(color: theme.colorScheme.outline, width: AppShapes.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Arquivo sem Relatório',
                style: AppTypography.cardTitle.copyWith(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'O envio para análise externa só ocorre com sua autorização expressa. Uma nova verificação pode levar alguns minutos.',
                style: AppTypography.bodyCompact.copyWith(color: colors.muted, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space24),

        // Stepper Label
        Text(
          '02 / 03   •   COMO FUNCIONA A ANÁLISE',
          style: AppTypography.caption.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space16),

        FileGuardButton(
          label: 'Continuar',
          onPressed: _nextPage,
        ),
      ],
    );
  }

  /// Passo 03: Privacidade Inicial (04 · Privacidade inicial)
  Widget _buildStep3(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.fileGuardColors;

    return ListView(
      padding: AppSpacing.screenPadding.copyWith(
        top: AppSpacing.space16,
        bottom: AppSpacing.space32,
      ),
      children: <Widget>[
        Text(
          'Sobre a Análise',
          style: AppTypography.headline.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.space16),

        // Card Destaque: Hash vs Upload
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppShapes.borderLarge,
            border: Border.all(color: colors.neutral, width: AppShapes.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.lock_outline, size: 22, color: colors.neutral),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: Text(
                      'Consultar hash ≠ enviar arquivo',
                      style: AppTypography.cardTitle.copyWith(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'A consulta apenas transmite a impressão digital pública do arquivo. O envio transfere o arquivo binário completo ao VirusTotal.',
                style: AppTypography.bodyCompact.copyWith(color: colors.muted, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space16),

        // Parágrafos Explicativos de Transparência
        _buildBulletPoint(
          context,
          'Amostras enviadas podem ser compartilhadas com parceiros globais do VirusTotal. Nunca envie arquivos com dados pessoais ou confidenciais.',
        ),
        const SizedBox(height: AppSpacing.space12),
        _buildBulletPoint(
          context,
          'O FileGuard é uma ferramenta de triagem e não substitui uma solução de segurança de tempo real. Relatórios de terceiros podem conter falsos negativos.',
        ),
        const SizedBox(height: AppSpacing.space12),
        _buildBulletPoint(
          context,
          'Sua API Key pessoal conecta sua conta, respeitando suas cotas. Ela fica guardada exclusivamente no Android Keystore deste dispositivo.',
        ),

        const SizedBox(height: AppSpacing.space24),

        // Stepper Label
        Text(
          '03 / 03   •   PRIVACIDADE EM PRIMEIRO LUGAR',
          style: AppTypography.caption.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space16),

        FileGuardButton(
          label: 'Configurar minha API Key',
          onPressed: () => _finishOnboarding(goToSettings: true),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final colors = context.fileGuardColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Icon(Icons.check_circle_outline, size: 16, color: colors.neutral),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyCompact.copyWith(color: colors.muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}
