import 'package:flutter/services.dart';

/// Serviço para encaminhar APKs ao instalador nativo do Android após análise prévia.
class ApkInstallService {
  const ApkInstallService();

  static const MethodChannel _channel =
      MethodChannel('dev.andr3dav1d.fileguard/apk_installer');

  /// Abre o instalador nativo do sistema para o APK especificado.
  /// Só deve ser acionado por clique explícito do usuário após a exibição do relatório de ameaças.
  Future<bool> installApk(String filePath) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'installApk',
        {'filePath': filePath},
      );
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
