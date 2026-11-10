import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extensão de tema personalizada para acomodar tokens semânticos do FileGuard,
/// incluindo hierarquia planar de superfícies AMOLED e estados de risco.
@immutable
class FileGuardColors extends ThemeExtension<FileGuardColors> {
  final Color card;
  final Color surfaceHigh;
  final Color surfaceSecondary;
  final Color danger;
  final Color dangerContainer;
  final Color warning;
  final Color warningContainer;
  final Color neutral;
  final Color neutralContainer;
  final Color muted;
  final Color disabledText;
  final Color disabledContainer;
  final Color modalScrim;

  const FileGuardColors({
    required this.card,
    required this.surfaceHigh,
    required this.surfaceSecondary,
    required this.danger,
    required this.dangerContainer,
    required this.warning,
    required this.warningContainer,
    required this.neutral,
    required this.neutralContainer,
    required this.muted,
    required this.disabledText,
    required this.disabledContainer,
    required this.modalScrim,
  });

  /// Instância configurada para o Tema Claro.
  static const FileGuardColors light = FileGuardColors(
    card: AppColors.lightCard,
    surfaceHigh: AppColors.lightSurfaceHigh,
    surfaceSecondary: AppColors.lightSurfaceSecondary,
    danger: AppColors.lightDanger,
    dangerContainer: AppColors.lightDangerContainer,
    warning: AppColors.lightWarning,
    warningContainer: AppColors.lightWarningContainer,
    neutral: AppColors.lightNeutral,
    neutralContainer: AppColors.lightNeutralContainer,
    muted: AppColors.lightMuted,
    disabledText: AppColors.lightDisabledText,
    disabledContainer: AppColors.lightDisabledContainer,
    modalScrim: AppColors.modalScrim,
  );

  /// Instância configurada para o Tema Escuro AMOLED.
  static const FileGuardColors dark = FileGuardColors(
    card: AppColors.darkCard,
    surfaceHigh: AppColors.darkSurfaceHigh,
    surfaceSecondary: AppColors.darkSurfaceSecondary,
    danger: AppColors.darkDanger,
    dangerContainer: AppColors.darkDangerContainer,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningContainer,
    neutral: AppColors.darkNeutral,
    neutralContainer: AppColors.darkNeutralContainer,
    muted: AppColors.darkMuted,
    disabledText: AppColors.darkDisabledText,
    disabledContainer: AppColors.darkDisabledContainer,
    modalScrim: AppColors.modalScrim,
  );

  @override
  FileGuardColors copyWith({
    Color? card,
    Color? surfaceHigh,
    Color? surfaceSecondary,
    Color? danger,
    Color? dangerContainer,
    Color? warning,
    Color? warningContainer,
    Color? neutral,
    Color? neutralContainer,
    Color? muted,
    Color? disabledText,
    Color? disabledContainer,
    Color? modalScrim,
  }) {
    return FileGuardColors(
      card: card ?? this.card,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      neutral: neutral ?? this.neutral,
      neutralContainer: neutralContainer ?? this.neutralContainer,
      muted: muted ?? this.muted,
      disabledText: disabledText ?? this.disabledText,
      disabledContainer: disabledContainer ?? this.disabledContainer,
      modalScrim: modalScrim ?? this.modalScrim,
    );
  }

  @override
  FileGuardColors lerp(ThemeExtension<FileGuardColors>? other, double t) {
    if (other is! FileGuardColors) return this;

    return FileGuardColors(
      card: Color.lerp(card, other.card, t) ?? card,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t) ?? surfaceHigh,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ??
              surfaceSecondary,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      dangerContainer:
          Color.lerp(dangerContainer, other.dangerContainer, t) ??
              dangerContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
              warningContainer,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
      neutralContainer:
          Color.lerp(neutralContainer, other.neutralContainer, t) ??
              neutralContainer,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      disabledText:
          Color.lerp(disabledText, other.disabledText, t) ?? disabledText,
      disabledContainer:
          Color.lerp(disabledContainer, other.disabledContainer, t) ??
              disabledContainer,
      modalScrim: Color.lerp(modalScrim, other.modalScrim, t) ?? modalScrim,
    );
  }
}

/// Extensão de conveniência no BuildContext para acesso rápido aos tokens semânticos.
extension FileGuardColorsContext on BuildContext {
  FileGuardColors get fileGuardColors {
    final colors = Theme.of(this).extension<FileGuardColors>();
    assert(
      colors != null,
      'FileGuardColors não foi encontrado no ThemeData atual. '
      'Certifique-se de registrar a extensão no ThemeData.',
    );
    return colors ?? FileGuardColors.light;
  }
}
