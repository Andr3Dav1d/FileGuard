# FileGuard · Especificação do Design System (Revisão Técnica)

> **Documento revisado e confrontado diretamente com o Figma MCP:**  
> **Arquivo Figma:** [FileGuard no Figma](https://www.figma.com/design/zeWrs5EG30L1rGSUDSR5YW/FileGuard) (`zeWrs5EG30L1rGSUDSR5YW`)  
> **Páginas auditadas:** `0:1 Design Foundations`, `6:2 Componentes`, `6:4 Telas · Claro`, `6:5 Telas · Escuro AMOLED`.  
> **Status da Revisão:** Auditado contra WCAG AA, hierarquia AMOLED validada, tokens nativos discriminados de inferências e inconsistências dimensionais registradas.

---

## 1. Princípios de Design & Arquitetura Visual

* **Filosofia:** *Material 3 Expressive contido · Função antes da apresentação*.
* **Propósito de Segurança:** Interface utilitária, técnica e transparente. Foco em clareza absoluta sobre privacidade e consentimento em cada fronteira de rede (separação estrita entre consulta de hash SHA-256 e envio de arquivos binários).
* **Estrutura por Tela:** Um título por tarefa, sem elementos "hero" distrativos nas telas de operação diária. Dados criptográficos (hashes SHA-256) exibidos na íntegra e prontamente copiáveis.
* **Modelo Planar:** O design não adota sombras difusas (`elevation` / `box-shadow`) em nenhum tema. A profundidade é puramente planar, expressa por variações de luminosidade de superfície e bordas sólidas sutis de `1 dp`.

---

## 2. Tokens de Cor: Nativos vs. Pendentes de Definição

Para evitar divergências na implementação Flutter, a tabela a seguir discrimina explicitamente a origem e o grau de certeza de cada token:

| Papel / Token | Tema Claro | Tema Escuro AMOLED | Status no Figma | Evidência / Notas Técnicas |
| :--- | :--- | :--- | :--- | :--- |
| `background` | `#F5F8FA` | `#000000` | **NATIVO FIGMA** | `0:1` e CSS de telas (`var(--color/background)`) |
| `surface` | `#FFFFFF` | `#000000` | **NATIVO FIGMA** | `0:1`: "AMOLED: fundo e superfície #000000" |
| `card` | `#FFFFFF` | `#101010` | **NATIVO FIGMA** | `0:1`: "Cartões #101010"; Telas `var(--color/card)` |
| `surfaceHigh` (Elevada) | `#EAF0F4` | `#0A0A0A` | **NATIVO FIGMA** | `0:1`: "Elevada #0A0A0A"; Bottom Nav e tracks |
| `surfaceSecondary` | `#EAF0F4` | `#121212` | **NATIVO FIGMA** | `0:1`: "Secundária #121212" |
| `outline` / `divider` | `#BACBD3` | `#252525` | **NATIVO FIGMA** | `0:1`: "Divisores #252525"; Telas `var(--color/outline)` |
| `modalScrim` | `rgba(5, 18, 26, 0.46)` | `rgba(5, 18, 26, 0.46)` | **EXTRAÍDO DE TELAS** | Nó `6:3362` em telas com modal ativo |
| `primary` (Azul AMOLED) | `#08677D` | `#80B4FF` | **NATIVO FIGMA** | `0:1`: Caixa "Azul AMOLED #08677D / #80B4FF" |
| `onPrimary` | `#FFFFFF` | `#001C3B` | **NATIVO FIGMA** | CSS de botões preenchidos (`var(--color/onprimary)`) |
| `primaryContainer` | `#C5EDF6` | `#10233B` | **NATIVO FIGMA** | CSS de badges e indicadores (`var(--color/primarycontainer)`) |
| `onPrimaryContainer` | `#064A5B` | `#CFE2FF` | **NATIVO FIGMA** | CSS de rótulos ativos na Bottom Nav |
| `text` (Primary) | `#152D38` | `#FFFFFF` | **NATIVO FIGMA** | `0:1`: "Texto principal #FFFFFF"; CSS `var(--color/text)` |
| `muted` (Secondary) | `#50646E` | `#B3B3B3` | **NATIVO FIGMA** | `0:1`: "Secundário #B3B3B3"; CSS `var(--color/muted)` |
| `disabledText` (Escuro) | — | `#666666` | **NATIVO FIGMA** | `0:1`: "Desativado #666666" |
| `disabledText` (Claro) | `#50646E` | — | **EXTRAÍDO DE TELAS** | Botão `6:288` usa `var(--color/muted, #50646E)` |
| `disabledContainer` (Claro) | `#EAF0F4` | — | **NATIVO FIGMA** | Botão `6:288` usa `var(--color/surfacehigh, #EAF0F4)` |
| `disabledContainer` (Escuro) | — | *Pendente* | **PENDENTE DE DEFINIÇÃO** | Inexistente no Figma (sem botão desabilitado escuro) |
| `danger` (Malicioso) | `#AA2733` | `#FFB4AB` | **NATIVO FIGMA** | `0:1`: Caixa "Malicioso #AA2733 / #FFB4AB" |
| `dangerContainer` (Claro) | `#FFE9EB` | — | **NATIVO FIGMA** | Badge `6:291` usa `var(--color/dangercontainer)` |
| `dangerContainer` (Escuro) | — | *Pendente* | **PENDENTE DE DEFINIÇÃO** | Badges escuros usam superfícies padrão/primárias |
| `warning` (Suspeito) | `#795600` | `#FFD180` | **NATIVO FIGMA** | `0:1`: Caixa "Suspeito #795600 / #FFD180" |
| `warningContainer` (Claro) | `#FFF0CC` | — | **NATIVO FIGMA** | Badge `6:296` usa `var(--color/warningcontainer)` |
| `warningContainer` (Escuro) | — | *Pendente* | **PENDENTE DE DEFINIÇÃO** | Inexistente no Figma |
| `neutral` (Nenhuma detecção) | `#38685E` | `#8FD5A6` | **NATIVO FIGMA** | `0:1`: Caixa "Nenhuma detecção #38685E / #8FD5A6" |
| `neutralContainer` (Claro) | `#DBF1EA` | — | **NATIVO FIGMA** | Badge `6:301` usa `var(--color/neutralcontainer)` |
| `neutralContainer` (Escuro) | — | *Pendente* | **PENDENTE DE DEFINIÇÃO** | Inexistente no Figma |

> [!IMPORTANT]
> **Lacunas de Design Identificadas (Pendentes de Definição):**
> 1. **Containers de Status no Modo Escuro:** O Figma não define valores para `dangerContainer`, `warningContainer` ou `neutralContainer` no tema escuro AMOLED. Nas telas escuras, o badge de detecção utiliza `primaryContainer` (`#10233B`) ou fundo escuro padrão. Recomenda-se para a equipe de design definir se o Flutter deve adotar opacidade de 15% sobre a cor de risco ou um tom tonal escuro.
> 2. **Botão Desabilitado no Tema Escuro:** Não há símbolo ou instância desenhada de botão inativo no tema AMOLED. Recomenda-se adotar fundo `#121212` ou `#101010` com borda `#252525` e texto `#666666`.

---

## 3. Auditoria de Acessibilidade & Contraste WCAG AA

Todos os pares de texto e fundo utilizados na interface foram submetidos ao cálculo matemático de luminância relativa ($L$) conforme a especificação WCAG 2.1:

$$L = 0.2126 \times R + 0.7152 \times G + 0.0722 \times B$$
$$\text{Ratio} = \frac{L_1 + 0.05}{L_2 + 0.05}$$

### 3.1 Combinações no Tema Claro

| Par de Cores (Texto vs. Fundo) | Hex Texto | Hex Fundo | Razão de Contraste | Requisito WCAG AA | Veredito |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Texto Principal sobre Fundo Geral | `#152D38` | `#F5F8FA` | **13.45 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Principal sobre Cartão Branco | `#152D38` | `#FFFFFF` | **14.34 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Principal sobre Superfície Elevada | `#152D38` | `#EAF0F4` | **12.48 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Muted/Apoio sobre Fundo Geral | `#50646E` | `#F5F8FA` | **5.81 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Muted/Apoio sobre Cartão Branco | `#50646E` | `#FFFFFF` | **6.20 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Muted/Apoio sobre Superfície Elevada | `#50646E` | `#EAF0F4` | **5.39 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Primário sobre Fundo Geral | `#08677D` | `#F5F8FA` | **6.06 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Primário sobre Cartão Branco | `#08677D` | `#FFFFFF` | **6.47 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Branco sobre Botão Primário | `#FFFFFF` | `#08677D` | **6.47 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Primária sobre PrimaryContainer | `#08677D` | `#C5EDF6` | **5.18 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| OnPrimaryContainer sobre PrimaryContainer | `#064A5B` | `#C5EDF6` | **7.87 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Perigo (Malicioso) sobre DangerContainer | `#AA2733` | `#FFE9EB` | **5.94 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Perigo (Malicioso) sobre Cartão Branco | `#AA2733` | `#FFFFFF` | **6.89 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Aviso (Suspeito) sobre WarningContainer | `#795600` | `#FFF0CC` | **5.91 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Neutro (Sem detecções) sobre NeutralContainer | `#38685E` | `#DBF1EA` | **5.37 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Desabilitado sobre Botão Desabilitado | `#50646E` | `#EAF0F4` | **5.39 : 1** | Isento (SC 1.4.3) | **APROVADO** ($\ge 4.5:1$) |

### 3.2 Combinações no Tema Escuro AMOLED

| Par de Cores (Texto vs. Fundo) | Hex Texto | Hex Fundo | Razão de Contraste | Requisito WCAG AA | Veredito |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Texto Branco sobre Fundo Preto AMOLED | `#FFFFFF` | `#000000` | **21.00 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** (Máximo) |
| Texto Branco sobre Cartão Escuro | `#FFFFFF` | `#101010` | **19.03 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Muted sobre Fundo Preto AMOLED | `#B3B3B3` | `#000000` | **10.02 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Muted sobre Cartão Escuro | `#B3B3B3` | `#101010` | **9.08 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Primária Escura sobre Fundo Preto | `#80B4FF` | `#000000` | **9.89 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Primária Escura sobre Cartão Escuro | `#80B4FF` | `#101010` | **8.96 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| OnPrimary sobre Botão Primário Escuro | `#001C3B` | `#80B4FF` | **8.05 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Perigo (Malicioso) sobre Cartão Escuro | `#FFB4AB` | `#101010` | **11.21 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Aviso (Suspeito) sobre Cartão Escuro | `#FFD180` | `#101010` | **13.31 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Neutro (Sem detecções) sobre Cartão Escuro | `#8FD5A6` | `#101010` | **11.09 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| OnPrimaryContainer sobre PrimaryContainer | `#CFE2FF` | `#10233B` | **12.05 : 1** | $\ge 4.5:1$ (Normal) | **APROVADO** |
| Texto Desabilitado sobre Fundo Preto | `#666666` | `#000000` | **3.66 : 1** | Isento (SC 1.4.3) | **CONFORME** ($\ge 3:1$) |
| Texto Desabilitado sobre Cartão Escuro | `#666666` | `#101010` | **3.31 : 1** | Isento (SC 1.4.3) | **CONFORME** ($\ge 3:1$) |

> [!NOTE]  
> **Conformidade de Estados Desabilitados:** De acordo com o critério de sucesso WCAG 2.1 SC 1.4.3, elementos de interface inativos ou desabilitados não possuem exigência mínima de contraste. No FileGuard, o estado desabilitado claro (`5.39:1`) supera até mesmo o limiar de texto ativo normal (`4.5:1`), e o estado desabilitado escuro (`3.31:1` a `3.66:1`) mantém legibilidade superior a 3:1 sem criar falso estímulo visual de interatividade.

---

## 4. Hierarquia de Superfícies no Tema AMOLED

A interface AMOLED do FileGuard não utiliza sombras nem elevações dinâmicas com difusão tonal. Ela é estruturada em uma hierarquia puramente planar de 4 camadas por luminância, projetada para desligar pixels OLED onde for possível e gerar contraste nítido:

```
[ Camada 3: Controles & Diálogos ]   -> #101010 (Cartões, Modais) | Borda #252525
[ Camada 2: Superfície Elevada ]     -> #0A0A0A (Barra Inferior, Bloco SHA-256)
[ Camada 1: Superfície Secundária ]  -> #121212 (Áreas de apoio)
[ Camada 0: Fundo Base ]             -> #000000 (Black puro - Pixels desligados)
```

1. **Camada 0 — Fundo Base (`#000000`):**
   * Usado no canvas geral da tela e na Top App Bar (em repouso). Os pixels pretos permanecem 100% desligados em telas OLED/AMOLED, economizando bateria.
2. **Camada 1 — Superfície Secundária (`#121212`):**
   * Tonalidade escura neutra para agrupamentos secundários e áreas de contraste suave.
3. **Camada 2 — Superfície Elevada / Controles Inferiores (`#0A0A0A`):**
   * Aplicada no fundo da `Bottom navigation` e em contêineres técnicos (ex.: contêiner do SHA-256 no nó `6:3351`). Oferece uma sutil separação do preto absoluto sem reflexos.
4. **Camada 3 — Cartões e Superfícies de Conteúdo (`#101010`):**
   * Aplicada em todos os `Statistic card`, cartões de detalhes, e nos modais de diálogo (`Hash permission dialog` nó `6:3363`).
5. **Divisores e Contornos (`#252525`):**
   * Linha de contorno sólida de `1 dp` para delimitar cartões, botões tonais e inputs contra o fundo escuro, mantendo a sobriedade técnica ("sem brilho").
6. **Scrim Modal (`rgba(5, 18, 26, 0.46)`):**
   * Sobreposição escura com tom sutil de azul-petróleo para modais de consentimento, mantendo legibilidade sem ocultar completamente o contexto anterior.

---

## 5. Auditoria de Componentes: Variantes Claras vs. Escuras

A inspeção do arquivo revelou uma distinção estrutural crítica entre a página de biblioteca e as telas do projeto:

* **Página `6:2 Componentes` (Biblioteca Mestre):**
  * Todos os 16 componentes principais (`Button`, `Detection badge`, `App bar`, `Bottom navigation`, `Statistic card`, `File list tile`, `Progress`, `API key field`, `Permission dialog`, `Engine report table`, etc.) foram construídos e expostos **apenas no Tema Claro**.
  * Eles **NÃO possuem a propriedade variante `Theme=Light | Dark`** nem usam Figma Variables para alternância de tema no componente mestre.
  * O único componente da página com propriedade formal de tema é `Prévia de tema` (`15:3947`), que apresenta `Tema=Claro` e `Tema=Escuro`.
* **Páginas `6:4 Telas · Claro` e `6:5 Telas · Escuro AMOLED`:**
  * As variantes escuras existem de fato implementadas ao longo das **51 telas** da página `6:5`.
  * Nessas telas, os elementos escuros são instâncias com overrides manuais de preenchimento (`#101010`, `#80B4FF`, `#B3B3B3`, etc.).
* **Diretriz para Implementação Flutter:**
  * Não duplicar componentes em `LightWidget` e `DarkWidget`. Em Flutter, implementar cada componente consumindo dinamicamente as propriedades do `Theme.of(context)` e da extensão de tema `FileGuardColors`, permitindo que o mesmo widget se adapte automaticamente a ambos os temas.

---

## 6. Auditoria de Inconsistências Dimensionais e Espaçamentos

O confronto direto entre os símbolos isolados da folha de componentes e as telas completas evidenciou as seguintes inconsistências e especificações de tela:

| Componente | Especificação na Folha `Componentes` (`6:2`) | Especificação nas Telas Reais (`6:4` e `6:5`) | Resolução / Recomendação para Flutter |
| :--- | :--- | :--- | :--- |
| **`Permission dialog`** | Largura `332 dp`<br>Padding `16 dp`<br>Raio `12 dp` | Largura `364 dp`<br>Padding `24 dp`<br>Raio `28 dp` (`rounded-[28px]`) | **Adotar a especificação de tela (`28 dp`, padding `24 dp`)**: Segue o padrão Material 3 para diálogos (`extraLarge`). |
| **`Export bottom sheet` vs Tela 26** | Modelado como Bottom Sheet modal (`412 × 228 dp`) com botões diretos de exportação | Tela completa de 917 dp (`26 · Exportar relatório`) com opções rádio e múltiplos botões | **Implementar a Tela 26**: O fluxo real do usuário foi desenvolvido como tela cheia; o bottom sheet ficou como componente isolado. |
| **Largura do `Button`** | Largura fixa de `364 dp` | `w-full` ocupando a largura útil entre as margens laterais de 16 dp (`380 dp`) | **Usar `double.infinity` com restrições**: Em Flutter, botões devem expandir no container mantendo margens de `16 dp`. |
| **Largura do `Statistic card`** | Largura fixa de `176 dp` | Inserido em linha com `flex: 1` (`184 dp` em tela de 412 dp) | **Usar `Expanded` em `Row`**: Garantir proporcionalidade responsiva em diferentes resoluções. |
| **`Bottom navigation`** | Altura do frame `84 dp` | Frame de `84 dp` posicionado a `bottom: 24px` sobre a barra de gestos Android | **Respeitar `SafeArea` do Android**: Ancorar acima da barra de gestos (`108 × 4 dp`). |
| **`API key field`** | Raio de `16 dp` | Raio de `16 dp` | **Confirmado:** Campo de entrada usa intencionalmente raio maior (`16 dp`) do que cartões padrão (`12 dp`). |

---

## 7. Catálogo Tipográfico e Grid (Métricas Consolidadas)

### 7.1 Tipografia (Roboto)

| Token / Papel | Tamanho (`fontSize`) | Altura da Linha (`lineHeight`) | Peso (`fontWeight`) | Regra de Aplicação |
| :--- | :--- | :--- | :--- | :--- |
| **Headline / Tela** | `28 px` | `36 px` | Medium (`w500`) | Título principal de telas sem barra |
| **Estatística** | `28 px` | `34 px` | Medium (`w500`) | Contadores numéricos em `Statistic card` |
| **App Bar Title** | `20 px` | `28 px` | Medium (`w500`) | Título da Top App Bar |
| **Dialog Title** | `20 px` | `28 px` | Bold (`w700`) | Título nos diálogos de permissão |
| **Subtítulo / Seção** | `18 px` | `24–26 px` | Medium (`w500`) | Cabeçalhos de blocos e seções |
| **Card Title / Alerta** | `16 px` | `24 px` | Medium (`w500`) | Títulos internos de cartões e status de progresso |
| **Corpo (Padrão)** | `16 px` | `20–24 px` | Regular (`w400`) | Textos explicativos e orientações de privacidade |
| **Corpo (Compacto) / Botão** | `14 px` | `20 px` | Medium (`w500`) | Rótulos de botões e títulos de arquivos em listas |
| **Técnico (Hash / Engines)** | `13 px` | `20 px` | Regular (`w400`) | SHA-256 e tabela de resultados antivírus |
| **Apoio / Metadados** | `12 px` | `16 px` | Regular / Medium | Tamanho, data de arquivo e rótulos de input |
| **Micro / Navegação** | `11 px` | `16 px` | Regular / Medium | Rótulos da Bottom Navigation |

### 7.2 Espaçamentos e Formas

* **Grade:** Base de `4 dp`.
* **Margens de Tela:** `16 dp` nas laterais móveis.
* **Padding Padronizado:**
  * `--space/8`: `8 dp` (App Bar, File list tile)
  * `--space/12`: `12 dp` (Statistic card, botões verticalmente)
  * `--space/16`: `16 dp` (Cartões de conteúdo, inputs, botões horizontalmente)
  * `--space/24`: `24 dp` (Padding interno de diálogos e respiro de scroll)
* **Formas (Corner Radius):**
  * Diálogos de permissão: `28 dp`
  * Campos de API Key e contêineres de ícone: `16 dp`
  * Cartões, botões e badges: `12 dp`
  * File list tile e barra de progresso: `8 dp`
  * Gesture handle do Android: `4 dp`
  * Indicador de seleção de navegação: `100 dp` (pílula total)

---

## 8. Catálogo de Componentes e Estados Consolidados

1. **`Button`**:
   * Altura fixa de `48 dp`, raio de `12 dp`.
   * *Filled*: Fundo `primary`, texto `onPrimary`.
   * *Tonal*: Fundo transparente, borda `1 dp` em `outline`, texto `primary`.
   * *Danger*: Fundo `danger`, texto branco.
   * *Disabled*: Fundo `surfaceHigh` (`#EAF0F4`), texto `muted` (`#50646E`). *(Escuro pendente)*.
   * *Pressed*: Opacidade `88%` do estado normal.
   * *Loading*: Fundo `primary`, texto "Analisando…".
2. **`Detection badge`**:
   * Largura de `312 dp`, padding `12 dp`, raio `12 dp`.
   * *Malicious*: Ícone `warning`, texto `danger`.
   * *Suspicious*: Ícone `warning`, texto `warning`.
   * *No detections*: Ícone `check`, texto `neutral`.
   * *Inconclusive*: Ícone `clock`, texto `muted`.
   * *Pending*: Ícone `clock`, texto `primary`.
3. **`App bar`**:
   * Altura mínima `64 dp`, padding `8 dp`. Alvos de toque de navegação e ação de `48 × 48 dp`.
4. **`Bottom navigation`**:
   * 4 destinos (`Início`, `Analisador`, `Histórico`, `Configurações`). Indicador ativo de `64 × 32 dp` em `primaryContainer`.
5. **`API key field`**:
   * Raio `16 dp`, padding `16 dp`. Borda `1 dp` em `outline` ou `danger` (erro). Alternância de máscara com `Icon/eye` (24 dp).
6. **`Progress`**:
   * Track de `8 dp` (`surfaceHigh`), indicador de `8 dp` (`primary`), raio `8 dp`.
7. **`Preference switch`**:
   * `52 × 32 dp`. *On*: track `primary`, thumb branco. *Off*: track `surfaceHigh`, thumb `muted`.

---

## 9. Diretrizes de Implementação no Flutter

Para garantir fidelidade com o design inspecionado:

1. **`ThemeData` AMOLED:**
   ```dart
   final darkTheme = ThemeData(
     brightness: Brightness.dark,
     scaffoldBackgroundColor: const Color(0xFF000000),
     colorScheme: const ColorScheme.dark(
       primary: Color(0xFF80B4FF),
       onPrimary: Color(0xFF001C3B),
       primaryContainer: Color(0xFF10233B),
       onPrimaryContainer: Color(0xFFCFE2FF),
       surface: Color(0xFF000000),
       onSurface: Color(0xFFFFFFFF),
       outline: Color(0xFF252525),
     ),
   );
   ```
2. **`ThemeExtension` para Risco e Superfícies AMOLED:**
   ```dart
   class FileGuardColors extends ThemeExtension<FileGuardColors> {
     final Color card;
     final Color surfaceHigh;
     final Color surfaceSecondary;
     final Color danger;
     final Color warning;
     final Color neutral;
     final Color muted;

     const FileGuardColors({
       required this.card,
       required this.surfaceHigh,
       required this.surfaceSecondary,
       required this.danger,
       required this.warning,
       required this.neutral,
       required this.muted,
     });
     // Implementar copyWith e lerp...
   }
   ```
3. **Alvos de Toque:**
   * Garantir `BoxConstraints(minWidth: 48, minHeight: 48)` em todos os botões de ação e ícones interativos.
4. **Respeito a Movimento Reduzido:**
   * Utilizar `MediaQuery.of(context).disableAnimations` para suprimir transições com física de mola (`damping: 0.85`, `stiffness: 400`) quando o usuário ativar a preferência de redução de movimento no Android.
