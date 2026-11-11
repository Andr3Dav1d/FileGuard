# Estratégia de Testes Automatizados — FileGuard

Este documento orienta sobre a execução, cobertura e cenários dos testes automatizados do **FileGuard**.

---

## 1. Execução dos Testes

Para executar toda a suíte de testes do projeto:
```bash
flutter test
```

Para executar a análise estática e verificação de regras de linter:
```bash
flutter analyze
```

---

## 2. Cenários e Módulos Cobertos

### 2.1 Tema, Design System e Regressão Visual
- `test/core/theme/theme_test.dart`:
  - Validação dos temas Claro e AMOLED (#000000).
  - Validação dos tokens `FileGuardColors` e interpolação (`lerp`).
- `test/core/widgets/components_test.dart`:
  - Validação dos 10 componentes reutilizáveis (`FileGuardButton`, `DetectionBadge`, `StatisticCard`, `FileListTile`, `ProgressCard`, `ApiKeyField`, `PermissionDialog`, `PreferenceSwitch`, `ScanFAB`, `FileGuardAppBar`).
  - Verificação de acessibilidade e alvos de toque mínimos de 48 dp.
- `test/visual_layout_test.dart`:
  - Validação de layout planar e ausência de overflows sob o viewport de referência do Figma (412 × 917 dp).

### 2.2 Gerenciamento Seguro da API Key
- `test/features/settings/api_key_test.dart`:
  - Gravação, leitura e remoção segura sem exposição de credenciais.
  - Validação real de status HTTP com mocks:
    - HTTP 200 -> `ApiKeyStatus.valid`
    - HTTP 401 -> `ApiKeyStatus.invalid`
    - HTTP 429 -> `ApiKeyStatus.quotaExceeded`
    - Chaves vazias -> `ApiKeyStatus.notConfigured`

### 2.3 Cálculo Criptográfico de Hash em Streaming
- `test/features/scanner/sha256_calculator_test.dart`:
  - Cálculo de hash SHA-256 via streaming em múltiplos chunks assíncronos.
  - Validação de digests padrão conhecidos (NIST/UTF-8).
  - Comportamento de entrada vazia.

### 2.4 Integração e Classificação VirusTotal
- `test/features/scanner/virus_total_repository_test.dart`:
  - Consulta por hash com retorno 200 (relatório encontrado).
  - Consulta por hash com retorno 404 (`HashLookupNotFound` - sem falsos seguros).
  - Tratamento de HTTP 429 (cota excedida).
  - Mapeamento das 5 categorias de veredito (`malicious`, `suspicious`, `noDetections`, `inconclusive`, `pending`).

### 2.5 Backup Offline e Integridade
- `test/features/history/backup_service_test.dart`:
  - Exportação e importação de JSON de backup local sem credenciais.
  - Rejeição de formatos de backup corrompidos ou incompatíveis.
