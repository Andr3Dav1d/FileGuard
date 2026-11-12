/// Categorias semânticas de detecção retornadas pelos motores no VirusTotal.
enum EngineCategory {
  malicious,
  suspicious,
  undetected,
  harmless,
  timeout,
  failure,
  typeUnsupported,
  unknown;

  static EngineCategory fromString(String? category) {
    if (category == null) return EngineCategory.unknown;
    switch (category.toLowerCase().trim()) {
      case 'malicious':
        return EngineCategory.malicious;
      case 'suspicious':
        return EngineCategory.suspicious;
      case 'undetected':
        return EngineCategory.undetected;
      case 'harmless':
        return EngineCategory.harmless;
      case 'timeout':
      case 'confirmed-timeout':
        return EngineCategory.timeout;
      case 'failure':
        return EngineCategory.failure;
      case 'type-unsupported':
      case 'type_unsupported':
        return EngineCategory.typeUnsupported;
      default:
        return EngineCategory.unknown;
    }
  }
}

/// Resultado individual de um motor antivírus no VirusTotal.
class EngineResult {
  const EngineResult({
    required this.engineName,
    required this.category,
    this.result,
    this.method,
    this.engineVersion,
    this.engineUpdate,
  });

  final String engineName;
  final String category;
  final String? result;
  final String? method;
  final String? engineVersion;
  final String? engineUpdate;

  /// Categoria semântica normalizada do motor.
  EngineCategory get engineCategory => EngineCategory.fromString(category);

  bool get isMalicious => engineCategory == EngineCategory.malicious;
  bool get isSuspicious => engineCategory == EngineCategory.suspicious;
  bool get isUndetected => engineCategory == EngineCategory.undetected;
  bool get isHarmless => engineCategory == EngineCategory.harmless;
  bool get isTimeout => engineCategory == EngineCategory.timeout;
  bool get isFailure => engineCategory == EngineCategory.failure;
  bool get isTypeUnsupported => engineCategory == EngineCategory.typeUnsupported;

  factory EngineResult.fromJson(String name, Map<String, dynamic> json) {
    return EngineResult(
      engineName: (json['engine_name'] as String?) ?? name,
      category: (json['category'] as String?) ?? 'undetected',
      result: json['result'] as String?,
      method: json['method'] as String?,
      engineVersion: json['engine_version'] as String?,
      engineUpdate: json['engine_update'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'engine_name': engineName,
    'category': category,
    if (result != null) 'result': result,
    if (method != null) 'method': method,
    if (engineVersion != null) 'engine_version': engineVersion,
    if (engineUpdate != null) 'engine_update': engineUpdate,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngineResult &&
          runtimeType == other.runtimeType &&
          engineName == other.engineName &&
          category == other.category &&
          result == other.result &&
          method == other.method &&
          engineVersion == other.engineVersion &&
          engineUpdate == other.engineUpdate;

  @override
  int get hashCode =>
      engineName.hashCode ^
      category.hashCode ^
      result.hashCode ^
      method.hashCode ^
      engineVersion.hashCode ^
      engineUpdate.hashCode;

  @override
  String toString() =>
      'EngineResult(engineName: $engineName, category: $category, result: $result)';
}
