# Integração com a Plataforma Android

Este documento descreve os detalhes de integração nativa do **FileGuard** com o sistema operacional Android.

---

## 1. Storage Access Framework (SAF)

Para seleção de arquivos pelo usuário, o FileGuard adota o **Storage Access Framework (SAF)** nativo do Android:
- Não é solicitada permissão ampla e invasiva de gerenciamento de todos os arquivos (`MANAGE_EXTERNAL_STORAGE`).
- A seleção é delegada ao seletor de documentos do Android (`ACTION_OPEN_DOCUMENT`) através de canais compatíveis.
- O aplicativo consome os dados do arquivo via URI ou fluxo binário `openRead()`, garantindo o respeito ao ciclo de vida e às permissões temporárias concedidas pelo sistema.

---

## 2. FileProvider e Encaminhamento de APKs

Quando o usuário decide voluntariamente instalar um pacote APK após a revisão do relatório de segurança:

1. **Definição no Manifesto**:
   `androidx.core.content.FileProvider` configurado em `android/app/src/main/AndroidManifest.xml` com a autoridade `${applicationId}.fileprovider`.
2. **Caminhos Acessíveis**:
   Configurados em `android/app/src/main/res/xml/file_paths.xml` com suporte a arquivos em cache, armazenamento interno e caminhos públicos temporários.
3. **Platform Channel Kotlin (`MainActivity.kt`)**:
   - Canal: `com.example.fileguard/apk_installer`
   - Método: `installApk`
   - O código Kotlin obtém uma `content://` URI segura via `FileProvider.getUriForFile()`.
   - Dispara uma `Intent(Intent.ACTION_VIEW)` com o MIME `application/vnd.android.package-archive` e as flags `FLAG_GRANT_READ_URI_PERMISSION` e `FLAG_ACTIVITY_NEW_TASK`.
   - O instalador nativo do Android é aberto sem bypass ou alterações nas proteções do sistema operacional.

---

## 3. Armazenamento Seguro com Android Keystore

O `flutter_secure_storage` utiliza chaves criptográficas geradas e mantidas dentro do módulo seguro de hardware do Android (`Android Keystore`), garantindo que a API Key permaneça inacessível mesmo com acesso físico ao sistema de arquivos não privilegiado.
