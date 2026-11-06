// =============================================================================
// 05_browser_showcase_queries.cypher
// Ready-to-paste showcase queries for Neo4j Browser (http://localhost:7474)
// =============================================================================
// All queries in this file are self-contained (no prior `:param` setup required)
// so you can copy and paste any block directly into Neo4j Browser to visualize
// graphs (Graph tab) or inspect rankings (Table tab).
// =============================================================================

// -----------------------------------------------------------------------------
// Query 1 — Visualize the Complete Graph Schema (Visual Graph Mode)
// Displays how the 4 node labels (User, Track, Artist, Genre) and 5 relationship
// types connect in the database.
// -----------------------------------------------------------------------------
CALL db.schema.visualization();

// -----------------------------------------------------------------------------
// Query 2 — Explore the Musical Subgraph of Alice Martins ('u1') (Visual Mode)
// Plots Alice Martins, the artists she follows, the tracks she liked/listened to,
// and the genres/artists linked to those tracks.
// -----------------------------------------------------------------------------
MATCH path = (u:User {id: 'u1'})-[:LIKED|LISTENED_TO|FOLLOWS]->(target)
OPTIONAL MATCH genrePath = (target)-[:IN_GENRE|PERFORMED_BY]->(related)
RETURN path, genrePath
LIMIT 50;

// -----------------------------------------------------------------------------
// Query 3 — Visualize Peer Users with Similar Musical Taste to Alice ('u1')
// Shows shared liked tracks acting as bridges between Alice Martins ('u1') and
// similar peers (Bruno Costa, Carla Dias, Diego Rocha, Elena Silva).
// -----------------------------------------------------------------------------
MATCH path = (u:User {id: 'u1'})-[:LIKED]->(shared:Track)<-[:LIKED]-(peer:User)
WHERE u <> peer
RETURN path;

// -----------------------------------------------------------------------------
// Query 4 — Visualize Collaborative Filtering Recommendation Paths (Visual Mode)
// Traces the multi-hop recommendation path:
// Alice ('u1') -> Shared Track -> Similar Peer -> Recommended Unseen Track -> Artist
// -----------------------------------------------------------------------------
MATCH (u:User {id: 'u1'})-[:LIKED]->(shared:Track)<-[:LIKED]-(peer:User)
WHERE u <> peer
MATCH recPath = (u)-[:LIKED]->(shared)<-[:LIKED]-(peer)-[:LIKED]->(rec:Track)-[:PERFORMED_BY]->(a:Artist)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
RETURN recPath
LIMIT 25;

// -----------------------------------------------------------------------------
// Query 5 — Top 10 Collaborative Filtering Recommendations for 'u1' (Table Mode)
// Ranks unseen tracks for Alice Martins ('u1') by how many similar users liked
// each track and their shared-like similarity score.
// -----------------------------------------------------------------------------
MATCH (u:User {id: 'u1'})-[:LIKED]->(shared:Track)<-[:LIKED]-(peer:User)
WHERE u <> peer
WITH u, peer, count(DISTINCT shared) AS sharedLikes
MATCH (peer)-[:LIKED]->(rec:Track)-[:PERFORMED_BY]->(a:Artist)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
WITH rec, a,
     count(DISTINCT peer) AS similarUsersCount,
     sum(sharedLikes) AS collaborativeScore,
     collect(DISTINCT peer.name)[0..5] AS recommendedByPeers
RETURN rec.id AS trackId,
       rec.title AS trackTitle,
       a.name AS artistName,
       [(rec)-[:IN_GENRE]->(g:Genre) | g.name] AS genres,
       similarUsersCount,
       collaborativeScore,
       recommendedByPeers
ORDER BY similarUsersCount DESC, collaborativeScore DESC, rec.title ASC
LIMIT 10;

// -----------------------------------------------------------------------------
// Query 6 — Top 10 Followed-Artist Recommendations for 'u1' (Strategy B - Table)
// Recommends unseen tracks by artists Alice ('u1') follows, prioritizing artists
// with higher historical engagement from Alice.
// -----------------------------------------------------------------------------
MATCH (u:User {id: 'u1'})-[:FOLLOWS]->(a:Artist)<-[:PERFORMED_BY]-(rec:Track)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
OPTIONAL MATCH (u)-[priorLike:LIKED]->(:Track)-[:PERFORMED_BY]->(a)
WITH u, a, rec, count(DISTINCT priorLike) * 3 AS likeAffinity
OPTIONAL MATCH (u)-[priorListen:LISTENED_TO]->(:Track)-[:PERFORMED_BY]->(a)
WITH u, a, rec, likeAffinity, coalesce(sum(priorListen.plays), 0) AS listenAffinity
WITH u, a, rec, (likeAffinity + listenAffinity) AS artistAffinityScore
OPTIONAL MATCH (otherUser:User)-[:LIKED]->(rec)
WITH a, rec, artistAffinityScore, count(DISTINCT otherUser) AS communityLikes
OPTIONAL MATCH (:User)-[l:LISTENED_TO]->(rec)
WITH rec, a, artistAffinityScore, communityLikes, coalesce(sum(l.plays), 0) AS communityPlays
RETURN rec.id AS trackId,
       rec.title AS trackTitle,
       a.name AS followedArtist,
       [(rec)-[:IN_GENRE]->(g:Genre) | g.name] AS genres,
       artistAffinityScore,
       communityLikes,
       communityPlays,
       (artistAffinityScore * 2 + communityLikes * 3 + communityPlays) AS relevanceScore
ORDER BY artistAffinityScore DESC, relevanceScore DESC, rec.title ASC
LIMIT 10;

// -----------------------------------------------------------------------------
// Query 7 — "Background Hits": High Plays, Very Few Likes (Business Insight)
// Detects passive/background tracks that accumulate many plays across listeners
// but rarely receive explicit likes.
// -----------------------------------------------------------------------------
MATCH (u:User)-[l:LISTENED_TO]->(t:Track)-[:PERFORMED_BY]->(a:Artist)
WITH t, a, sum(l.plays) AS totalPlays, count(DISTINCT u) AS uniqueListeners
WHERE totalPlays >= 40
OPTIONAL MATCH (liker:User)-[:LIKED]->(t)
WITH t, a, totalPlays, uniqueListeners, count(DISTINCT liker) AS totalLikes
WHERE totalLikes <= 2
RETURN t.id AS trackId,
       t.title AS trackTitle,
       a.name AS artistName,
       totalPlays,
       uniqueListeners,
       totalLikes,
       round(toFloat(totalLikes) / totalPlays, 4) AS likeToPlayRatio
ORDER BY totalPlays DESC, totalLikes ASC;

// -----------------------------------------------------------------------------
// Query 8 — Top 10 Genre-Affinity Recommendations for 'u1' (Strategy C - Table)
// Scores Alice's preferred genres (5 pts per liked track + 1 pt per play) and
// recommends unseen tracks matching those genres.
// -----------------------------------------------------------------------------
MATCH (u:User {id: 'u1'})
CALL (u) {
    MATCH (u)-[:LIKED]->(t:Track)-[:IN_GENRE]->(g:Genre)
    RETURN g, count(DISTINCT t) * 5 AS score
    UNION ALL
    MATCH (u)-[l:LISTENED_TO]->(t:Track)-[:IN_GENRE]->(g:Genre)
    RETURN g, sum(l.plays) AS score
}
WITH u, g, sum(score) AS genreAffinity
WHERE genreAffinity > 0
MATCH (rec:Track)-[:IN_GENRE]->(g)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
MATCH (rec)-[:PERFORMED_BY]->(a:Artist)
WITH rec, a,
     collect(DISTINCT g.name) AS matchedGenres,
     sum(genreAffinity) AS totalGenreAffinity
OPTIONAL MATCH (liker:User)-[:LIKED]->(rec)
WITH rec, a, matchedGenres, totalGenreAffinity,
     count(DISTINCT liker) AS communityLikes
RETURN rec.id AS trackId,
       rec.title AS trackTitle,
       a.name AS artistName,
       matchedGenres,
       totalGenreAffinity,
       communityLikes,
       (totalGenreAffinity + communityLikes * 3) AS relevanceScore
ORDER BY relevanceScore DESC, totalGenreAffinity DESC, rec.title ASC
LIMIT 10;

// -----------------------------------------------------------------------------
// Query 9 — Visualize Genre-Based Recommendation Paths (Strategy C - Visual)
// Shows how genres of tracks liked by Alice ('u1') bridge to recommended tracks.
// -----------------------------------------------------------------------------
MATCH (u:User {id: 'u1'})-[:LIKED]->(liked:Track)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Track)-[:PERFORMED_BY]->(a:Artist)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
RETURN u, liked, g, rec, a
LIMIT 35;

// -----------------------------------------------------------------------------
// Query 10 — Shared Tracks Between Two Users ('u1' Alice and 'u2' Bruno)
// Visually plots all tracks connecting Alice Martins and Bruno Costa.
// -----------------------------------------------------------------------------
MATCH path = (u1:User {id: 'u1'})-[:LIKED|LISTENED_TO]->(t:Track)<-[:LIKED|LISTENED_TO]-(u2:User {id: 'u2'})
MATCH artistPath = (t)-[:PERFORMED_BY]->(a:Artist)
RETURN path, artistPath;

// -----------------------------------------------------------------------------
// Query 11 — Collaborative Filtering for a Synthwave & Deep House Fan ('u6')
// Demonstrates personalized recommendations for Felipe Mendes ('u6').
// -----------------------------------------------------------------------------
MATCH (u:User {id: 'u6'})-[:LIKED]->(shared:Track)<-[:LIKED]-(peer:User)
WHERE u <> peer
WITH u, peer, count(DISTINCT shared) AS sharedLikes
MATCH (peer)-[:LIKED]->(rec:Track)-[:PERFORMED_BY]->(a:Artist)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
WITH rec, a,
     count(DISTINCT peer) AS similarUsersCount,
     sum(sharedLikes) AS collaborativeScore,
     collect(DISTINCT peer.name)[0..5] AS recommendedByPeers
RETURN rec.id AS trackId,
       rec.title AS trackTitle,
       a.name AS artistName,
       [(rec)-[:IN_GENRE]->(g:Genre) | g.name] AS genres,
       similarUsersCount,
       collaborativeScore,
       recommendedByPeers
ORDER BY similarUsersCount DESC, collaborativeScore DESC, rec.title ASC
LIMIT 10;

// -----------------------------------------------------------------------------
// Query 12 — Collaborative Filtering for a Lo-Fi, Neo Soul & Jazz Fan ('u11')
// Demonstrates personalized recommendations for Karina Gomes ('u11').
// -----------------------------------------------------------------------------
MATCH (u:User {id: 'u11'})-[:LIKED]->(shared:Track)<-[:LIKED]-(peer:User)
WHERE u <> peer
WITH u, peer, count(DISTINCT shared) AS sharedLikes
MATCH (peer)-[:LIKED]->(rec:Track)-[:PERFORMED_BY]->(a:Artist)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
WITH rec, a,
     count(DISTINCT peer) AS similarUsersCount,
     sum(sharedLikes) AS collaborativeScore,
     collect(DISTINCT peer.name)[0..5] AS recommendedByPeers
RETURN rec.id AS trackId,
       rec.title AS trackTitle,
       a.name AS artistName,
       [(rec)-[:IN_GENRE]->(g:Genre) | g.name] AS genres,
       similarUsersCount,
       collaborativeScore,
       recommendedByPeers
ORDER BY similarUsersCount DESC, collaborativeScore DESC, rec.title ASC
LIMIT 10;
