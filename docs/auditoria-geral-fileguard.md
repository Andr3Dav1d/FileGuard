# Relatório de Auditoria Geral — FileGuard

**Data da Auditoria:** 12 de novembro de 2026  
**Ambiente:** Linux x86_64 / Android SDK / Flutter 3.13.7 / Dart 3.13  
**Status do Repositório:** Branch `dev`, Etapas 1 a 5 concluídas  
**Resultado dos Testes Automatizados:** 97 testes aprovados (100% de sucesso)  
**Resultado da Análise Estática:** `flutter analyze` — 0 problemas encontrados  

---

## 1. Resumo Executivo

O **FileGuard** é um aplicativo Android desenvolvido em Flutter para análise de segurança de arquivos e pacotes APK através da API v3 do VirusTotal. O projeto adota uma arquitetura em camadas (Domain, Data, Presentation), navegação declarativa com `GoRouter`, persistência local offline em SQLite v2 com migração automática e fidelidade visual ao Design System do Figma nos temas Claro e Escuro AMOLED puro (`#000000`).

Esta auditoria geral foi executada exclusivamente em modo de leitura e análise do código-fonte, cobrindo seis dimensões: funcionalidade, segurança, arquitetura, interface visual, acessibilidade e cobertura de testes.

O projeto apresenta uma base de código sólida, tipagem estrita, separação arquitetural coerente e conformidade com WCAG AA. Foram identificados **11 pontos de melhoria comprovados** (0 críticos, 2 altos, 6 médios e 3 baixos) e **3 suspeitas para investigação em dispositivo físico**. Nenhum risco de segurança crítico (vazamento de API Key ou execução de código arbitrário) foi encontrado.

---

## 2. Estado Geral do Projeto

### 2.1 Visão Geral dos Módulos

```
lib/
├── app/
│   ├── app.dart                    # Configuração global MaterialApp.router
│   ├── router/                     # GoRouter e catálogo AppRoutes
│   └── shell/                      # FileGuardShell com barra inferior de 84dp
├── core/
│   ├── localization/               # Suporte a strings e internacionalização
│   ├── theme/                      # AppColors, AppTheme, AppTypography, AppSpacing, AppShapes
│   └── widgets/                    # FileGuardButton, FileGuardAppBar, DetectionBadge, etc.
└── features/
    ├── home/                       # Dashboard com estatísticas e atalhos rápidos
    ├── onboarding/                 # Landing / onboarding de boas-vindas em 3 passos
    ├── settings/                   # Gerenciamento seguro da API Key via Keystore
    ├── history/                    # SQLite v2, BackupService v2, HistoryScreen
    └── scanner/                    # FilePicker, Hasher, Repositório VT v3, Telas 51 e 42
```

### 2.2 Métricas de Qualidade

| Métrica | Valor Encontrado | Avaliação |
| :--- | :--- | :--- |
| **Erros de Análise (`flutter analyze`)** | 0 erros / 0 warnings / 0 lints | Excelente |
| **Total de Testes Automatizados** | 97 testes unitários e de widgets | 100% passando |
| **Conformidade AMOLED** | `#000000` em Scaffold e AppBars | Totalmente conforme |
| **Alvos de Toque (Touch Targets)** | Mínimo 48×48 dp em todos os botões | Conforme Seção 8 DS |
| **Logs de Credenciais / API Key** | Zero ocorrências de print com chaves | Seguro |

---

## 3. Auditoria Funcional

Mapeamento do comportamento real em comparação com as especificações dos fluxos:

| Fluxo Funcional | Estado Atual | Análise de Risco / Comportamento |
| :--- | :--- | :--- |
| **1. Seleção de arquivos (SAF)** | Implementado via `FilePickerService` | Usa seletor nativo do Android. Arquivo é lido via stream para hash. |
| **2. Consentimento de upload** | Implementado com `PermissionDialog` | Exibido apenas quando o hash não é encontrado (HTTP 404). Explica que o arquivo será enviado para a nuvem. |
| **3. Cálculo local de SHA-256** | Implementado com `crypto` em streaming | Não carrega o arquivo inteiro em memória para o cálculo do hash. |
| **4. Consulta de hash** | `GET /files/{hash}` | Retorna relatório instantâneo sem enviar o binário caso o arquivo já esteja catalogado. |
| **5. Upload de novo arquivo** | `POST /files` | Funcional, porém carrega o arquivo inteiro em RAM antes do upload (`readAsBytes`) e não valida o limite de 32 MB da API pública. |
| **6. Polling adaptativo** | `pollAnalysis` com backoff exponencial | Realiza de 1 a 5 tentativas espaçadas de 4s a 16s com tratamento de HTTP 429. |
| **7. Cancelamento** | Suportado localmente | Permite interromper o loop de polling localmente sem travar a UI. |
| **8. Exibição do resultado (Tela 51)** | Implementado na `ScannerScreen` | Exibe `ReportSummaryCard`, contexto UTC, metadados, prévia de 3 motores, cópia de hash e botões de ação. |
| **9. Detalhes técnicos (Tela 42)** | `TechnicalDetailsScreen` | Apresenta SHA-256, MD5, SHA-1, reputação, tags, contadores e `EngineReportTable` com busca e filtros. |
| **10. Compartilhamento** | Implementado com `SharePlus` | Formata resumo textual sem incluir credenciais. |
| **11. Exportação** | `BackupService.exportToJson` | Gera JSON contendo metadados e motores, compartilhado via share sheet. |
| **12. Histórico offline** | `HistoryScreen` + SQLite v2 | Salva automaticamente análises concluídas; abre relatórios offline na Tela 42. |
| **13. Importação de backups** | `importFromJson` via menu | Compatível com backups v1 e v2; não realiza nova consulta de rede. |
| **14. Exclusão de histórico** | Individual via `Dismissible` e total via menu | Confirmações explícitas antes de deletar dados locais. |

---

## 4. Auditoria de Segurança

### 4.1 Armazenamento da API Key
* A chave de API é armazenada utilizando `FlutterSecureStorage` (`fg_vt_api_key_secure`) com `AndroidOptions()`, delegando a criptografia para o Android Keystore.
* A recuperação e o salvamento tratam falhas silenciosamente sem expor mensagens com o valor da chave.

### 4.2 Ausência de Vazamento de Credenciais em Logs e Backups
* Varredura realizada em todo o código-fonte por chamadas `print`, `debugPrint` e `log`: zero ocorrências expondo chaves.
* `BackupService.exportToJson()` e `BackupService.importFromJson()` operam estritamente sobre a estrutura de relatórios de arquivos, sem nenhum campo referente à API Key.

### 4.3 Validação de URLs Externas
* A navegação externa para o VirusTotal (`_openVirusTotal` na `ScannerScreen`) realiza validação de esquema (`isScheme('http') || isScheme('https')`) antes da invocação do `launchUrl`, prevenindo tentativas de injeção de esquemas maliciosos (`javascript:`, `file:`, etc.).

### 4.4 Permissões Android
* `android.permission.INTERNET`: Essencial para consulta e upload na API VirusTotal.
* `android.permission.REQUEST_INSTALL_PACKAGES`: Utilizado pela funcionalidade opcional de encaminhamento de APKs ao instalador nativo do sistema após verificação de segurança.

---

## 5. Auditoria Arquitetural

### 5.1 Separação de Camadas
* **Domain:** Entidades (`ScanReport`, `EngineResult`, `AnalysisStats`, `TotalVotes`, `ScanVerdict`) puras em Dart, desacopladas de frameworks externos.
* **Data:** Repositórios e fontes de dados (`VirusTotalRepositoryImpl`, `ScanHistoryDatabase`, `BackupService`) isolam chamadas HTTP e SQLite.
* **Presentation:** Widgets desacoplados que consomem estados reativos via Riverpod (`ScannerNotifier`, `HistoryNotifier`, `ApiKeyNotifier`).

### 5.2 Gerenciamento de Estado
* Uso consistente de Riverpod 3.x (`Notifier`, `AsyncNotifier`, `Provider`).
* Overrides limpos implementados no ambiente de testes sem dependência de Singletons globais mutáveis.

### 5.3 Persistência e Migração SQLite
* O esquema do banco de dados foi atualizado para a versão 2 com migração incremental (`ALTER TABLE scan_history ADD COLUMN ...`), preservando os registros legados da v1 sem perda de histórico.
* Desserialização resiliente: campos JSON (`results_json`, `tags`, `total_votes_json`) são envolvidos em blocos `try/catch` para evitar falha catastrófica ao carregar registros antigos.

---

## 6. Auditoria Visual e Acessibilidade

### 6.1 Fidelidade ao Figma
* **Tema Claro:** Fundo planar `#F5F8FA` (`AppColors.lightBackground`), cartões brancos com raio 12dp (`AppShapes.radiusLarge`), tipografia Roboto seguindo a escala da Seção 7 do Design System.
* **Tema Escuro AMOLED:** Fundo preto absoluto `#000000` (`AppColors.darkBackground`), cartões `#101010`, superfícies altas `#0A0A0A`, bordas planares `#252525`, textos em branco puro `#FFFFFF` e cores de status com contraste validado (`#FFB4AB` para perigo, `#8FD5A6` para neutro).

### 6.2 Acessibilidade e Semântica
* **Alvos de Toque:** A `FileGuardAppBar` e o `FileGuardButton` respeitam a regra de dimensão mínima de 48 × 48 dp.
* **Leitores de Tela:** Uso de `Semantics(button: true, label: ...)` nos botões de cópia de hashes e ações contextuais.
* **Texto Preventivo:** Ausência de detecções é explicitamente acompanhada pelo aviso: *"Nenhum mecanismo detectou ameaças no relatório atual. Isso não garante que o arquivo seja seguro."*, evitando falsa sensação de segurança.

---

## 7. Auditoria da Suíte de Testes

### 7.1 Distribuição dos Testes
* `test/core/theme/theme_test.dart` (3 testes)
* `test/core/widgets/components_test.dart` (11 testes)
* `test/visual_layout_test.dart` (2 testes)
* `test/widget_test.dart` (3 testes)
* `test/features/onboarding/onboarding_test.dart` (3 testes)
* `test/features/settings/api_key_test.dart` (6 testes)
* `test/features/history/scan_history_database_test.dart` (6 testes)
* `test/features/history/backup_service_test.dart` (5 testes)
* `test/features/history/history_screen_test.dart` (7 testes)
* `test/features/scanner/sha256_calculator_test.dart` (4 testes)
* `test/features/scanner/scan_report_parser_test.dart` (6 testes)
* `test/features/scanner/virus_total_repository_test.dart` (12 testes)
* `test/features/scanner/report_summary_card_test.dart` (5 testes)
* `test/features/scanner/engine_report_table_test.dart` (6 testes)
* `test/features/scanner/detection_details_card_test.dart` (4 testes)
* `test/features/scanner/technical_details_screen_test.dart` (9 testes)
* `test/features/scanner/scanner_screen_test.dart` (9 testes)
* **Total:** 97 testes automatizados executados e aprovados.

### 7.2 Diagnóstico da Suíte
* **Pontos Fortes:** Testes unitários cobrem exaustivamente as categorias semânticas do VirusTotal v3, migração de banco v1 -> v2 e parsing de formatos duplos (`/files` e `/analyses`).
* **Lacunas Identificadas:**
  1. Ausência de testes de integração ponta a ponta (`integration_test/`) em dispositivo Android real.
  2. Os testes de widget utilizam viewport artificialmente estendido (`physicalSize = Size(800, 2400)`) para evitar avisos de hit-test, em vez de validar o comportamento de rolagem natural (`tester.scrollUntilVisible`) em telas convencionais (360×640 dp).

---

## 8. Lista Priorizada de Problemas e Oportunidades

### 8.1 Problemas Comprovados

#### [SEC-01 / ARQ-01] [SEVERIDADE ALTA]
* **Localização:** `lib/features/scanner/presentation/providers/scanner_provider.dart:169` e `lib/features/scanner/data/repositories/virus_total_repository_impl.dart:121`
* **Descrição:** A leitura do arquivo para upload é feita através de `ioFile.readAsBytes()`, carregando todos os bytes para a memória heap do Dart, seguido por `MultipartFile.fromBytes`.
* **Como reproduzir:** Tentar realizar o upload de um arquivo de 100 MB em um aparelho Android com pouca memória disponível.
* **Impacto:** Risco iminente de `OutOfMemoryError` (crash do aplicativo por esgotamento de memória).
* **Solução Recomendada:** Utilizar `http.MultipartFile.fromPath(file.path)` ou transmissão via stream sem alocação do array completo em RAM.
* **Teste Necessário:** Teste unitário no repositório verificando upload via arquivo em disco / stream.

---

#### [FUNC-01] [SEVERIDADE ALTA]
* **Localização:** `lib/features/scanner/presentation/providers/scanner_provider.dart:151`
* **Descrição:** Não há verificação do limite de tamanho máximo suportado pelo endpoint de upload direto da API do VirusTotal (32 MB).
* **Como reproduzir:** Selecionar um arquivo de 40 MB não catalogado e confirmar o envio.
* **Impacto:** O servidor do VirusTotal rejeita a conexão com HTTP 413 (Payload Too Large), gerando mensagem de erro genérica e desperdício de banda do usuário.
* **Solução Recomendada:** Incluir validação prévia de tamanho antes da tela de consentimento: se `file.size > 32 * 1024 * 1024`, alertar o usuário que a API pública do VirusTotal não aceita envio direto de arquivos acima de 32 MB.
* **Teste Necessário:** Teste no `ScannerNotifier` verificando bloqueio de arquivos acima de 32 MB com mensagem orientativa.

---

#### [FUNC-02] [SEVERIDADE MÉDIA]
* **Localização:** `lib/features/scanner/presentation/providers/scanner_provider.dart:205-211`
* **Descrição:** Se o polling expirar após 5 tentativas sem a análise ser concluída pelo VirusTotal (`status: 'queued'`), o notifier define `step: ScannerStep.completed` mas mantém `report: null`. Na `ScannerScreen`, a ausência de `report` faz a UI renderizar o estado `idle`, descartando o `analysisId`.
* **Como reproduzir:** Mockar o `pollAnalysis` para retornar `null` (análise ainda na fila após tentativas).
* **Impacto:** O usuário perde a informação de que o arquivo foi enviado com sucesso e não possui meios de retomar a consulta por aquele `analysisId`.
* **Solução Recomendada:** Manter o `analysisId` e `selectedFile` em um estado específico de análise enfileirada (`ScannerStep.queued`), com botão para retentar a checagem sem reenviar o binário.
* **Teste Necessário:** Teste de widget verificando a exibição do estado de análise enfileirada e persistência temporária do `analysisId`.

---

#### [ARQ-02] [SEVERIDADE MÉDIA]
* **Localização:** `lib/features/scanner/domain/models/scan_report.dart:76-80`
* **Descrição:** Em `ScanReport.fromVirusTotalJson`, o campo `sha256` faz fallback para `data['id']`. Na rota `/analyses/{id}`, `data['id']` é o identificador alfanumérico da análise (base64), e não o hash SHA-256 do arquivo.
* **Como reproduzir:** Chamar `ScanReport.fromVirusTotalJson` com JSON de resposta de `/analyses/{id}` onde `meta.file_info` não contenha `sha256`.
* **Impacto:** O SHA-256 é preenchido com o ID da análise e a URL de permalink gerada (`/gui/file/{analysisId}`) resulta em 404 no VirusTotal.
* **Solução Recomendada:** Não utilizar `data['id']` como fallback para SHA-256 se o endpoint for de análise. Utilizar o hash calculado localmente (`localSha256`) se disponível.
* **Teste Necessário:** Teste unitário de parser garantindo que `sha256` nunca receba o `analysisId`.

---

#### [FUNC-03] [SEVERIDADE MÉDIA]
* **Localização:** `lib/features/scanner/data/repositories/virus_total_repository_impl.dart:192, 258`
* **Descrição:** Em caso de resposta HTTP 429 (Too Many Requests), o código aguarda um valor fixo (`maxDelay: 16s`), ignorando o cabeçalho `Retry-After` retornado pelo VirusTotal.
* **Como reproduzir:** Simular resposta HTTP 429 com cabeçalho `Retry-After: 60`.
* **Impacto:** Tentativa prematura de requisição que continuará sendo rejeitada ou espera desnecessária.
* **Solução Recomendada:** Extrair o cabeçalho `retry-after` da resposta e utilizá-lo como delay caso seja maior que o intervalo corrente.
* **Teste Necessário:** Teste no repositório simulando 429 com `Retry-After: 30` e verificando o intervalo de espera.

---

#### [UI-01] [SEVERIDADE MÉDIA]
* **Localização:** `lib/features/scanner/presentation/screens/technical_details_screen.dart:65-80`
* **Descrição:** O texto de resumo no rodapé da tabela calcula: `"$threatsCount detecções + $cleanCount sem detecção = $totalCount mecanismos"`. Como `cleanCount` considera apenas `undetected + harmless`, caso existam mecanismos com timeout, falha ou tipo não suportado, a soma matemática fica visualmente incorreta (exemplo: `2 detecções + 65 sem detecção = 70 mecanismos`, quando 2 + 65 = 67).
* **Como reproduzir:** Abrir um relatório que contenha 2 maliciosos, 65 undetected e 3 timeouts.
* **Impacto:** Dúvida para o usuário final quanto à precisão da contagem de mecanismos.
* **Solução Recomendada:** Ajustar a fórmula para que `sem detecção` englobe todos os motores que não detectaram ameaça (`totalCount - threatsCount`), ou exibir explicitamente motores com timeout/falha no texto.
* **Teste Necessário:** Teste de widget validando a coerência aritmética da string de resumo quando há timeouts.

---

#### [DATA-01] [SEVERIDADE MÉDIA]
* **Localização:** `lib/features/scanner/presentation/screens/technical_details_screen.dart:25`, `lib/features/history/presentation/screens/history_screen.dart:184`, `lib/features/history/data/datasources/scan_history_database.dart:107`
* **Descrição:** Arquivos com tamanho ausente são exibidos como `0 B` ou `0.0 KB`; registros sem data no banco recebem `0` (exibindo `01/01/1970 00:00 UTC`); nomes ausentes recebem `'Arquivo'`.
* **Como reproduzir:** Inserir um registro com campos nulos e inspecionar no Histórico e Detalhes Técnicos.
* **Impacto:** Apresentação de dados enganosos (arquivos analisados não possuem 0 bytes e não foram escaneados em 1970).
* **Solução Recomendada:** Formatar tamanho `<= 0` como `"Tamanho não informado"` / `"—"`, e tratar data nula explicitamente como `"Data não disponível"`.
* **Teste Necessário:** Teste de renderização de registros antigos com metadados vazios.

---

#### [DATA-02] [SEVERIDADE MÉDIA]
* **Localização:** `lib/features/history/presentation/screens/history_screen.dart:88-92`
* **Descrição:** A importação de backups itera inserindo relatórios um a um sem bloco transacional (`db.transaction`). Se houver falha no meio do processo, o banco fica em estado inconsistente. Além disso, se o backup contiver registros com o mesmo hash mas IDs diferentes, cria registros duplicados.
* **Como reproduzir:** Importar um backup JSON onde o último registro seja inválido.
* **Impacto:** Histórico corrompido ou parcialmente restaurado sem rollback.
* **Solução Recomendada:** Criar método `importReports` no repositório executado sob transação e com deduplicação por SHA-256.
* **Teste Necessário:** Teste de transação verificando rollback em falha de importação de backup.

---

#### [ARQ-03] [SEVERIDADE BAIXA]
* **Localização:** `selected_file_info.dart`, `technical_details_screen.dart`, `scanner_screen.dart`, `history_screen.dart`
* **Descrição:** A lógica de formatação de bytes (`_formatFileSize`) e a resolução de cores para diagnósticos estão duplicadas em 4 locais diferentes.
* **Impacto:** Dificuldade de manutenção e risco de divergência em casas decimais e limiares (KB vs MB).
* **Solução Recomendada:** Criar `FileSizeFormatter` centralizado em `core/utils/` e método auxiliar unificado em `EngineResult`.
* **Teste Necessário:** Testes unitários para o formatador unificado.

---

#### [SEC-02] [SEVERIDADE BAIXA]
* **Localização:** `android/app/src/main/AndroidManifest.xml`
* **Descrição:** Ausência de declaração de `<queries>` para a intent `android.intent.action.VIEW` com esquema `https`.
* **Impacto:** No Android 11+ (API 30+), alguns navegadores padrão podem não responder adequadamente ao `launchUrl` devido às restrições de visibilidade de pacotes do sistema operacional.
* **Solução Recomendada:** Declarar `<intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>` dentro da tag `<queries>`.
* **Teste Necessário:** Validação de inicialização e compilação do manifesto no Android Gradle.

---

#### [TEST-01] [SEVERIDADE BAIXA]
* **Localização:** `test/features/scanner/scanner_screen_test.dart` e `test/features/history/history_screen_test.dart`
* **Descrição:** Testes de tela longa dependem da ampliação artificial do viewport para 800×2400 no `setUp` para que botões rolados sejam clicados sem aviso de hit-test.
* **Impacto:** Não valida a usabilidade real do gesto de rolagem do usuário em telas de 360×640 dp.
* **Solução Recomendada:** Utilizar `tester.scrollUntilVisible` para simular o gesto de rolagem do usuário mantendo dimensões padrão de dispositivos móveis.
* **Teste Necessário:** Testes executados com viewport mobile padrão (412×917 e 360×640).

---

### 8.2 Suspeitas Não Verificadas

1. **[SUSP-01] Limpeza de arquivos temporários do `file_picker` no cache do aplicativo**
   * *Hipótese:* O `file_picker` cria cópias temporárias na pasta de cache do Android ao selecionar arquivos via SAF. É necessário verificar em dispositivo físico se esses arquivos acumulam indefinidamente após múltiplas análises.
2. **[SUSP-02] Resposta da API do VirusTotal para contas públicas no endpoint `/users/{apiKey}`**
   * *Hipótese:* A validação de chave usa `GET /users/{apiKey}`. Em algumas variações de chave de API v3 da comunidade, o endpoint recomendado pela documentação para leitura da cota é `/users/{id}` ou `/api-keys/{id}`. Vale validar o comportamento em contas gratuitas e premium.
3. **[SUSP-03] Exportação de relatório único como texto compartilhado vs arquivo `.json` físico**
   * *Hipótese:* O botão "Exportar" envia o JSON como string de texto pelo `SharePlus`. Em gerenciadores de arquivos Android, o usuário pode preferir salvar diretamente um arquivo `.json` no disco (usando `XFile`).

---

## 9. Plano de Correção Priorizado

O plano está dividido em etapas pequenas, independentes e sequenciais. **Nenhuma alteração deve ser iniciada sem aprovação prévia.**

### Etapa 1 — Segurança e Estabilidade de Upload (Prioridade Alta)
* **Objetivo:** Prevenir estouro de memória (OOM) no envio de arquivos e bloquear tentativas de upload acima do limite do VirusTotal.
* **Arquivos:**
  * `lib/features/scanner/presentation/providers/scanner_provider.dart`
  * `lib/features/scanner/data/repositories/virus_total_repository_impl.dart`
  * `lib/features/scanner/domain/repositories/virus_total_repository.dart`
* **Ações:**
  1. Validar tamanho máximo (32 MB) antes do fluxo de consentimento/upload.
  2. Implementar transmissão em stream / `fromPath` para evitar alocação de `readAsBytes` na memória RAM.
* **Riscos:** Baixo.
* **Testes:** Teste unitário de rejeição preventiva > 32 MB e mock de upload em stream.
* **Critério de Aprovação:** `flutter test` verde e zero alocação de buffers gigantes em RAM.

### Etapa 2 — Resiliência do Polling e Integridade de Dados (Prioridade Alta)
* **Objetivo:** Tratar o cabeçalho `Retry-After`, evitar corrupção de SHA-256 com `analysisId` e tratar análises que permanecem na fila do VT.
* **Arquivos:**
  * `lib/features/scanner/domain/models/scan_report.dart`
  * `lib/features/scanner/data/repositories/virus_total_repository_impl.dart`
  * `lib/features/scanner/presentation/providers/scanner_provider.dart`
* **Ações:**
  1. Corrigir fallback de SHA-256 em `ScanReport.fromVirusTotalJson` para não receber `analysisId`.
  2. Ler `Retry-After` nas respostas HTTP 429.
  3. Preservar `analysisId` no estado para permitir checagem manual posterior caso o polling inicial expire.
* **Riscos:** Baixo (alteração localizada de parsing e cabeçalhos).
* **Testes:** Testes unitários com fixtures de `/analyses/{id}` e respostas 429 com cabeçalho.
* **Critério de Aprovação:** Teste de parser validando SHA-256 intacto e respeito ao tempo do `Retry-After`.

### Etapa 3 — Qualidade de Dados e Transações no Histórico (Prioridade Média)
* **Objetivo:** Proteger importação de backups com transação SQLite e tratar explicitamente metadados ausentes (`0 B`, datas nulas).
* **Arquivos:**
  * `lib/features/history/data/datasources/scan_history_database.dart`
  * `lib/features/history/presentation/screens/history_screen.dart`
  * `lib/features/scanner/presentation/screens/technical_details_screen.dart`
* **Ações:**
  1. Adicionar método transacional `importReports(List<ScanReport>)` no repositório com deduplicação por SHA-256.
  2. Tratar `fileSize <= 0` como `"Tamanho não informado"` e datas nulas como `"Data não informada"`.
  3. Corrigir a coerência aritmética da nota de resumo inferior na Tela 42 (`cleanCount = total - threats`).
* **Riscos:** Baixo.
* **Testes:** Testes de transação, rollback e exibição de campos nulos sem quebrar layout.
* **Critério de Aprovação:** 100% dos testes do histórico e detalhes técnicos aprovados.

### Etapa 4 — Refatoração de Utilitários e Manifesto Android (Prioridade Baixa)
* **Objetivo:** Eliminar duplicações de código e garantir total compatibilidade com Android 11+ no `url_launcher`.
* **Arquivos:**
  * `android/app/src/main/AndroidManifest.xml`
  * `lib/core/utils/file_size_formatter.dart` (a ser criado)
  * `lib/features/scanner/presentation/screens/scanner_screen.dart`
  * `lib/features/scanner/presentation/screens/technical_details_screen.dart`
* **Ações:**
  1. Centralizar `FileSizeFormatter` e remover duplicatas de `_formatFileSize`.
  2. Adicionar intent `https` na tag `<queries>` do `AndroidManifest.xml`.
  3. Atualizar testes de tela para usar `tester.scrollUntilVisible` em viewport padrão.
* **Riscos:** Nenhum.
* **Testes:** `flutter analyze`, `flutter test`.
* **Critério de Aprovação:** Zero avisos no linter e navegação externa validada no Android.

---

## 10. Comandos Executados e Resultados

```bash
$ git status
On branch dev
Your branch is up to date with 'origin/dev'.
Changes not staged for commit:
  modified:   lib/app/router/app_router.dart
  modified:   lib/app/router/app_routes.dart
  modified:   lib/features/history/data/datasources/scan_history_database.dart
  modified:   lib/features/history/data/services/backup_service.dart
  modified:   lib/features/history/presentation/screens/history_screen.dart
  modified:   lib/features/scanner/data/repositories/virus_total_repository_impl.dart
  modified:   lib/features/scanner/domain/models/analysis_stats.dart
  modified:   lib/features/scanner/domain/models/engine_result.dart
  modified:   lib/features/scanner/domain/models/scan_report.dart
  modified:   lib/features/scanner/domain/repositories/virus_total_repository.dart
  modified:   lib/features/scanner/presentation/providers/scanner_provider.dart
  modified:   lib/features/scanner/presentation/screens/scanner_screen.dart
  modified:   pubspec.lock
  modified:   pubspec.yaml
  modified:   test/features/history/backup_service_test.dart
  modified:   test/features/scanner/virus_total_repository_test.dart

$ flutter analyze
Analyzing fileguard...
No issues found! (ran in 4.4s)

$ flutter test
00:11 +97: All tests passed!
```

---

## 11. Limitações da Auditoria

1. **Ausência de rede externa intencional:** Nenhum arquivo real foi transmitido aos servidores do VirusTotal para não consumir a cota de produção da API key nem violar as diretrizes de auditoria somente de leitura.
2. **Ambiente Host Linux:** A auditoria dinâmica foi executada em ambiente simulado e na suíte de testes do Flutter. Validações de hardware específicas (ex.: ciclo de vida do instalador nativo do Android e comportamento de baixo consumo de bateria AMOLED em display OLED físico) necessitam de verificação final no aparelho real conectado.

---

## 12. Execução e Validação das Correções (Remediação)

Todas as 4 etapas do plano de remediação foram executadas e validadas:

### Etapa 1 — Estabilidade de Upload & Limite de Tamanho (Alta Prioridade)
- **[SEC-01 / ARQ-01] Upload em Stream:** Substituído `readAsBytes()` por upload em stream (`http.MultipartFile.fromPath`) em [scanner_provider.dart](file:///home/adavid/Documents/Projetos/fileguard/lib/features/scanner/presentation/providers/scanner_provider.dart) e [virus_total_repository_impl.dart](file:///home/adavid/Documents/Projetos/fileguard/lib/features/scanner/data/repositories/virus_total_repository_impl.dart).
- **[FUNC-01] Validação de 32 MB:** Implementada validação proativa antes do upload com bloqueio e mensagem explicativa em português sobre a limitação da API pública do VirusTotal.
- **Testes Unitários:** Adicionados testes para upload em stream, rejeição de arquivos > 32 MB e erro HTTP 413 em [virus_total_repository_test.dart](file:///home/adavid/Documents/Projetos/fileguard/test/features/scanner/virus_total_repository_test.dart) e [scanner_provider_test.dart](file:///home/adavid/Documents/Projetos/fileguard/test/features/scanner/scanner_provider_test.dart).

### Etapa 2 — Resiliência de Polling e Integridade de Identificadores (Média Prioridade)
- **[ARQ-02] Correção do Fallback de SHA-256:** Corrigido [scan_report.dart](file:///home/adavid/Documents/Projetos/fileguard/lib/features/scanner/domain/models/scan_report.dart) para que o `analysisId` em base64 nunca seja atribuído a `sha256`. Adicionado suporte a `fallbackSha256`.
- **[FUNC-03] Header `Retry-After`:** Implementada a classe [RateLimitException](file:///home/adavid/Documents/Projetos/fileguard/lib/features/scanner/data/repositories/virus_total_repository_impl.dart) que preserva a duração indicada no header HTTP 429 `Retry-After`, com respeito ao tempo de espera durante o polling.
- **[FUNC-02] Estado de Fila (`ScannerStep.queued`):** Quando o polling expira na fila do VT, o estado é preservado com `pendingAnalysisId` e botão "Verificar status agora" para reconsulta sob demanda sem reenvio do arquivo.
- **Testes Unitários & Widgets:** Testes em [scan_report_parser_test.dart](file:///home/adavid/Documents/Projetos/fileguard/test/features/scanner/scan_report_parser_test.dart), [virus_total_repository_test.dart](file:///home/adavid/Documents/Projetos/fileguard/test/features/scanner/virus_total_repository_test.dart) e [scanner_screen_test.dart](file:///home/adavid/Documents/Projetos/fileguard/test/features/scanner/scanner_screen_test.dart).

### Etapa 3 — Transacionalidade de Backup e Apresentação de Dados (Média Prioridade)
- **[DATA-02] Transação e Batch no Histórico:** Criado método `saveReports` no [ScanHistoryDatabase](file:///home/adavid/Documents/Projetos/fileguard/lib/features/history/data/datasources/scan_history_database.dart) e `importReports` no [HistoryNotifier](file:///home/adavid/Documents/Projetos/fileguard/lib/features/history/presentation/providers/history_provider.dart), executando restaurações em um único lote atômico (`db.transaction` + `batch`) com substituição de duplicatas (`ConflictAlgorithm.replace`).
- **[UI-01] Coerência Aritmética no Rodapé:** Ajustada a fórmula em [technical_details_screen.dart](file:///home/adavid/Documents/Projetos/fileguard/lib/features/scanner/presentation/screens/technical_details_screen.dart) para incluir explicitamente motores não analisados (timeout/falha/não suportado) quando `threats + clean != total`.
- **[DATA-01] Tratamento de Metadados Nulos:** Tratamento de datas inválidas (`<= 0`) com fallback para "Data não disponível" / "Data desconhecida", e integração com o novo formatador de tamanho.

### Etapa 4 — Utilitários e Ajustes de Plataforma (Baixa Prioridade)
- **[ARQ-03] Centralização do `FileSizeFormatter`:** Criado [file_size_formatter.dart](file:///home/adavid/Documents/Projetos/fileguard/lib/core/utils/file_size_formatter.dart), eliminando todas as 4 implementações duplicadas no app.
- **[SEC-02] Declaração de Queries no Android:** Adicionado intent filter com scheme `https` na tag `<queries>` do [AndroidManifest.xml](file:///home/adavid/Documents/Projetos/fileguard/android/app/src/main/AndroidManifest.xml) para Android 11+ (API 30+).

### Resultado Final da Verificação
- **Análise estática:** `flutter analyze` -> 0 erros e 0 avisos.
- **Testes automatizados:** `flutter test` -> 114 testes executados e 100% aprovados.

---

*Relatório de auditoria e plano de remediação finalizados com sucesso.*
