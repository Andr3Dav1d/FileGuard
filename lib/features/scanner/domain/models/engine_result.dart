/// Resultado individual de um motor antivírus.
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

  bool get isMalicious => category == 'malicious';
  bool get isSuspicious => category == 'suspicious';

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
    'result': result,
    'method': method,
    'engine_version': engineVersion,
    'engine_update': engineUpdate,
  };
}
