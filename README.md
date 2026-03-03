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
cd LinkedIn-Easy-Apply-MentoriaOperacao/bot

bundle install
```

> **Importante:** Todos os comandos do bot devem ser executados de dentro da pasta `bot/`.

---

## Quick Start (Passo a Passo Completo)

### Passo 1 — Clonar e instalar

```bash
git clone https://github.com/Lucasdfg07/LinkedIn-Easy-Apply-MentoriaOperacao.git
cd LinkedIn-Easy-Apply-MentoriaOperacao/bot
bundle install
```

### Passo 2 — Exportar seu perfil do LinkedIn como PDF

1. Acesse seu perfil no LinkedIn: `linkedin.com/in/seu-usuario`
2. Clique no botao **"More" / "Mais"** (ao lado de "Open to")
3. Clique em **"Save to PDF" / "Salvar em PDF"**
4. Salve o arquivo (ex: `MeuPerfil.pdf`)

### Passo 3 — Gerar o `profile.yml` com ChatGPT

Abra o ChatGPT (ou qualquer LLM), **envie o PDF exportado** e cole o seguinte prompt:

---

> **Prompt para colar no ChatGPT:**

````
Analise o PDF do meu perfil do LinkedIn que enviei e gere um arquivo YAML
seguindo EXATAMENTE este formato. Preencha todos os campos com os dados
extraidos do meu perfil.

REGRAS IMPORTANTES:
- Skills devem ser termos tecnicos em lowercase, sem espacos (use underscore)
- O campo "degree" deve ser EXATAMENTE um destes: high_school, associate, bachelor, master, phd
- O campo "years" deve ser o total de anos de experiencia profissional
- Em "easy_apply_answers", preencha com respostas reais baseadas no meu perfil
- NAO invente dados — se algo nao consta no PDF, deixe vazio ou com valor generico

FORMATO OBRIGATORIO:

```yaml
personal:
  first_name: ""
  last_name: ""
  email: ""            # Se nao constar no PDF, deixe "seu@email.com" para eu preencher
  phone: ""            # Se nao constar no PDF, deixe "+55 11 00000-0000" para eu preencher
  city: ""
  country: ""

experience:
  years: 0             # Total de anos de experiencia profissional
  current_title: ""    # Cargo mais recente
  summary: ""          # Resumo de 1 linha do headline ou about

education:
  degree: ""           # EXATAMENTE: high_school | associate | bachelor | master | phd
  field: ""            # Area de formacao

skills:
  - skill_em_lowercase
  - outra_skill
  # Liste TODAS as skills do perfil + skills implicitas das experiencias

languages:
  - name: ""
    proficiency: ""    # native | professional | limited

easy_apply_answers:
  "years of experience": ""
  "salary expectation": "Open to discuss"
  "work authorization": "Yes"
  "sponsorship": "No"
  "remote": "Yes"
  "start date": "Immediately"
  "notice period": "2 weeks"
  "willing to relocate": "Yes"
  "linkedin profile": ""     # URL do meu LinkedIn
  "website": ""              # Se houver
  "github": ""               # Se houver
```

Retorne SOMENTE o YAML, sem explicacoes. Vou copiar e colar direto no arquivo.
````

---

Depois que o ChatGPT gerar o YAML:

```bash
# Crie o arquivo de perfil
cp config/profile.yml.example config/profile.yml

# Cole o conteudo gerado pelo ChatGPT no arquivo:
# Abra config/profile.yml no seu editor e substitua o conteudo
```

> **Dica:** Revise o YAML gerado. Confira se email, telefone e skills estao corretos. O ChatGPT pode nao ter acesso a todos os dados do PDF.

### Passo 4 — Obter o cookie `li_at`

O bot usa o cookie de sessao do LinkedIn para autenticar (sem precisar de login/senha):

1. Abra o **Google Chrome** e faca login no LinkedIn normalmente
2. Pressione **F12** para abrir o DevTools
3. Va na aba **Application** (ou "Aplicativo")
4. No menu lateral, expanda **Cookies** → clique em `https://www.linkedin.com`
5. Procure o cookie chamado **`li_at`**
6. Clique no valor e copie (e um texto longo tipo `AQEDAQNj...`)

![Como encontrar o cookie li_at](https://i.imgur.com/placeholder.png)

Agora cole o valor em `config/config.yml`:

```yaml
linkedin:
  li_at: "AQEDAQxxxxxxxxxxxxxxxxxxxxxx..."   # Cole aqui o valor copiado
```

> **O cookie `li_at` expira a cada ~30 dias.** Se o bot der erro de sessao, repita este passo.

### Passo 5 — Configurar a busca

A query de busca e **gerada automaticamente** a partir da **skill principal** do `profile.yml`.
Voce so precisa configurar os filtros em `config/config.yml`:

```yaml
search:
  # A skill de busca vem do primary_skill no profile.yml
  # Incluir filtro de remoto na query
  include_remote: true

  # Vagas postadas nas ultimas N horas (24 = ultimo dia, 168 = semana, 720 = mes)
  posted_hours: 24

  # Tipo de trabalho (1 = presencial, 2 = remoto, 3 = hibrido)
  work_type: 2

  # Area geografica (92000000 = Worldwide, 106057199 = Brazil, 103644278 = US)
  geo_id: 92000000

  # Apenas Easy Apply
  easy_apply_only: true
```

#### Como funciona

O bot le o campo `primary_skill` do `profile.yml` e monta a query:

| `primary_skill` no profile | Query gerada |
|---------------------------|--------------|
| `ruby` | `"Ruby" AND ("remote" OR "remoto")` |
| `react` | `"React" AND ("remote" OR "remoto")` |
| `python` | `"Python" AND ("remote" OR "remoto")` |
| `nodejs` | `"Node.js" AND ("remote" OR "remoto")` |
| `rails` | `"Ruby on Rails" AND ("remote" OR "remoto")` |
| `golang` | `"Golang" AND ("remote" OR "remoto")` |

A skill e formatada automaticamente para o LinkedIn (ex: `nodejs` → `"Node.js"`, `rails` → `"Ruby on Rails"`, `cpp` → `"C++"`).

Se `include_remote: false`, a query fica apenas `"Ruby"`.

#### Definindo a skill principal no profile.yml

```yaml
# A PRIMEIRA linha relevante do profile define a busca
primary_skill: ruby    # → busca por "Ruby"
```

A `primary_skill` deve ser a tecnologia que **define seu perfil**:
- Perfil Ruby + React → `primary_skill: ruby`
- Perfil React + Node → `primary_skill: react`
- Perfil backend Node → `primary_skill: nodejs`
- Perfil Python Data → `primary_skill: python`
- Perfil DevOps → `primary_skill: kubernetes`

> Se `primary_skill` nao estiver definido, o bot usa a **primeira skill** da lista `skills:`.

#### GeoIDs mais usados

| Regiao | GeoId |
|--------|-------|
| Worldwide | `92000000` |
| Brazil | `106057199` |
| United States | `103644278` |
| European Union | `91000000` |
| United Kingdom | `101165590` |
| Canada | `101174742` |
| Germany | `101282230` |
| Portugal | `100364837` |

### Passo 6 — Validar tudo

```bash
ruby bin/easy_apply validate
```

Se tudo estiver certo:
```
  Query:     "Ruby" AND ("remote" OR "remoto")
  Posted:    last 24h
  Work type: Remote
  Threshold: 0.7
  Primary:   ruby
  Skills:    15 total

✓ Config and profile are valid!
```

Se houver erro, o bot dira exatamente o que corrigir.

### Passo 7 — Testar com Dry Run (IMPORTANTE!)

**Sempre rode o dry run primeiro** para ver os scores sem aplicar de verdade:

```bash
ruby bin/easy_apply run --dry-run
```

O bot vai:
- Abrir o Chrome
- Fazer login com seu cookie
- Buscar vagas
- Mostrar o score de cada uma
- **NAO aplicar para nenhuma**

Verifique se os scores fazem sentido. Se muitas vagas boas estao sendo puladas, diminua o threshold em `config.yml`:

```yaml
matching:
  threshold: 0.60   # Mais permissivo (default: 0.70)
```

### Passo 8 — Rodar de verdade

Quando estiver satisfeito com o dry run:

```bash
ruby bin/easy_apply run
```

O bot vai rodar em loop:
1. Busca vagas → Pontua → Aplica se score >= threshold
2. Espera 60 segundos
3. Repete

**Para parar:** pressione `Ctrl+C` a qualquer momento (o bot para graciosamente).

### Passo 9 — Acompanhar resultados

```bash
ruby bin/easy_apply status
```

Ou confira diretamente o log em `data/applications_log.json`.

---

## Configuracao Avancada

### Ajustar matching

```yaml
matching:
  threshold: 0.70               # Score minimo para aplicar (0.0 - 1.0)
  weights:
    skills: 0.60                # Peso das skills (60%)
    experience: 0.25            # Peso da experiencia (25%)
    education: 0.15             # Peso da educacao (15%)
```

### Ajustar velocidade e seguranca

```yaml
polling:
  interval_seconds: 60                    # Tempo entre ciclos de busca
  max_applications_per_session: 50        # Maximo de aplicacoes por sessao
  break_after_applications: 7             # Pausa a cada N aplicacoes
  break_duration_seconds_min: 120         # Pausa minima (2 min)
  break_duration_seconds_max: 300         # Pausa maxima (5 min)

delays:
  between_actions_min: 0.8               # Delay entre cliques (seg)
  between_actions_max: 2.5
  between_applications_min: 15           # Espera entre candidaturas (seg)
  between_applications_max: 45
```

> **Dica de seguranca:** Se quiser ser mais conservador, aumente os delays e diminua o max_applications_per_session para 20-30.

---

## Referencia de Comandos

> **Todos os comandos devem ser executados de dentro da pasta `bot/`**

```bash
cd bot
```

| Comando | O que faz |
|---------|-----------|
| `ruby bin/easy_apply validate` | Valida config + profile e mostra a query gerada |
| `ruby bin/easy_apply run --dry-run` | Busca vagas, mostra scores, **nao aplica** |
| `ruby bin/easy_apply run` | Modo live: busca + pontua + aplica em loop |
| `ruby bin/easy_apply status` | Mostra estatisticas da sessao |
| `ruby bin/easy_apply help` | Lista todos os comandos |

### Flags do `run`

| Flag | Default | Descricao |
|------|---------|-----------|
| `--dry-run` | `false` | Busca e pontua sem aplicar |
| `--config PATH` | `config/config.yml` | Caminho para config alternativo |
| `--profile PATH` | `config/profile.yml` | Caminho para profile alternativo |

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
