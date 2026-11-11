# FileGuard — Arquitetura e Fluxo de Dados

Este documento descreve a arquitetura técnica, organização de camadas e fluxos de dados do **FileGuard**, alinhado ao plano mestre de implementação.

---

## 1. Visão Geral da Arquitetura

O FileGuard adota o padrão **Feature-First** combinado com princípios de **Clean Architecture** e separação estrita de responsabilidades:

```text
lib/
├── app/                  # Bootstrap, roteamento e casca da aplicação (GoRouter, Shell)
├── core/                 # Infraestrutura compartilhada (tema, tokens, widgets base, l10n)
└── features/             # Módulos funcionais independentes
    ├── home/             # Dashboard inicial e resumo de segurança
    ├── scanner/          # Fluxo de seleção, hash, análise e upload de arquivos
    ├── history/          # Persistência local SQLite de relatórios anteriores
    └── settings/         # Gerenciamento seguro da API Key e preferências
```

---

## 2. Camadas por Funcionalidade

Cada funcionalidade em `lib/features/<nome>/` é subdividida em camadas:

1. **Domain (`domain/`)**:
   - **Entidades e Value Objects**: Representam os conceitos centrais do negócio (ex.: `ScanReport`, `AnalysisStats`, `ApiKeyStatus`).
   - **Contratos (Interfaces)**: Repositórios abstratos (ex.: `ApiKeyRepository`, `VirusTotalRepository`, `ScanHistoryRepository`). Não possui dependência de frameworks externos ou bibliotecas de I/O.

2. **Data (`data/`)**:
   - **Data Sources**: Comunicação direta com armazenamento seguro (`flutter_secure_storage`), HTTP (`http`), SQLite (`sqflite`) ou canais nativos.
   - **DTOs / Mappers**: Serialização JSON da API VirusTotal v3 e mapeamento bidirecional para as entidades de domínio.
   - **Implementações de Repositório**: Implementam os contratos de domínio.

3. **Application / State (`presentation/providers/` ou `application/`)**:
   - Gerenciamento de estado com **Riverpod** (`AsyncNotifier`, `Notifier`).
   - Coordenação de fluxos e validações.

4. **Presentation (`presentation/`)**:
   - Telas (`screens/`) e componentes específicos de cada feature (`widgets/`).
   - Consumo de estado reativo e despacho de eventos aos notifiers.

---

## 3. Fluxos de Dados Principais

### 3.1 Ciclo de Vida da API Key

```mermaid
sequenceDiagram
    autonumber
    actor User as Usuário
    participant UI as SettingsScreen
    participant Notifier as ApiKeyNotifier
    participant Repo as ApiKeyRepository
    participant Storage as FlutterSecureStorage (KeyStore)
    participant VT as VirusTotal API v3

    User->>UI: Digita API Key e clica em Salvar
    UI->>Notifier: saveAndValidateKey(apiKey)
    Notifier->>Notifier: Emite ApiKeyStatus.validating
    Notifier->>VT: GET /api/v3/users/{apiKey} (Header: x-apikey)
    alt Chave Válida (HTTP 200)
        VT-->>Notifier: 200 OK + quotas/user data
        Notifier->>Repo: storeApiKey(apiKey)
        Repo->>Storage: write(key, EncryptedSharedPreferences)
        Notifier->>Notifier: Emite ApiKeyStatus.valid
    else Chave Inválida (HTTP 401)
        VT-->>Notifier: 401 Unauthorized
        Notifier->>Notifier: Emite ApiKeyStatus.invalid
    else Limite Excedido (HTTP 429)
        VT-->>Notifier: 429 QuotaExceeded
        Notifier->>Notifier: Emite ApiKeyStatus.quotaExceeded
    else Sem Conexão / Erro de Rede
        VT-->>Notifier: SocketException / Timeout
        Notifier->>Notifier: Emite ApiKeyStatus.networkError
    end
    Notifier-->>UI: Atualiza estado e feedback visual
```

### 3.2 Fluxo de Análise e Upload de Arquivos

```mermaid
sequenceDiagram
    autonumber
    actor User as Usuário
    participant ScannerUI as ScannerScreen
    participant SAF as Storage Access Framework (Android)
    participant HashCalc as Sha256StreamCalculator
    participant VTRepo as VirusTotalRepository
    participant HistoryRepo as ScanHistoryRepository

    User->>ScannerUI: Seleciona Arquivo
    ScannerUI->>SAF: Abre seletor de arquivos (ACTION_OPEN_DOCUMENT)
    SAF-->>ScannerUI: URI do arquivo + metadados (nome, tamanho)
    ScannerUI->>HashCalc: calculateSha256(fileStream)
    Note over HashCalc: Cálculo em streaming (sem carregar tudo na RAM)
    HashCalc-->>ScannerUI: Retorna hash SHA-256
    ScannerUI->>VTRepo: getReportByHash(sha256)
    alt Relatório Existe (HTTP 200)
        VTRepo-->>ScannerUI: Relatório encontrado com estatísticas
        ScannerUI->>HistoryRepo: Salva análise no histórico SQLite
        ScannerUI-->>User: Exibe relatório detalhado com DetectionBadge
    else Hash Não Encontrado (HTTP 404)
        VTRepo-->>ScannerUI: NotFoundError (Sem relatório disponível)
        ScannerUI-->>User: Exibe PermissionDialog para consentimento de upload
        alt Usuário autoriza
            User->>ScannerUI: Confirma upload
            ScannerUI->>VTRepo: uploadFile(stream, metadata)
            VTRepo-->>ScannerUI: Análise enfileirada (Analysis ID)
            ScannerUI->>VTRepo: pollAnalysis(analysisId)
            VTRepo-->>ScannerUI: Relatório concluído
            ScannerUI->>HistoryRepo: Salva no histórico local
            ScannerUI-->>User: Exibe resultado final
        else Usuário recusa
            User->>ScannerUI: Cancela
            ScannerUI-->>User: Mantém estado informativo (não analisado)
        end
    end
```

---

## 4. Diretrizes de Segurança e Privacidade

- **Isolamento de Credenciais**: A API Key nunca transita para o disco em texto não criptografado. No Android, o `flutter_secure_storage` utiliza `EncryptedSharedPreferences` com chaves assimétricas gerenciadas pelo Android Keystore.
- **Não Exposição de Segredos**: Logs, mensagens de erro (`debugPrint`, `print`, crash reports) são sanitizados e nunca registram a API Key ou cabeçalhos sensíveis.
- **Zero Retenção de Arquivos**: O aplicativo não mantém cópias locais dos arquivos analisados após o cálculo do hash ou envio consentido.
- **Consentimento Obrigatório**: Nenhuma requisição de upload de binário é executada sem aprovação explícita e específica do usuário para aquele arquivo.
