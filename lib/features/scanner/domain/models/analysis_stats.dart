/// Estatísticas consolidadas dos motores de análise do VirusTotal.
class AnalysisStats {
  const AnalysisStats({
    this.malicious = 0,
    this.suspicious = 0,
    this.undetected = 0,
    this.harmless = 0,
    this.timeout = 0,
    this.failure = 0,
    this.typeUnsupported = 0,
  });

  final int malicious;
  final int suspicious;
  final int undetected;
  final int harmless;
  final int timeout;
  final int failure;
  final int typeUnsupported;

  int get totalEngines =>
      malicious +
      suspicious +
      undetected +
      harmless +
      timeout +
      failure +
      typeUnsupported;

  factory AnalysisStats.fromJson(Map<String, dynamic> json) {
    return AnalysisStats(
      malicious: (json['malicious'] as num?)?.toInt() ?? 0,
      suspicious: (json['suspicious'] as num?)?.toInt() ?? 0,
      undetected: (json['undetected'] as num?)?.toInt() ?? 0,
      harmless: (json['harmless'] as num?)?.toInt() ?? 0,
      timeout: ((json['timeout'] as num?)?.toInt() ?? 0) +
          ((json['confirmed-timeout'] as num?)?.toInt() ?? 0) +
          ((json['confirmed_timeout'] as num?)?.toInt() ?? 0),
      failure: (json['failure'] as num?)?.toInt() ?? 0,
      typeUnsupported: (json['type-unsupported'] as num?)?.toInt() ??
          (json['type_unsupported'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
    'malicious': malicious,
    'suspicious': suspicious,
    'undetected': undetected,
    'harmless': harmless,
    'timeout': timeout,
    'failure': failure,
    'type-unsupported': typeUnsupported,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisStats &&
          runtimeType == other.runtimeType &&
          malicious == other.malicious &&
          suspicious == other.suspicious &&
          undetected == other.undetected &&
          harmless == other.harmless &&
          timeout == other.timeout &&
          failure == other.failure &&
          typeUnsupported == other.typeUnsupported;

  @override
  int get hashCode =>
      malicious.hashCode ^
      suspicious.hashCode ^
      undetected.hashCode ^
      harmless.hashCode ^
      timeout.hashCode ^
      failure.hashCode ^
      typeUnsupported.hashCode;

  @override
  String toString() =>
      'AnalysisStats(malicious: $malicious, suspicious: $suspicious, undetected: $undetected, harmless: $harmless, timeout: $timeout, failure: $failure, typeUnsupported: $typeUnsupported)';
}
