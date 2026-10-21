# Automatize MEI

Projeto da disciplina de **Programação Orientada a Objetos**, com o objetivo de automatizar processos
de um MEI (Microempreendedor Individual) parceiro, atuante na produção e venda de geladinho gourmet
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

- **Backend (API):** Python + FastAPI, Programação Orientada a Objetos
- **Site:** Python
- **Aplicativo:** Flutter/Dart
- **Documentação da API:** Swagger (`/docs`)

## Estrutura do projeto

```
automatize-mei/
├── backend/        # API em Python (FastAPI): main.py, models/, schemas/, repositories/, services/, api/, core/, tests/
├── site/            # Interface adicional web (Python), consumindo a API
├── app_flutter/      # Interface adicional mobile (Flutter), consumindo a API
└── docs/             # Documentação técnica (exemplos de requisições, fluxo de erros)
```

## Como executar

### Backend

**Pré-requisitos:** Docker, Python 3.11+

1. **Suba o PostgreSQL:**
   ```bash
   docker compose up -d
   ```

2. **Crie o arquivo `.env`** copiando o exemplo e ajustando as variáveis:
   ```bash
   cp .env.example .env
   ```
   Variáveis disponíveis: `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `BUSINESS_TZ`.

3. **Instale as dependências Python:**
   ```bash
   pip install -r backend/requirements.txt
   ```

4. **Execute as migrations** (cria as tabelas no banco):
   ```bash
   alembic upgrade head
   ```

5. **Inicie o servidor** (executa a partir da raiz do projeto):
   ```bash
   uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
   ```
   A documentação interativa estará em `http://localhost:8000/docs`.

6. **Rode os testes de integração:**
   ```bash
   pytest backend/tests/
   ```

> **Emulador Android:** o endereço padrão do app para alcançar a máquina host é `http://10.0.2.2:8000`.
> Em dispositivos físicos, use o IP da máquina na rede local.

> **Dados compartilhados:** a API não tem autenticação; todos os clientes que apontarem para a mesma
> instância compartilham os mesmos dados.

## Status

🚧 Em desenvolvimento — estrutura inicial do repositório commitada; Tópicos I a VI do trabalho teórico definidos.
