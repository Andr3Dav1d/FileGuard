import 'package:file_picker/file_picker.dart';

import 'package:fileguard/features/scanner/domain/models/selected_file_info.dart';
import 'sha256_calculator.dart';

/// Serviço para seleção de arquivos utilizando o Storage Access Framework (SAF) nativo do Android.
class FilePickerService {
  FilePickerService({
    Sha256Calculator? hashCalculator,
  }) : _hashCalculator = hashCalculator ?? const Sha256Calculator();

  final Sha256Calculator _hashCalculator;

  /// Abre o seletor de documentos do Android e calcula o hash SHA-256 do arquivo selecionado.
  Future<SelectedFileInfo?> pickAndProcessFile() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.any,
    );

    if (file == null) {
      return null;
    }

    final name = file.name;
    final size = (await file.length()) ?? file.lengthSync() ?? 0;
    final filePath = file.path ?? file.uri.toString();

    // Calcula SHA-256 em streaming via XFile
    final stream = file.xFile.openRead();
    final sha256Hash = await _hashCalculator.calculateFromStream(stream);

    // Identifica MIME básico a partir da extensão
    final lowerName = name.toLowerCase();
    String? mimeType;
    if (lowerName.endsWith('.apk')) {
      mimeType = 'application/vnd.android.package-archive';
    } else if (lowerName.endsWith('.pdf')) {
      mimeType = 'application/pdf';
    } else if (lowerName.endsWith('.zip')) {
      mimeType = 'application/zip';
    } else if (lowerName.endsWith('.exe')) {
      mimeType = 'application/x-msdownload';
    }

    return SelectedFileInfo(
      name: name,
      size: size,
      path: filePath,
      mimeType: mimeType,
      sha256: sha256Hash,
    );
  }
}
