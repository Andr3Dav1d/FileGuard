# Privacidade e Segurança no FileGuard

Este documento descreve as garantias, mecanismos criptográficos e políticas de privacidade implementadas no **FileGuard**, em conformidade com as diretrizes do plano de desenvolvimento e boas práticas de proteção de dados (LGPD).

---

## 1. Armazenamento e Tratamento da API Key

- **Chave Individual do Usuário**: O aplicativo não fornece nem compartilha nenhuma API Key corporativa ou de desenvolvedor. Cada usuário utiliza sua própria chave pessoal obtida em virustotal.com.
- **Armazenamento Seguro com Keystore**: A chave é persistida utilizando o `flutter_secure_storage`, empregando criptografia de hardware (`Android Keystore`) com algoritmos de cifra `AES-GCM` e chave protegida por `RSA-OAEP`.
- **Não Persistência em Texto Puro**: A chave nunca é salva em `SharedPreferences` padrão, bancos de dados SQLite, arquivos comuns ou logs de depuração.
- **Sanitização de Logs e Exceções**: Todas as classes que lidam com requisições HTTP (`VirusTotalApiClient`, `VirusTotalRepositoryImpl`) tratam erros sem interpolar a API Key no texto de exceções, dumps ou mensagens de erro para a interface.

---

## 2. Minimização de Dados e Consulta por Hash

- **Prioridade Absoluta ao Hash**: Antes de qualquer envio de binário, o FileGuard calcula o hash criptográfico **SHA-256** do arquivo diretamente no aparelho através de leitura em streaming (`crypto`).
- **RAM Otimizada**: Arquivos grandes não são carregados na memória do dispositivo. O cálculo de hash consome pedaços (chunks) sucessivos de bytes.
- **Apenas Hashes Transitados**: Na consulta inicial, apenas o hash SHA-256 (64 caracteres hexadecimais) é enviado ao VirusTotal para verificar se já existe um relatório público correspondente.

---

## 3. Consentimento Explícito para Upload de Binários

- **Upload Nunca Automático**: Se o VirusTotal retornar HTTP 404 (hash não encontrado), o FileGuard **nunca** realiza upload automático do arquivo.
- **Diálogo Contextual Específico**: É apresentado um diálogo nativo de consentimento (`PermissionDialog`) detalhando o nome do arquivo, seu tamanho e alertando que o conteúdo será processado pelos motores e políticas de privacidade de terceiros do VirusTotal.
- **Direito de Cancelamento**: Se o usuário optar por cancelar, nenhuma informação adicional ou byte do arquivo é enviado à rede.

---

## 4. Banco de Dados e Histórico 100% Offline

- **Persistência Local Exclusiva**: O histórico de análises é gravado em um banco de dados relacional SQLite (`sqflite`) no diretório seguro de dados do aplicativo no dispositivo.
- **Sem Telemetria ou Servidores Próprios**: O FileGuard não possui backend próprio, endpoints de analytics ou rastreadores de telemetria. Os únicos servidores contactados são os endpoints oficiais da API pública do VirusTotal (`virustotal.com`).
- **Sem Cópia Permanente de Arquivos**: O banco de dados do histórico armazena exclusivamente metadados da análise (nome do arquivo, tamanho, hash SHA-256, veredito e estatísticas numéricas). O conteúdo binário do arquivo nunca é mantido no banco.

---

## 5. Tratamento de Arquivos APK

- **Análise Prévia Obrigatória**: Nenhum pacote Android (APK) pode ser instalado diretamente sem antes passar pelo fluxo de consulta ou análise antivírus.
- **Sem Instalação Silenciosa**: A ação de instalar exige confirmação ativa e clique explícito do usuário no botão *"Encaminhar ao Instalador Android"*.
- **Avisos de Risco**: Se forem detectadas ameaças (malicious ou suspicious), um alerta proeminente em vermelho/amarelo é exibido antes de habilitar a opção de encaminhamento.
- **Proteções Nativas Respeitadas**: O aplicativo utiliza `FileProvider` e intents padrão (`ACTION_VIEW`), deixando a decisão final de segurança, permissões e análise de assinatura sob a responsabilidade do instalador nativo do sistema Android.
