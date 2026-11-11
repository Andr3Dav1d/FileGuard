/// Representa o estado atual de validação e persistência da API Key do VirusTotal.
enum ApiKeyStatus {
  /// Nenhuma chave configurada no dispositivo.
  notConfigured,

  /// Validando chave com a API do VirusTotal.
  validating,

  /// Chave validada e ativa com sucesso.
  valid,

  /// Chave incorreta, inválida ou revogada (HTTP 401).
  invalid,

  /// Cota da chave atingida ou excedida (HTTP 429).
  quotaExceeded,

  /// Sem conexão com a internet ou erro de rede.
  networkError,

  /// Erro temporário do serviço ou falha inesperada (HTTP 5xx).
  temporaryError,
}

/// Extensão com mensagens amigáveis em pt-BR para cada estado da API Key.
extension ApiKeyStatusX on ApiKeyStatus {
  String get description {
    switch (this) {
      case ApiKeyStatus.notConfigured:
        return 'Nenhuma API Key configurada';
      case ApiKeyStatus.validating:
        return 'Validando chave com o VirusTotal...';
      case ApiKeyStatus.valid:
        return 'API Key configurada e válida';
      case ApiKeyStatus.invalid:
        return 'API Key inválida ou revogada';
      case ApiKeyStatus.quotaExceeded:
        return 'Limite de requisições excedido';
      case ApiKeyStatus.networkError:
        return 'Sem conexão para validar a chave';
      case ApiKeyStatus.temporaryError:
        return 'Instabilidade temporária no VirusTotal';
    }
  }

  bool get isValid => this == ApiKeyStatus.valid;
  bool get isValidating => this == ApiKeyStatus.validating;
}
