/// Total de votos da comunidade no VirusTotal.
class TotalVotes {
  const TotalVotes({
    this.harmless = 0,
    this.malicious = 0,
  });

  final int harmless;
  final int malicious;

  factory TotalVotes.fromJson(Map<String, dynamic> json) {
    return TotalVotes(
      harmless: (json['harmless'] as num?)?.toInt() ?? 0,
      malicious: (json['malicious'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'harmless': harmless,
    'malicious': malicious,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TotalVotes &&
          runtimeType == other.runtimeType &&
          harmless == other.harmless &&
          malicious == other.malicious;

  @override
  int get hashCode => harmless.hashCode ^ malicious.hashCode;

  @override
  String toString() => 'TotalVotes(harmless: $harmless, malicious: $malicious)';
}
