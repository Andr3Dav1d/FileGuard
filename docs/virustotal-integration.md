# Integração com a API v3 do VirusTotal

Este documento detalha os endpoints, modelos de dados, limites e tratamento de exceções da **API v3 do VirusTotal** utilizados no **FileGuard**.

---

## 1. Visão Geral e Autenticação

A comunicação com o VirusTotal ocorre exclusivamente via HTTPS na URL base:
```
https://www.virustotal.com/api/v3
```

Todas as requisições autenticadas exigem o cabeçalho:
```http
x-apikey: <SUA_API_KEY_VIRUSTOTAL>
accept: application/json
```

> [!IMPORTANT]
> A chave de API pertence exclusivamente ao usuário do dispositivo. O FileGuard nunca inclui chaves compartilhadas no código-fonte nem armazena a chave em servidores intermediários.

---

## 2. Endpoints Utilizados

### 2.1 Validação da Chave e Quotas
- **Método / Rota:** `GET /users/{id}`
- **Parâmetro `{id}`:** A própria API Key fornecida pelo usuário.
- **Finalidade:** Validar a autenticidade da chave sem consumir quota de análise de arquivos e consultar limites de requisição.
- **Respostas:**
  - `200 OK`: Chave válida e ativa. O corpo contém `data.attributes.quotas` e dados da conta.
  - `401 Unauthorized`: Chave inexistente, inválida ou revogada.
  - `429 Too Many Requests`: Limite de requisições excedido.

### 2.2 Consulta de Relatório por Hash
- **Método / Rota:** `GET /files/{id}`
- **Parâmetro `{id}`:** Hash SHA-256 (64 caracteres hexadecimais), SHA-1 ou MD5. O FileGuard prioriza sempre **SHA-256**.
- **Finalidade:** Obter o relatório consolidado de análises prévias sem necessidade de enviar o arquivo binário.
- **Respostas:**
  - `200 OK`: Relatório disponível. Contém estatísticas de detecção de mais de 70 motores antivírus.
  - `404 Not Found`: Hash não catalogado no banco de dados do VirusTotal. **Atenção:** 404 indica ausência de análise prévia, **jamais** ausência de ameaça ou arquivo seguro.
  - `401 Unauthorized`: API Key inválida.
  - `429 Too Many Requests`: Cota de requisições por minuto/dia atingida.

### 2.3 Upload de Arquivo Binário (Consentido)
- **Método / Rota:** `POST /files`
- **Content-Type:** `multipart/form-data`
- **Corpo:** Campo `file` contendo o fluxo de bytes do arquivo.
- **Limite Padrão da API v3 Pública:** Arquivos de até 32 MB diretamente no endpoint `/files`. (Para arquivos maiores que 32 MB e até 650 MB, a API v3 requer `GET /files/upload_url`, endpoint especial de upload).
- **Finalidade:** Enviar o arquivo original para enfileiramento de análise quando não houver relatório por hash e o usuário concordar explicitamente.
- **Respostas:**
  - `200 OK`: Retorna objeto de análise com `id` (ex.: `k-ZjM4N...`) no formato `{"data": {"type": "analysis", "id": "..."}}`.
  - `400 Bad Request`: Arquivo corrompido ou vazio.
  - `413 Payload Too Large`: Tamanho excede o limite aceito.

### 2.4 Acompanhamento da Análise (Polling)
- **Método / Rota:** `GET /analyses/{id}`
- **Parâmetro `{id}`:** Identificador de análise retornado no upload.
- **Finalidade:** Consultar o progresso do processamento de um upload.
- **Atributos de Status:**
  - `queued`: Na fila de processamento.
  - `in_progress`: Motores antivírus executando a análise.
  - `completed`: Análise finalizada; estatísticas consolidadas disponíveis.

---

## 3. Classificação Semântica dos Resultados

A resposta de `last_analysis_stats` da API v3 fornece as seguintes contagens:
- `malicious`: Total de motores que detectaram malware.
- `suspicious`: Total de motores que classificaram como suspeito/heurístico.
- `undetected`: Motores que examinaram e não encontraram assinaturas.
- `harmless`: Motores que classificaram explicitamente como inofensivo.
- `timeout` / `confirmed-timeout`: Motores que estouraram tempo de resposta.
- `failure`: Motores com falha de execução.
- `type-unsupported`: Motores que não suportam o formato do arquivo.

### Regra de Mapeamento no FileGuard:

```text
Se (malicious > 0)
    => Malicious (Estado: Perigo / Vermelho)
Senão se (suspicious > 0)
    => Suspicious (Estado: Suspeito / Amarelo)
Senão se (undetected + harmless > 0)
    => No Detections (Estado: Sem Detecções / Verde)
Senão se (apenas timeout, failure ou type-unsupported)
    => Inconclusive (Estado: Inconclusivo / Roxo/Neutro)
Caso em fila ou processamento
    => Pending (Estado: Pendente / Azul)
```

> [!CAUTION]
> O estado **Sem Detecções** nunca deve ser comunicado como "Arquivo 100% Seguro" ou "Livre de Vírus". A interface deve manter o texto transparente: *"Nenhum dos motores antivírus detectou ameaças conhecidas neste arquivo."*

---

## 4. Tratamento de Erros HTTP

| Código | Causa Provável | Ação da Aplicação |
| :--- | :--- | :--- |
| **400** | Hash ou requisição malformada | Notificar usuário sobre formato inválido de identificador |
| **401** | Chave ausente, inválida ou revogada | Redirecionar para tela de Configuração com aviso claro |
| **403** | Falta de privilégios ou restrição na conta | Informar limitação de permissão da conta do usuário |
| **404** | Hash não registrado no VirusTotal | Apresentar diálogo com opção de upload voluntário |
| **429** | Limite de cota pública (ex.: 4 req/min) | Orientar o usuário a aguardar antes de nova consulta |
| **500/502/503** | Instabilidade nos servidores do VirusTotal | Informar indisponibilidade temporária do serviço externo |
| **Timeout / Socket** | Sem conexão ou falha DNS no dispositivo | Exibir estado de "Sem conexão com a internet" |
