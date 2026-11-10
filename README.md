# Automatize MEI

Projeto da disciplina de **Programação Orientada a Objetos**, com o objetivo de automatizar processos
de um MEI (Microempreendedor Individual) parceira, atuante na produção e venda de geladinho gourmet
e salgadinho de copo há aproximadamente 9 anos (com um intervalo de pausa no meio desse período).

## I. Integrantes e parceira

| Integrante | Frente | Responsabilidade |
|---|---|---|
| Gustavo Moreira Annibal | Frontend | Site (Python) + Documentação (exemplos de requisição, Swagger revisado) |
| Alisson Casalli | Frontend | Aplicativo (Flutter) |
| Arthur Broleze | Frontend | Apoio geral tanto no site quanto no app |
| Guilherme dos Santos | Backend | API + Testes automatizados |
| Isadora Lamas | Backend | API |
| Maria Bueno | Backend | Banco de dados (modelagem e persistência) e criptografia |

**Revisão de merge/conflitos:** Guilherme e Gustavo.

A parceira vende geladinho gourmet e salgadinho de copo próximo a uma escola, com uma base diária de
60 a 80 clientes, concentrados nos horários de saída dos alunos. Demonstrou interesse em se atualizar
tecnologicamente, inclusive planejando comprar um notebook para isso.

## II. Ponto focal do trabalho

**Área escolhida:** Gestão de Estoque Operacional e Controle Financeiro Simplificado.

**Processos a automatizar:**
- Controle diário de vendas e fechamento de caixa (hoje feito por contagem manual de moedas e cédulas).
- Controle de produção e estoque congelado (registro do lote produzido e do saldo disponível no freezer).

**Restrição central de design:** a parceira possui baixa alfabetização e depende de estímulos visuais.
Por isso, a solução **não pode** ser baseada em texto corrido, menus extensos ou planilhas numéricas —
precisa ser centrada em ícones, cores e imagens dos produtos.

## III. Solução

A solução é um **aplicativo integrado a uma API**, substituindo o controle manual atual. Ela cobre três
frentes:
- **Controle financeiro:** registro de entradas (vendas) e saídas (ingredientes, embalagens, gás), com
  cálculo automático de lucro diário/semanal/mensal.
- **Controle de estoque e produção:** registro de insumos por lote, cálculo de custo unitário e apoio à
  decisão de preço e reposição.
- **Registro de clientela e sazonalidade:** registro de vendas por horário/dia da semana, para identificar
  picos de movimento e ajustar a produção.

> Nota: a documentação teórica original do grupo descreve esta solução usando a analogia de "planilha
> eletrônica". Na prática, ela é implementada como app + API — não como Excel/Google Planilhas —, para
> atender à restrição de acessibilidade do Tópico II.

## IV. Plano de execução

Cronograma de aproximadamente **2 meses**, com rodízio de integrantes entre frentes (regra de negócio,
endpoints, telas) em vez de papéis fixos por camada.

| Semana | Foco |
|---|---|
| 1 | Modelagem de domínio e definição técnica (stack da API e estrutura Flutter) |
| 2–3 | Regras de negócio (cálculo de custo, lucro, baixa de estoque) |
| 4–5 | Construção dos endpoints da API + telas do app, interface centrada em ícones/imagens |
| 6 | Integração API ↔ app, com revisão cruzada de código |
| 7 | Testes de usabilidade simulando baixo letramento (fluxo só com ícones) |
| 8 | Documentação técnica, revisão geral e buffer |

**Fluxo de Git:** cada integrante trabalha em sua própria branch; Guilherme e Gustavo revisam e tratam
conflitos antes do merge.

## V. Plano de implantação

A implantação será simples e orientada à realidade da parceira. Após a finalização do app, **Maria**
será responsável por realizar a capacitação, de forma presencial, demonstrando diretamente na tela do
dispositivo como registrar produção, vendas e consultar saldo/lucro — sem depender de manual escrito,
dado o perfil de baixa alfabetização da parceira. Maria também acompanhará o uso da parceira após a
capacitação, verificando se a solução atendeu de fato à sua necessidade e se ajustes adicionais de
orientação são necessários.

## VI. Resultados esperados

Espera-se que a solução reduza o tempo e o esforço gastos hoje no fechamento manual de caixa e na
contagem física do estoque no freezer, substituindo-os por registro simples e visual. Como contribuição
direta, a parceira passa a ter visibilidade real sobre lucro, custo por lote e padrões de venda por
horário — informação que hoje não existe de forma estruturada —, apoiando decisões futuras sobre preço,
produção e expansão (ex: venda por redes sociais, mencionada por ela na entrevista).

## Tecnologias

- **Backend (API):** Python 3.12+ · FastAPI · SQLAlchemy · Alembic · PostgreSQL · JWT (python-jose) · bcrypt
- **Site:** Python — _pendente de implementação_
- **Aplicativo:** Flutter/Dart
- **Documentação interativa da API:** Swagger em `/docs`
- **Testes:** pytest + httpx

## Arquitetura do backend

O backend segue uma arquitetura em camadas (MVC-like), separando claramente responsabilidades:

```
Controller  →  recebe a requisição HTTP e delega ao Service
Service     →  aplica as regras de negócio e coordena transações
Repository  →  acessa o banco de dados via SQLAlchemy ORM
Model       →  define o esquema das tabelas (mapeamento ORM)
Schema      →  valida e serializa dados de entrada/saída (Pydantic v2)
Core        →  configuração, conexão ao banco, segurança (JWT/bcrypt), dependências
```

## Endpoints implementados

Todos os endpoints (exceto `/auth`) exigem o header `Authorization: Bearer <token>`.

| Módulo | Método | Rota | Descrição |
|---|---|---|---|
| Auth | POST | `/auth/register` | Cadastra usuário (senha armazenada como hash bcrypt) |
| Auth | POST | `/auth/login` | Autentica e retorna token JWT |
| Produtos | GET | `/produtos` | Lista todos os produtos |
| Produtos | GET | `/produtos/{id}` | Busca produto por ID |
| Produtos | POST | `/produtos` | Cria produto |
| Produtos | PUT | `/produtos/{id}` | Atualiza produto |
| Produtos | DELETE | `/produtos/{id}` | Remove produto |
| Vendas | GET | `/vendas` | Lista todas as vendas |
| Vendas | POST | `/vendas` | Registra venda e baixa estoque atomicamente |
| Vendas | DELETE | `/vendas/{id}` | Cancela venda e restaura estoque |
| Despesas | GET | `/despesas` | Lista todas as despesas |
| Despesas | POST | `/despesas` | Registra despesa |
| Despesas | DELETE | `/despesas/{id}` | Remove despesa |
| Fechamentos | GET | `/fechamentos` | Lista histórico de fechamentos de caixa |
| Fechamentos | POST | `/fechamentos` | Fecha o caixa do dia (totais recalculados pelo servidor) |
| Fechamentos | DELETE | `/fechamentos/{id}` | Reabre fechamento |
| Produções | POST | `/producoes` | Registra lote produzido e incrementa estoque |
| Perdas | POST | `/perdas` | Registra perda e decrementa estoque |

## Estrutura do projeto

```
automatize-mei/
├── backend/
│   ├── app/
│   │   ├── controller/     # Rotas HTTP (FastAPI APIRouter por domínio)
│   │   ├── services/       # Regras de negócio e coordenação de transações
│   │   ├── repositories/   # Acesso ao banco de dados (ORM)
│   │   ├── models/         # Modelos SQLAlchemy (mapeamento de tabelas)
│   │   ├── schemas/        # Schemas Pydantic (validação e serialização)
│   │   ├── core/           # Config, DB, segurança (JWT/bcrypt), dependências, timezone
│   │   └── main.py         # Ponto de entrada da aplicação FastAPI
│   ├── alembic/            # Migrations do banco de dados
│   │   └── versions/       # 001 schema inicial · 002 usuários e CHECKs · 003 total_pix
│   ├── tests/              # Testes de integração (pytest + httpx)
│   ├── alembic.ini
│   └── requirements.txt
├── database/
│   └── connection.py       # Engine e SessionLocal compartilhados (SQLAlchemy)
├── site/                   # Interface web Python — pendente de implementação
│   ├── app.py              # (stub)
│   ├── templates/          # (stub)
│   └── static/
├── app_flutter/            # Aplicativo mobile Flutter — em desenvolvimento
├── docs/                   # Documentação técnica (exemplos de requisição, fluxo de erros)
├── scripts/
│   └── criar_usuario.py    # Script auxiliar para criação de usuário via CLI
├── docker-compose.yml      # Sobe o PostgreSQL na porta 5433
├── .env.example
└── README.md
```

## Tabelas do banco de dados

| Tabela | Descrição |
|---|---|
| `usuarios` | Usuários com senha_hash bcrypt e cargo |
| `produtos` | Produtos com nome, preço e estoque atual |
| `vendas` | Registro de vendas (produto, quantidade, valor, forma de pagamento) |
| `despesas` | Despesas por categoria (ingredientes, embalagem, gás, outros) |
| `fechamentos` | Fechamento de caixa diário com totais recalculados pelo servidor |
| `producoes` | Entradas de produção por lote (incrementa estoque) |
| `perdas` | Baixas por perda (decrementa estoque) |

## Como executar

### Pré-requisitos

- Docker (para o PostgreSQL)
- Python 3.12+

### 1. Configurar variáveis de ambiente

```bash
cp .env.example .env
```

O arquivo `.env` já contém valores funcionais para desenvolvimento. A `SECRET_KEY` deve ter no mínimo 32 caracteres.

### 2. Subir o PostgreSQL

```bash
docker compose up -d
```

O PostgreSQL fica disponível na porta `5433` do host (dentro do container usa `5432`).

### 3. Instalar dependências Python

```bash
pip install -r backend/requirements.txt
```

### 4. Executar as migrations

```bash
alembic -c backend/alembic.ini upgrade head
```

### 5. Iniciar o servidor (executar da raiz do projeto)

```bash
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

A documentação interativa Swagger estará em `http://localhost:8000/docs`.

### 6. Rodar os testes de integração

```bash
pytest backend/tests/
```

> **Emulador Android:** o endereço padrão do app para alcançar a máquina host é `http://10.0.2.2:8000`.
> Em dispositivos físicos, use o IP da máquina na rede local.

## Status

| Componente | Status |
|---|---|
| Backend — Auth (register/login, JWT, bcrypt) | ✅ Implementado |
| Backend — Produtos (CRUD completo) | ✅ Implementado |
| Backend — Vendas (registro + baixa de estoque atômica, cancelamento) | ✅ Implementado |
| Backend — Despesas (CRUD com bloqueio por fechamento de caixa) | ✅ Implementado |
| Backend — Fechamentos de caixa (totais calculados servidor) | ✅ Implementado |
| Backend — Produções (registro de lote + incremento de estoque) | ✅ Implementado |
| Backend — Perdas (registro + decremento de estoque com validação) | ✅ Implementado |
| Backend — Migrations (3 versões: schema, usuários/CHECKs, total_pix) | ✅ Implementado |
| Backend — Testes de integração | 🔄 Parcial (auth, vendas, despesas, fechamentos) |
| Aplicativo Flutter | 🔄 Em desenvolvimento |
| Site Python | ⬜ Pendente |
