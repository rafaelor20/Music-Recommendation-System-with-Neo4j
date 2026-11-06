// =============================================================================
// 01_import_data.cypher
// Idempotent CSV data import script using LOAD CSV WITH HEADERS and MERGE
// =============================================================================
// All numeric and temporal properties are explicitly cast.
// Executing this script multiple times will not duplicate nodes or relationships.

// 1. Create Users
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {id: trim(row.id)})
SET u.name = trim(row.name),
    u.createdAt = datetime(trim(row.createdAt));

// 2. Create Artists
LOAD CSV WITH HEADERS FROM 'file:///artists.csv' AS row
MERGE (a:Artist {id: trim(row.id)})
SET a.name = trim(row.name);

// 3. Create Genres
LOAD CSV WITH HEADERS FROM 'file:///genres.csv' AS row
MERGE (g:Genre {id: trim(row.id)})
SET g.name = trim(row.name);

// 4. Create Tracks
LOAD CSV WITH HEADERS FROM 'file:///tracks.csv' AS row
MERGE (t:Track {id: trim(row.id)})
SET t.title = trim(row.title),
    t.durationMs = toInteger(trim(row.durationMs)),
    t.releaseYear = toInteger(trim(row.releaseYear));

// 5. Associate Tracks with their Primary Artist (PERFORMED_BY)
LOAD CSV WITH HEADERS FROM 'file:///tracks.csv' AS row
MATCH (t:Track {id: trim(row.id)})
MATCH (a:Artist {id: trim(row.artistId)})
MERGE (t)-[:PERFORMED_BY]->(a);

// 6. Associate Tracks with Genres (IN_GENRE)
// Supports one or multiple semicolon-delimited genre IDs per track (e.g., "g1;g9")
LOAD CSV WITH HEADERS FROM 'file:///tracks.csv' AS row
MATCH (t:Track {id: trim(row.id)})
UNWIND split(trim(row.genreIds), ';') AS genreId
MATCH (g:Genre {id: trim(genreId)})
MERGE (t)-[:IN_GENRE]->(g);

// 7. Create Listening History Relationships (LISTENED_TO)
LOAD CSV WITH HEADERS FROM 'file:///listens.csv' AS row
MATCH (u:User {id: trim(row.userId)})
MATCH (t:Track {id: trim(row.trackId)})
MERGE (u)-[r:LISTENED_TO]->(t)
SET r.plays = toInteger(trim(row.plays)),
    r.lastPlayedAt = datetime(trim(row.lastPlayedAt));

// 8. Create Track Like Relationships (LIKED)
LOAD CSV WITH HEADERS FROM 'file:///likes.csv' AS row
MATCH (u:User {id: trim(row.userId)})
MATCH (t:Track {id: trim(row.trackId)})
MERGE (u)-[r:LIKED]->(t)
SET r.createdAt = datetime(trim(row.createdAt));

// 9. Create Artist Follow Relationships (FOLLOWS)
LOAD CSV WITH HEADERS FROM 'file:///follows.csv' AS row
MATCH (u:User {id: trim(row.userId)})
MATCH (a:Artist {id: trim(row.artistId)})
MERGE (u)-[r:FOLLOWS]->(a)
SET r.createdAt = datetime(trim(row.createdAt));
