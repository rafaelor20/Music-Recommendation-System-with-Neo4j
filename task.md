# TASK.md — Music Recommendation System with Neo4j

## 1. Objetivo

Desenvolver um projeto de recomendação musical inspirado no Spotify, utilizando exclusivamente o **Neo4j como banco de dados e mecanismo de recomendação**.

O objetivo é demonstrar conhecimentos de:
- Modelagem de dados orientada a grafos.
- Neo4j e linguagem Cypher.
- Importação e manipulação de dados com CSV.
- Consultas envolvendo múltiplos relacionamentos.
- Algoritmos básicos de recomendação.
- Docker e Docker Compose.

**Restrição principal:** Não implementar backend, API REST, frontend ou serviços externos. Toda a lógica de negócio deve ser executada diretamente no Neo4j por meio de consultas Cypher.

O projeto deve ser simples de executar, reproduzível e adequado para apresentação em um portfólio técnico.

---

## 2. Arquitetura

Utilizar a seguinte stack:

| Tecnologia | Responsabilidade |
|---|---|
| Neo4j Community Edition | Banco de dados em grafo |
| Cypher | Modelagem, importação e consultas |
| Docker | Containerização |
| Docker Compose | Orquestração do ambiente |
| CSV | Dataset de demonstração |
| Neo4j Browser | Interface para executar consultas e visualizar resultados |

Não adicionar dependências desnecessárias.

### Serviços e portas

- Neo4j Browser: `http://localhost:7474`
- Bolt: `bolt://localhost:7687`

Utilizar volumes Docker para persistência dos dados.

As credenciais devem ser configuradas por variáveis de ambiente, utilizando `.env.example` como referência.

Não versionar credenciais reais.

---

## 3. Modelagem do grafo

Criar os seguintes labels:

### User

Propriedades:
- `id`: identificador único.
- `name`: nome do usuário.
- `createdAt`: data de criação.

### Track

Propriedades:
- `id`: identificador único.
- `title`: título da música.
- `durationMs`: duração em milissegundos.
- `releaseYear`: ano de lançamento.

### Artist

Propriedades:
- `id`: identificador único.
- `name`: nome do artista.

### Genre

Propriedades:
- `id`: identificador único.
- `name`: nome do gênero.

### Relacionamentos

Implementar os seguintes relacionamentos:

| Origem | Relacionamento | Destino | Propriedades |
|---|---|---|---|
| User | LISTENED_TO | Track | plays, lastPlayedAt |
| User | LIKED | Track | createdAt |
| User | FOLLOWS | Artist | createdAt |
| Track | PERFORMED_BY | Artist | Nenhuma |
| Track | IN_GENRE | Genre | Nenhuma |

### Regras de modelagem

1. Um usuário pode escutar uma música diversas vezes.
2. O relacionamento `LISTENED_TO` deve armazenar a quantidade de reproduções e a data da última reprodução.
3. Uma curtida deve ser representada por `LIKED`, independentemente do histórico de reprodução.
4. Um usuário pode seguir vários artistas.
5. Uma música deve possuir um artista principal e pelo menos um gênero.
6. Não criar nós duplicados para a mesma entidade.
7. Utilizar identificadores estáveis para todos os nós.

Criar constraints de unicidade para os identificadores.

---

## 4. Estrutura do repositório

Criar a seguinte estrutura:

```text
music-recommendation-neo4j/
│
├── docker-compose.yml
├── .env.example
├── .gitignore
├── README.md
├── TASK.md
├── Makefile
│
├── data/
│   └── sample/
│       ├── users.csv
│       ├── artists.csv
│       ├── genres.csv
│       ├── tracks.csv
│       ├── listens.csv
│       ├── likes.csv
│       └── follows.csv
│
├── cypher/
│   ├── 00_constraints.cypher
│   ├── 01_import_data.cypher
│   ├── 02_basic_queries.cypher
│   ├── 03_business_queries.cypher
│   └── 04_recommendations.cypher
│
└── docs/
    ├── graph-model.png
    ├── recommendations.png
    └── examples/
```

Os arquivos CSV de demonstração devem ser versionados no Git.

O `.gitignore` deve ignorar arquivos `.env`, dados privados e arquivos temporários, sem excluir o dataset público de exemplo.

---

## 5. Dataset

Criar um dataset sintético, consistente e suficientemente pequeno para permitir testes rápidos.

Quantidade mínima desejada:

| Entidade | Quantidade |
|---|---:|
| Usuários | 20 |
| Artistas | 30 |
| Gêneros | 10 |
| Músicas | 100 |
| Reproduções | 200 |
| Curtidas | 100 |
| Seguimentos | 50 |

Os dados devem ser coerentes entre si.

### Regras importantes

- Utilizar nomes fictícios ou dados de demonstração devidamente identificados.
- Garantir que todos os IDs referenciados existam.
- Criar usuários com preferências musicais parcialmente compartilhadas.
- Criar usuários com gostos diferentes.
- Criar artistas associados a diferentes gêneros.
- Garantir que existam músicas ainda não curtidas ou escutadas pelos usuários, para possibilitar recomendações.
- Incluir casos que permitam validar a similaridade entre usuários.

O dataset deve ser determinístico: executar novamente o processo de geração deve produzir os mesmos dados.

---

## 6. Scripts Cypher

Todos os scripts devem ser executáveis pelo Neo4j Browser e pelo `cypher-shell`.

Utilizar comentários explicativos nas consultas.

### 6.1. Constraints

Arquivo: `00_constraints.cypher`

Criar constraints de unicidade para:
- User.id
- Artist.id
- Genre.id
- Track.id

Utilizar `IF NOT EXISTS` para permitir execução repetida.

### 6.2. Importação

Arquivo: `01_import_data.cypher`

Implementar a importação utilizando `LOAD CSV WITH HEADERS`.

A importação deve:

1. Criar usuários.
2. Criar artistas.
3. Criar gêneros.
4. Criar músicas.
5. Associar músicas aos artistas.
6. Associar músicas aos gêneros.
7. Criar relacionamentos de reprodução.
8. Criar relacionamentos de curtida.
9. Criar relacionamentos de seguimento.

Utilizar `MERGE` para evitar duplicação de nós e relacionamentos.

Converter explicitamente valores numéricos e datas.

A importação deve ser idempotente: executar o script novamente não deve duplicar entidades ou interações.

Para isso, definir corretamente as chaves de cada relacionamento e atualizar propriedades quando necessário.

### 6.3. Consultas básicas

Arquivo: `02_basic_queries.cypher`

Implementar pelo menos:

1. Listar todos os usuários.
2. Listar músicas e respectivos artistas.
3. Listar músicas por gênero.
4. Listar artistas mais seguidos.
5. Listar gêneros mais reproduzidos.
6. Listar músicas mais reproduzidas.
7. Consultar o histórico musical de um usuário.

### 6.4. Consultas de negócio

Arquivo: `03_business_queries.cypher`

Implementar consultas que respondam:

1. Quais são os artistas mais populares?
2. Quais gêneros são mais populares?
3. Quais usuários possuem gostos musicais semelhantes?
4. Quais músicas são compartilhadas entre dois usuários?
5. Quais artistas são mais seguidos por usuários com preferências semelhantes?
6. Quais músicas possuem muitas reproduções, mas poucas curtidas?

Utilizar parâmetros Cypher quando a consulta depender de um usuário específico.

Exemplo:

```cypher
:param userId => 'u1'
```

### 6.5. Recomendações

Arquivo: `04_recommendations.cypher`

Implementar três estratégias de recomendação.

**Estratégia A — Collaborative Filtering**

Encontrar usuários que curtiram músicas em comum com o usuário atual e recomendar outras músicas curtidas por esses usuários.

Regras:
- Identificar usuários semelhantes.
- Encontrar músicas curtidas por eles.
- Excluir músicas já curtidas ou escutadas pelo usuário atual.
- Agrupar recomendações.
- Ordenar pelo número de usuários semelhantes que curtiram a música.
- Retornar as dez melhores recomendações.

**Estratégia B — Recomendação baseada em artistas**

Utilizar artistas seguidos pelo usuário para encontrar outras músicas desses artistas.

Regras:
- Identificar artistas seguidos.
- Encontrar músicas desses artistas.
- Excluir músicas já conhecidas pelo usuário.
- Priorizar artistas seguidos por ele.

**Estratégia C — Recomendação baseada em gêneros**

Identificar os gêneros mais presentes no histórico de curtidas e reproduções do usuário.

Regras:
- Calcular a preferência por gênero.
- Encontrar músicas desses gêneros.
- Excluir músicas já conhecidas pelo usuário.
- Ordenar as recomendações por relevância.

As três estratégias devem ser consultas Cypher independentes e facilmente testáveis.

Não implementar machine learning ou algoritmos complexos nesta primeira versão.

---

## 7. Docker Compose

Criar um `docker-compose.yml` com:

- Neo4j Community Edition.
- Portas 7474 e 7687.
- Autenticação configurada por variável de ambiente.
- Volume persistente para `/data`.
- Volume para logs.
- Dataset disponibilizado no diretório de importação do Neo4j.
- Scripts Cypher disponibilizados em um diretório somente leitura.

Utilizar uma versão oficial e estável da imagem Neo4j Community compatível com a sintaxe utilizada.

Não utilizar `latest` sem necessidade.

---

## 8. Makefile

Criar comandos para simplificar a utilização:

```makefile
up:
    docker compose up -d

down:
    docker compose down

logs:
    docker compose logs -f neo4j

shell:
    docker compose exec neo4j cypher-shell

constraints:
    # Executar 00_constraints.cypher

import:
    # Executar 01_import_data.cypher

queries:
    # Orientar a execução das consultas pelo Browser

reset:
    # Remover os dados persistidos e recriar o ambiente
```

Os comandos devem funcionar corretamente no ambiente documentado.

A senha deve ser obtida das variáveis de ambiente, sem ficar escrita diretamente nos comandos.

O comando `reset` deve ser explicitamente destrutivo e documentado.

---

## 9. Documentação README

Criar um README completo, preferencialmente em inglês, com:

1. Project Overview.
2. Problem Statement.
3. Why Neo4j?
4. Architecture.
5. Graph Data Model.
6. Dataset Description.
7. Prerequisites.
8. Installation.
9. Docker Compose Setup.
10. Database Initialization.
11. Data Import.
12. Basic Cypher Queries.
13. Business Queries.
14. Recommendation Strategies.
15. Expected Results.
16. Troubleshooting.
17. Future Improvements.

### Modelo do grafo

Gerar um diagrama visual que apresente:
- Labels dos nós.
- Tipos de relacionamentos.
- Direção dos relacionamentos.
- Propriedades importantes.

Salvar em `docs/graph-model.png`.

Pode utilizar Mermaid, Arrows.app ou outra ferramenta apropriada.

### Evidências visuais

Documentar exemplos de resultados esperados.

Preparar a estrutura para adicionar capturas do Neo4j Browser mostrando:
- Modelo do grafo.
- Usuários semelhantes.
- Recomendações geradas.
- Artistas e gêneros relacionados.

Não criar screenshots fictícias. As evidências devem ser obtidas de execuções reais.

---

## 10. Critérios de qualidade

O projeto deve seguir estas regras:

- Não adicionar backend ou frontend.
- Não depender de serviços externos.
- Não exigir APIs ou chaves de terceiros.
- Manter o Cypher legível e comentado.
- Utilizar constraints e `MERGE` adequadamente.
- Evitar duplicações de dados.
- Garantir integridade referencial durante a importação.
- Utilizar parâmetros nas consultas que dependem do usuário.
- Manter o dataset pequeno e reproduzível.
- Documentar decisões relevantes de modelagem.
- Não adicionar bibliotecas ou plugins sem justificativa.

---

## 11. Critérios de aceitação

Considerar a tarefa concluída somente quando todos os seguintes critérios forem atendidos:

### Ambiente

- [x] `docker compose up -d` inicia o Neo4j corretamente.
- [x] Neo4j Browser está acessível.
- [x] Autenticação funciona.
- [x] Dados persistem após reiniciar o container.

### Modelagem

- [x] Os quatro labels foram criados.
- [x] Os cinco tipos de relacionamentos foram implementados.
- [x] Constraints estão funcionando.
- [x] Não existem nós duplicados.

### Dataset

- [x] Todos os arquivos CSV estão presentes.
- [x] IDs e referências são consistentes.
- [x] A importação funciona.
- [x] Executar novamente a importação não duplica os dados.

### Consultas

- [x] Consultas básicas funcionam.
- [x] Consultas de negócio funcionam.
- [x] As três estratégias de recomendação funcionam.
- [x] Recomendações excluem músicas já conhecidas.
- [x] Resultados podem ser visualizados no Neo4j Browser.

### Documentação

- [x] README contém instruções completas.
- [x] Diagrama do grafo está disponível.
- [x] Exemplos de consultas estão documentados.
- [x] Problemas conhecidos e soluções estão registrados.

### Reprodutibilidade

Uma pessoa que nunca utilizou o projeto deve conseguir:

1. Clonar o repositório.
2. Configurar o `.env`.
3. Iniciar o Docker Compose.
4. Criar as constraints.
5. Importar o dataset.
6. Executar consultas.
7. Obter recomendações para um usuário de demonstração.

Tudo isso sem instalar Neo4j diretamente na máquina.

---

## 12. Processo de implementação do agente

Executar o desenvolvimento em etapas.

### Etapa 1 — Estrutura e infraestrutura

- Criar estrutura do repositório.
- Criar Docker Compose.
- Criar `.env.example` e `.gitignore`.
- Validar inicialização do Neo4j.

### Etapa 2 — Modelagem e dataset

- Criar CSVs.
- Criar constraints.
- Criar scripts de importação.
- Validar relacionamentos e integridade dos dados.

### Etapa 3 — Consultas

- Implementar consultas básicas.
- Implementar consultas de negócio.
- Implementar as três estratégias de recomendação.
- Validar os resultados com usuários de demonstração.

### Etapa 4 — Documentação

- Criar README.
- Criar diagrama do grafo.
- Documentar consultas e resultados esperados.
- Documentar troubleshooting.

### Etapa 5 — Validação final

Executar todos os procedimentos a partir de um ambiente limpo.

Verificar:
- Inicialização.
- Importação.
- Idempotência.
- Constraints.
- Consultas.
- Recomendações.
- Persistência.

Corrigir eventuais problemas antes de considerar a tarefa concluída.

---

## 13. Entrega final do agente

Ao concluir, apresentar um relatório contendo:

1. Arquivos criados.
2. Decisões de modelagem adotadas.
3. Estratégias de recomendação implementadas.
4. Comandos necessários para executar o projeto.
5. Consultas utilizadas para validar o funcionamento.
6. Resultados dos testes realizados.
7. Limitações conhecidas.
8. Melhorias futuras recomendadas.

**Importante:** Não declarar testes como aprovados sem executá-los. Diferenciar claramente funcionalidades implementadas, funcionalidades validadas e funcionalidades pendentes.

O resultado esperado é um repositório pequeno, didático, funcional e profissional, demonstrando o potencial do Neo4j para sistemas de recomendação musical.