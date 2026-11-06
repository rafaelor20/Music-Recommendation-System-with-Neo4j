// =============================================================================
// 03_business_queries.cypher
// Analytical & business intelligence queries over the music knowledge graph
// =============================================================================
// Before running user-specific queries in Neo4j Browser, configure parameters:
//   :param userId => 'u1'
//   :param otherUserId => 'u2'
// =============================================================================

// -----------------------------------------------------------------------------
// 1. Which artists are the most popular overall?
// Combines artist followers, total track likes, and total track plays into a
// weighted popularity index.
// -----------------------------------------------------------------------------
MATCH (a:Artist)
OPTIONAL MATCH (f:User)-[:FOLLOWS]->(a)
WITH a, count(DISTINCT f) AS followers
OPTIONAL MATCH (t:Track)-[:PERFORMED_BY]->(a)
OPTIONAL MATCH (lu:User)-[:LIKED]->(t)
WITH a, followers, count(DISTINCT t) AS catalogSize, count(DISTINCT lu) AS uniqueLikers
OPTIONAL MATCH (t2:Track)-[:PERFORMED_BY]->(a)
OPTIONAL MATCH (:User)-[l:LISTENED_TO]->(t2)
WITH a, followers, catalogSize, uniqueLikers, coalesce(sum(l.plays), 0) AS totalPlays
RETURN a.id AS artistId,
       a.name AS artistName,
       followers,
       uniqueLikers,
       totalPlays,
       (followers * 5 + uniqueLikers * 3 + totalPlays) AS popularityScore
ORDER BY popularityScore DESC, followers DESC
LIMIT 15;

// -----------------------------------------------------------------------------
// 2. Which genres are the most popular?
// Evaluates genre reach across unique listeners, likes, and total play volume.
// -----------------------------------------------------------------------------
MATCH (g:Genre)<-[:IN_GENRE]-(t:Track)
WITH g, count(DISTINCT t) AS tracksInGenre
OPTIONAL MATCH (g)<-[:IN_GENRE]-(t1:Track)<-[l:LISTENED_TO]-(uListen:User)
WITH g, tracksInGenre,
     count(DISTINCT uListen) AS uniqueListeners,
     coalesce(sum(l.plays), 0) AS totalPlays
OPTIONAL MATCH (g)<-[:IN_GENRE]-(t2:Track)<-[:LIKED]-(uLike:User)
WITH g, tracksInGenre, uniqueListeners, totalPlays,
     count(DISTINCT uLike) AS uniqueLikers
RETURN g.id AS genreId,
       g.name AS genreName,
       tracksInGenre,
       uniqueListeners,
       uniqueLikers,
       totalPlays,
       (uniqueListeners * 4 + uniqueLikers * 3 + totalPlays) AS engagementScore
ORDER BY engagementScore DESC, totalPlays DESC;

// -----------------------------------------------------------------------------
// 3. Which users have similar musical tastes to a target user ($userId)?
// Computes shared liked tracks and Jaccard similarity between $userId and peers.
// -----------------------------------------------------------------------------
MATCH (u1:User {id: $userId})-[:LIKED]->(t:Track)<-[:LIKED]-(u2:User)
WHERE u1 <> u2
WITH u1, u2, collect(DISTINCT t.title) AS sharedLikedTracks, count(DISTINCT t) AS sharedLikes
MATCH (u1)-[:LIKED]->(t1:Track)
WITH u1, u2, sharedLikedTracks, sharedLikes, count(DISTINCT t1) AS u1TotalLikes
MATCH (u2)-[:LIKED]->(t2:Track)
WITH u1, u2, sharedLikedTracks, sharedLikes, u1TotalLikes, count(DISTINCT t2) AS u2TotalLikes
WITH u1, u2, sharedLikes, sharedLikedTracks,
     round(toFloat(sharedLikes) / (u1TotalLikes + u2TotalLikes - sharedLikes), 3) AS jaccardSimilarity
RETURN u1.name AS targetUser,
       u2.id AS similarUserId,
       u2.name AS similarUserName,
       sharedLikes,
       jaccardSimilarity,
       sharedLikedTracks[0..5] AS sampleSharedTracks
ORDER BY sharedLikes DESC, jaccardSimilarity DESC
LIMIT 10;

// -----------------------------------------------------------------------------
// 4. Which tracks are shared between two specific users ($userId and $otherUserId)?
// Finds tracks that both users have interacted with (either LIKED or LISTENED_TO).
// -----------------------------------------------------------------------------
MATCH (u1:User {id: $userId})-[r1:LIKED|LISTENED_TO]->(t:Track)<-[r2:LIKED|LISTENED_TO]-(u2:User {id: $otherUserId})
MATCH (t)-[:PERFORMED_BY]->(a:Artist)
WITH u1, u2, t, a,
     collect(DISTINCT type(r1)) AS user1Interactions,
     collect(DISTINCT type(r2)) AS user2Interactions
RETURN t.id AS trackId,
       t.title AS trackTitle,
       a.name AS artistName,
       user1Interactions,
       user2Interactions
ORDER BY t.id ASC;

// -----------------------------------------------------------------------------
// 5. Which artists are most followed by users with similar preferences to $userId?
// Identifies users who share liked tracks with $userId and ranks the artists they follow.
// -----------------------------------------------------------------------------
MATCH (u:User {id: $userId})-[:LIKED]->(sharedTrack:Track)<-[:LIKED]-(peer:User)
WHERE u <> peer
WITH u, peer, count(DISTINCT sharedTrack) AS sharedLikes
WHERE sharedLikes >= 2
MATCH (peer)-[:FOLLOWS]->(a:Artist)
WITH u, a,
     count(DISTINCT peer) AS similarFollowersCount,
     sum(sharedLikes) AS weightedAffinity,
     EXISTS((u)-[:FOLLOWS]->(a)) AS alreadyFollowedByTargetUser
RETURN a.id AS artistId,
       a.name AS artistName,
       similarFollowersCount,
       weightedAffinity,
       alreadyFollowedByTargetUser
ORDER BY similarFollowersCount DESC, weightedAffinity DESC, artistName ASC
LIMIT 10;

// -----------------------------------------------------------------------------
// 6. Which tracks have many plays, but very few likes?
// Highlights passive/background hits (high play volume, low like conversion).
// -----------------------------------------------------------------------------
MATCH (u:User)-[l:LISTENED_TO]->(t:Track)-[:PERFORMED_BY]->(a:Artist)
WITH t, a,
     sum(l.plays) AS totalPlays,
     count(DISTINCT u) AS uniqueListeners
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
ORDER BY totalPlays DESC, totalLikes ASC
LIMIT 10;
