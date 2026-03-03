# LinkedIn Easy Apply Auto-Applicator

Bot Ruby que automatiza candidaturas **Easy Apply** no LinkedIn. Busca vagas por keywords + localização, extrai requisitos da descrição, compara com seu perfil (YAML), e aplica automaticamente se o match for >= 70%.

---

## Como Funciona

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Job Search  │────>│  Job Parser  │────>│   Matching   │────>│  Easy Apply  │
│              │     │              │     │   Engine     │     │    Flow      │
│ keywords +   │     │ extrai título│     │              │     │              │
│ localização  │     │ empresa,     │     │ score >= 70% │     │ preenche     │
│ Easy Apply   │     │ descrição    │     │ → APLICAR    │     │ modal multi- │
│ filter       │     │ completa     │     │              │     │ step         │
│              │     │              │     │ score < 70%  │     │              │
│ paginação    │     │ detecta Easy │     │ → SKIP       │     │ submit +     │
│ automática   │     │ Apply        │     │              │     │ confirma     │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
       │                                                              │
       │              ┌──────────────┐     ┌──────────────┐           │
       └─────────────>│  Seen Jobs   │     │  App Log     │<──────────┘
                      │  Store       │     │              │
                      │ dedup JSON   │     │ append-only  │
                      │ evita re-    │     │ log de todas │
                      │ processar    │     │ as decisões  │
                      └──────────────┘     └──────────────┘
```

### Ciclo de Polling

1. **Busca** vagas no LinkedIn (keywords + localização + Easy Apply filter)
2. **Filtra** vagas já vistas (dedup via `seen_jobs.json`)
3. **Parseia** cada vaga — extrai título, empresa, descrição completa
4. **Extrai requisitos** da descrição — skills, anos de experiência, educação
5. **Calcula score** ponderado contra seu perfil YAML
6. **Aplica** automaticamente se score >= threshold (default 70%)
7. **Loga** toda decisão (aplicou/pulou/falhou) com breakdown do score
8. **Espera** 60s e repete

---

## Pré-requisitos

| Requisito | Versão |
|-----------|--------|
| Ruby | >= 3.1 |
| Google Chrome | Instalado |
| ChromeDriver | Compatível com sua versão do Chrome |
| Bundler | >= 2.0 |

### Instalando ChromeDriver

**Windows (via chocolatey):**
```bash
choco install chromedriver
```

**macOS (via homebrew):**
```bash
brew install chromedriver
```

**Linux:**
```bash
# Verifique sua versão do Chrome
google-chrome --version

# Baixe a versão correspondente em:
# https://googlechromelabs.github.io/chrome-for-testing/
```

---

## Instalação

```bash
git clone https://github.com/Lucasdfg07/LinkedIn-Easy-Apply-MentoriaOperacao.git
cd LinkedIn-Easy-Apply-MentoriaOperacao

bundle install
```

---

## Configuração

### 1. Criar seu perfil

```bash
cp config/profile.yml.example config/profile.yml
```

Edite `config/profile.yml` com seus dados:

```yaml
personal:
  first_name: "Seu Nome"
  last_name: "Seu Sobrenome"
  email: "seu@email.com"
  phone: "+55 11 99999-9999"
  city: "Sao Paulo"
  country: "Brazil"

experience:
  years: 5
  current_title: "Senior Software Engineer"
  summary: "Full stack developer with focus on Ruby and JavaScript"

education:
  degree: "bachelor"  # Opções: high_school, associate, bachelor, master, phd
  field: "Computer Science"

skills:
  - ruby
  - rails
  - javascript
  - postgresql
  - docker
  # ... adicione todas as suas skills

easy_apply_answers:
  # Respostas para perguntas comuns do Easy Apply
  # O bot faz match por keyword no label da pergunta
  "years of experience": "5"
  "salary expectation": "Open to discuss"
  "work authorization": "Yes"
  "sponsorship": "No"
  "remote": "Yes"
  "start date": "Immediately"
```

### 2. Obter o cookie `li_at`

O bot usa o cookie de sessão do LinkedIn para autenticar. Para obter:

1. Faça login no LinkedIn no navegador
2. Abra DevTools (F12) → aba **Application** → **Cookies** → `https://www.linkedin.com`
3. Copie o valor do cookie `li_at`
4. Cole em `config/config.yml`:

```yaml
linkedin:
  li_at: "AQEDAQxxxxxxxxxxxxxxxxxxxxxx..."
```

> **Nota:** O cookie `li_at` expira periodicamente. Se o bot reportar erro de sessão, obtenha um novo cookie.

### 3. Configurar busca

Edite `config/config.yml`:

```yaml
search:
  keywords: "Ruby Developer"    # Termos de busca
  location: "Brazil"            # Localização
  easy_apply_only: true         # Apenas vagas Easy Apply
```

### 4. Ajustar matching (opcional)

```yaml
matching:
  threshold: 0.70               # Score mínimo para aplicar (0.0 - 1.0)
  weights:
    skills: 0.60                # Peso das skills (60%)
    experience: 0.25            # Peso da experiência (25%)
    education: 0.15             # Peso da educação (15%)
```

---

## Uso

### Validar configuração

```bash
ruby bin/easy_apply validate
```

Saída esperada:
```
✓ Config and profile are valid!
  Keywords: Ruby Developer
  Location: Brazil
  Threshold: 0.7
  Skills: 15
```

### Modo Dry Run (recomendado primeiro)

Busca vagas e mostra scores sem aplicar:

```bash
ruby bin/easy_apply run --dry-run
```

Saída:
```
✓ [0.850] Senior Ruby Developer @ Acme Corp
  Skills: ruby, rails, postgresql
  Exp: 1.0 | Edu: 1.0

✗ [0.450] Go/Rust Engineer @ StartupXYZ
  Skills:
  Exp: 0.3 | Edu: 1.0

=== Dry Run Complete ===
Jobs processed: 25
Would apply: 18
Skipped: 7
```

### Modo Live (aplica de verdade)

```bash
ruby bin/easy_apply run
```

### Ver estatísticas

```bash
ruby bin/easy_apply status
```

Saída:
```
=== Easy Apply Bot Status ===
Jobs seen:        142
Total decisions:  89
Applied:          34
Skipped:          48
Failed:           7
Average score:    0.721

--- Recent Applications ---
  ✓ Ruby Developer @ TechCo (0.92) [applied]
  ✗ Python Engineer @ DataInc (0.45) [skipped]
  ✓ Full Stack Dev @ StartUp (0.78) [applied]
```

### Opções do CLI

```bash
ruby bin/easy_apply help run
```

| Flag | Default | Descrição |
|------|---------|-----------|
| `--dry-run` | `false` | Busca e pontua sem aplicar |
| `--config` | `config/config.yml` | Caminho para arquivo de config |
| `--profile` | `config/profile.yml` | Caminho para arquivo de perfil |

---

## Algoritmo de Matching

O score é calculado com pesos configuráveis:

```
Score = (0.60 × skill_match) + (0.25 × experience_match) + (0.15 × education_match)
```

### Skills (60% do score)

- Extrai keywords da descrição via dicionário de ~100 termos canônicos com aliases
- Exemplo: `"RoR"`, `"Ruby on Rails"`, `"rubyonrails"` → tudo mapeia para `rails`
- Score = skills encontradas no seu perfil / total de skills exigidas
- Se nenhuma skill é mencionada → score 1.0

### Experiência (25% do score)

| Situação | Score |
|----------|-------|
| Seus anos >= exigido | 1.0 |
| Falta 1 ano | 0.7 |
| Falta 2+ anos | 0.3 |
| Não mencionado | 1.0 |

### Educação (15% do score)

| Situação | Score |
|----------|-------|
| Seu grau >= exigido | 1.0 |
| Seu grau < exigido | 0.5 |
| Sem grau no perfil | 0.3 |
| Não mencionado | 1.0 |

### Threshold

- Default: **0.70** (70%)
- Configurável em `config.yml` → `matching.threshold`
- Vagas com score abaixo são puladas automaticamente

---

## Anti-Detecção

O bot implementa várias medidas para simular comportamento humano:

| Medida | Detalhes |
|--------|----------|
| Chrome flags | `--disable-blink-features=AutomationControlled` |
| CDP injection | Remove `navigator.webdriver` |
| Window size | Aleatório entre 1200-1400 x 800-1000 px |
| Delay entre ações | 0.8 - 2.5 segundos |
| Digitação humana | 50 - 200ms por caractere |
| Pausa entre candidaturas | 15 - 45 segundos |
| Break longo | 2 - 5 min a cada 5-8 candidaturas |
| Cap por sessão | Máximo 50 candidaturas |

> **Todos os valores são configuráveis** via `config.yml` nas seções `delays`, `polling` e `browser`.

---

## Easy Apply Flow

O bot navega o modal multi-step do Easy Apply:

1. Clica no botão **"Easy Apply"**
2. Detecta campos visíveis no modal (inputs, selects, textareas, checkboxes)
3. Preenche automaticamente usando:
   - **Mapeamento direto:** nome, email, telefone, cidade, cargo atual
   - **Dicionário de respostas:** `easy_apply_answers` no `profile.yml`
4. Avança no modal (Next → Next → Review → Submit)
5. Se encontra campo desconhecido → **pula com warning** (nunca inventa respostas)
6. Confirma sucesso da submissão
7. Máximo de **8 steps** por aplicação (safety limit)

---

## Estrutura do Projeto

```
bot/
├── Gemfile                              # Dependências Ruby
├── Gemfile.lock                         # Lock de versões
├── bin/
│   └── easy_apply                       # Entry point do CLI
├── config/
│   ├── config.yml                       # Configurações do bot
│   └── profile.yml.example              # Template do perfil
├── data/                                # Runtime data (gitignored)
│   ├── seen_jobs.json                   # Jobs já processados
│   └── applications_log.json            # Log de candidaturas
├── lib/
│   ├── easy_apply.rb                    # Módulo raiz
│   └── easy_apply/
│       ├── cli.rb                       # Thor CLI
│       ├── config_loader.rb             # Carrega + valida configs
│       ├── anti_detection.rb            # Delays humanos
│       ├── logger.rb                    # Logger dual (file + console)
│       ├── browser/
│       │   ├── driver_factory.rb        # Cria Chrome WebDriver
│       │   ├── session.rb               # Login via cookie li_at
│       │   └── wait_helpers.rb          # Smart waits + scroll
│       ├── linkedin/
│       │   ├── selectors.rb             # CSS/XPath centralizados
│       │   ├── job_search.rb            # Busca + paginação
│       │   ├── job_parser.rb            # Extrai detalhes da vaga
│       │   └── easy_apply_flow.rb       # Automação do modal
│       ├── matching/
│       │   ├── profile.rb               # Wrapper do perfil YAML
│       │   ├── requirement_extractor.rb # Extrai requisitos da descrição
│       │   └── scorer.rb               # Scoring ponderado
│       └── persistence/
│           ├── seen_jobs_store.rb       # Dedup store
│           └── application_log.rb       # Log de decisões
├── spec/                                # Testes RSpec
│   ├── spec_helper.rb
│   └── easy_apply/
│       ├── config_loader_spec.rb
│       ├── matching/
│       │   ├── requirement_extractor_spec.rb
│       │   └── scorer_spec.rb
│       └── persistence/
│           ├── seen_jobs_store_spec.rb
│           └── application_log_spec.rb
├── log/                                 # Runtime logs (gitignored)
├── .rspec                               # RSpec config
├── .rubocop.yml                         # Linter config
└── .gitignore
```

---

## Testes

```bash
# Rodar todos os testes
bundle exec rspec

# Rodar com output detalhado
bundle exec rspec --format documentation

# Rodar um arquivo específico
bundle exec rspec spec/easy_apply/matching/scorer_spec.rb
```

**32 testes** cobrindo:
- `ConfigLoader` — load, validação, detecção de erros (6 testes)
- `RequirementExtractor` — extração de skills, experiência, educação (11 testes)
- `Scorer` — scoring ponderado, thresholds, edge cases (7 testes)
- `SeenJobsStore` — tracking, persistência, contagem (4 testes)
- `ApplicationLog` — logging, estatísticas, recentes (4 testes)

---

## Persistência

### `data/seen_jobs.json`

Armazena IDs de vagas já processadas para evitar reprocessamento:

```json
{
  "3847291056": {
    "seen_at": "2026-03-03T14:30:00-03:00",
    "title": "Ruby Developer",
    "company": "TechCo"
  }
}
```

### `data/applications_log.json`

Log append-only de todas as decisões:

```json
[
  {
    "timestamp": "2026-03-03T14:32:15-03:00",
    "job_id": "3847291056",
    "title": "Ruby Developer",
    "company": "TechCo",
    "location": "Remote",
    "score": 0.85,
    "pass": true,
    "decision": "applied",
    "result": "success",
    "breakdown": {
      "skills": 0.8,
      "experience": 1.0,
      "education": 1.0
    }
  }
]
```

---

## Configuração Completa

### `config/config.yml`

```yaml
linkedin:
  li_at: "YOUR_LI_AT_COOKIE_HERE"        # Cookie de sessão LinkedIn

search:
  keywords: "Ruby Developer"              # Termos de busca
  location: "Brazil"                      # Localização
  easy_apply_only: true                   # Filtrar Easy Apply

matching:
  threshold: 0.70                         # Score mínimo (0.0 - 1.0)
  weights:
    skills: 0.60                          # Peso skills
    experience: 0.25                      # Peso experiência
    education: 0.15                       # Peso educação

polling:
  interval_seconds: 60                    # Intervalo entre ciclos
  max_applications_per_session: 50        # Cap por sessão
  break_after_applications: 7             # Pausa a cada N aplicações
  break_duration_seconds_min: 120         # Break mínimo (2 min)
  break_duration_seconds_max: 300         # Break máximo (5 min)

delays:
  between_actions_min: 0.8               # Delay mín entre ações (seg)
  between_actions_max: 2.5               # Delay máx entre ações (seg)
  between_applications_min: 15           # Pausa mín entre aplicações (seg)
  between_applications_max: 45           # Pausa máx entre aplicações (seg)
  typing_delay_min_ms: 50               # Velocidade digitação mín (ms)
  typing_delay_max_ms: 200              # Velocidade digitação máx (ms)

browser:
  headless: false                         # true = sem janela visível
  window_width_min: 1200                  # Largura mín da janela
  window_width_max: 1400                  # Largura máx da janela
  window_height_min: 800                  # Altura mín da janela
  window_height_max: 1000                 # Altura máx da janela
```

---

## Troubleshooting

### "LinkedIn session invalid. Check your li_at cookie."

O cookie `li_at` expirou. Obtenha um novo:
1. Login no LinkedIn → DevTools → Application → Cookies → copiar `li_at`
2. Atualizar `config/config.yml`

### "Could not find Easy Apply button"

A vaga pode ter mudado de Easy Apply para candidatura externa. O bot pula automaticamente e loga o motivo.

### "Unknown field: '...' - skipping"

O bot encontrou um campo no modal Easy Apply que não sabe preencher. Adicione o mapeamento em `profile.yml` → `easy_apply_answers`:

```yaml
easy_apply_answers:
  "nome do campo": "sua resposta"
```

### ChromeDriver version mismatch

Se o Chrome atualizou, baixe o ChromeDriver correspondente:
- Verifique: `google-chrome --version`
- Baixe em: https://googlechromelabs.github.io/chrome-for-testing/

### Testes falhando

```bash
bundle exec rspec --format documentation
```

Verifique se todas as gems estão instaladas: `bundle install`

---

## Gems Utilizadas

| Gem | Versão | Propósito |
|-----|--------|-----------|
| `selenium-webdriver` | ~> 4.20 | Automação do Chrome |
| `thor` | ~> 1.3 | Framework CLI |
| `rspec` | ~> 3.13 | Testes |
| `rubocop` | ~> 1.62 | Linter |
| `webmock` | ~> 3.23 | Mock HTTP para testes |

---

## Aviso Legal

Este projeto foi desenvolvido para fins educacionais. O uso de automação no LinkedIn pode violar os Termos de Serviço da plataforma. Use por sua conta e risco. O autor não se responsabiliza por quaisquer consequências do uso deste software, incluindo suspensão ou banimento de contas.

---

## Licença

MIT
