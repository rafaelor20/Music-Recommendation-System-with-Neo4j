# Visual Evidence & Expected Query Results (`docs/examples/`)

This directory is dedicated to storing **real Neo4j Browser screenshots** and reference outputs obtained from live executions of the Music Recommendation System.

> **Important Note:** Do not place synthetic or mock screenshots in this directory. All visual captures added here should be exported directly from Neo4j Browser (`http://localhost:7474`) after running `make constraints` and `make import`.

---

## Recommended Captures to Save in `docs/examples/`

When exploring the graph in **Neo4j Browser** (`http://localhost:7474`), run the queries below and use the **Export PNG / SVG** button in the top-right corner of the result frame to save snapshots here:

### 1. Graph Schema Visualization (`schema-visualization.png`)

```cypher
CALL db.schema.visualization();
```

### 2. Similar Users Subgraph (`similar-users-subgraph.png`)

First set the target user parameter:

```cypher
:param userId => 'u1'
```

Then visualize the shared liked tracks connecting `u1` (`Alice Martins`) to similar peers:

```cypher
MATCH path = (u1:User {id: $userId})-[:LIKED]->(shared:Track)<-[:LIKED]-(peer:User)
WHERE u1 <> peer
RETURN path
LIMIT 50;
```

### 3. Collaborative Filtering Recommendations Graph (`collaborative-recommendations-graph.png`)

```cypher
MATCH (u:User {id: $userId})-[:LIKED]->(shared:Track)<-[:LIKED]-(peer:User)
WHERE u <> peer
MATCH path = (peer)-[:LIKED]->(rec:Track)-[:PERFORMED_BY]->(a:Artist)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
RETURN path
LIMIT 40;
```

### 4. Followed Artists & Genres Network (`artists-and-genres-graph.png`)

```cypher
MATCH path = (u:User {id: $userId})-[:FOLLOWS]->(a:Artist)<-[:PERFORMED_BY]-(t:Track)-[:IN_GENRE]->(g:Genre)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(t)
RETURN path
LIMIT 50;
```
