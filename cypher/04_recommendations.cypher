// =============================================================================
// 04_recommendations.cypher
// Three Graph-Based Music Recommendation Strategies in Pure Cypher
// =============================================================================
// Before running in Neo4j Browser, configure the target user parameter:
//   :param userId => 'u1'
// =============================================================================

// -----------------------------------------------------------------------------
// STRATEGY A — Collaborative Filtering (User-to-User via Shared Likes)
// -----------------------------------------------------------------------------
// Logic:
//   1. Find peer users who liked at least one track in common with $userId.
//   2. Find other tracks liked by those peers.
//   3. Exclude tracks already liked OR listened to by $userId.
//   4. Group by candidate track and rank by the number of similar users who
//      liked it (with total shared-like similarity weight as tie-breaker).
//   5. Return the top 10 recommendations.
// -----------------------------------------------------------------------------
MATCH (u:User {id: $userId})-[:LIKED]->(shared:Track)<-[:LIKED]-(peer:User)
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
// STRATEGY B — Artist-Based Recommendation (Followed Artists Discovery)
// -----------------------------------------------------------------------------
// Logic:
//   1. Identify artists followed by $userId.
//   2. Find tracks performed by those followed artists.
//   3. Exclude tracks already known (liked or listened to) by $userId.
//   4. Prioritize followed artists with whom the user has stronger prior
//      affinity (liked/played tracks from that artist) and rank tracks by
//      community popularity (likes + plays).
//   5. Return the top 10 recommendations.
// -----------------------------------------------------------------------------
MATCH (u:User {id: $userId})-[:FOLLOWS]->(a:Artist)<-[:PERFORMED_BY]-(rec:Track)
WHERE NOT (u)-[:LIKED|LISTENED_TO]->(rec)
OPTIONAL MATCH (u)-[priorLike:LIKED]->(:Track)-[:PERFORMED_BY]->(a)
WITH u, a, rec, count(DISTINCT priorLike) * 3 AS likeAffinity
OPTIONAL MATCH (u)-[priorListen:LISTENED_TO]->(:Track)-[:PERFORMED_BY]->(a)
WITH u, a, rec, likeAffinity, coalesce(sum(priorListen.plays), 0) AS listenAffinity
WITH u, a, rec, (likeAffinity + listenAffinity) AS artistAffinityScore
OPTIONAL MATCH (otherUser:User)-[:LIKED]->(rec)
WITH a, rec, artistAffinityScore, count(DISTINCT otherUser) AS communityLikes
OPTIONAL MATCH (:User)-[l:LISTENED_TO]->(rec)
WITH rec, a, artistAffinityScore, communityLikes,
     coalesce(sum(l.plays), 0) AS communityPlays
RETURN rec.id AS trackId,
       rec.title AS trackTitle,
       a.id AS artistId,
       a.name AS followedArtist,
       [(rec)-[:IN_GENRE]->(g:Genre) | g.name] AS genres,
       artistAffinityScore,
       communityLikes,
       communityPlays,
       (artistAffinityScore * 2 + communityLikes * 3 + communityPlays) AS relevanceScore
ORDER BY artistAffinityScore DESC, relevanceScore DESC, rec.title ASC
LIMIT 10;

// -----------------------------------------------------------------------------
// STRATEGY C — Genre-Based Recommendation (Content Profile Affinity)
// -----------------------------------------------------------------------------
// Logic:
//   1. Calculate $userId's preference score per genre based on their history
//      of likes (weight = 5 per liked track) and listens (weight = plays count).
//   2. Find candidate tracks belonging to those preferred genres.
//   3. Exclude tracks already known (liked or listened to) by $userId.
//   4. Aggregate the genre affinity score across the candidate track's genres
//      and incorporate community popularity as a tie-breaker.
//   5. Return the top 10 recommendations.
// -----------------------------------------------------------------------------
MATCH (u:User {id: $userId})
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
WITH u, rec, a,
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
