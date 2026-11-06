// =============================================================================
// 02_basic_queries.cypher
// Basic exploration queries to inspect nodes, relationships, and user activity
// =============================================================================
// Before running query #7 in Neo4j Browser, set the target user parameter:
//   :param userId => 'u1'
// =============================================================================

// -----------------------------------------------------------------------------
// 1. List all users ordered by registration date
// -----------------------------------------------------------------------------
MATCH (u:User)
RETURN u.id AS userId,
       u.name AS userName,
       toString(u.createdAt) AS createdAt
ORDER BY u.createdAt ASC, u.id ASC;

// -----------------------------------------------------------------------------
// 2. List tracks and their respective primary artists
// -----------------------------------------------------------------------------
MATCH (t:Track)-[:PERFORMED_BY]->(a:Artist)
RETURN t.id AS trackId,
       t.title AS trackTitle,
       a.id AS artistId,
       a.name AS artistName,
       t.releaseYear AS releaseYear,
       round(t.durationMs / 1000.0, 1) AS durationSeconds
ORDER BY a.name ASC, t.releaseYear DESC, t.title ASC
LIMIT 25;

// -----------------------------------------------------------------------------
// 3. List tracks grouped by genre
// -----------------------------------------------------------------------------
MATCH (t:Track)-[:IN_GENRE]->(g:Genre)
MATCH (t)-[:PERFORMED_BY]->(a:Artist)
RETURN g.id AS genreId,
       g.name AS genreName,
       count(t) AS totalTracks,
       collect(t.title + ' (' + a.name + ')')[0..5] AS sampleTracks
ORDER BY totalTracks DESC, genreName ASC;

// -----------------------------------------------------------------------------
// 4. List the most followed artists
// -----------------------------------------------------------------------------
MATCH (a:Artist)
OPTIONAL MATCH (u:User)-[:FOLLOWS]->(a)
RETURN a.id AS artistId,
       a.name AS artistName,
       count(DISTINCT u) AS followersCount
ORDER BY followersCount DESC, artistName ASC
LIMIT 15;

// -----------------------------------------------------------------------------
// 5. List the most played genres (by total play count and unique listeners)
// -----------------------------------------------------------------------------
MATCH (u:User)-[l:LISTENED_TO]->(t:Track)-[:IN_GENRE]->(g:Genre)
RETURN g.id AS genreId,
       g.name AS genreName,
       sum(l.plays) AS totalPlays,
       count(DISTINCT u) AS uniqueListeners,
       count(DISTINCT t) AS distinctTracksPlayed
ORDER BY totalPlays DESC, uniqueListeners DESC;

// -----------------------------------------------------------------------------
// 6. List the most played tracks
// -----------------------------------------------------------------------------
MATCH (u:User)-[l:LISTENED_TO]->(t:Track)-[:PERFORMED_BY]->(a:Artist)
RETURN t.id AS trackId,
       t.title AS trackTitle,
       a.name AS artistName,
       sum(l.plays) AS totalPlays,
       count(DISTINCT u) AS uniqueListeners
ORDER BY totalPlays DESC, uniqueListeners DESC
LIMIT 15;

// -----------------------------------------------------------------------------
// 7. Query the musical history of a specific user (listens + liked status)
// Note: In Neo4j Browser, run `:param userId => 'u1'` first if not already set.
// -----------------------------------------------------------------------------
MATCH (u:User {id: COALESCE($userId, 'u1')})-[l:LISTENED_TO]->(t:Track)-[:PERFORMED_BY]->(a:Artist)
OPTIONAL MATCH (t)-[:IN_GENRE]->(g:Genre)
WITH u, t, a, l, collect(DISTINCT g.name) AS genres,
     EXISTS((u)-[:LIKED]->(t)) AS isLiked
RETURN u.name AS userName,
       t.id AS trackId,
       t.title AS trackTitle,
       a.name AS artistName,
       genres,
       l.plays AS plays,
       isLiked,
       toString(l.lastPlayedAt) AS lastPlayedAt
ORDER BY l.plays DESC, l.lastPlayedAt DESC;
