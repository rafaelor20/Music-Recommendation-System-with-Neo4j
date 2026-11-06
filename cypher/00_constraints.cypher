// =============================================================================
// 00_constraints.cypher
// Uniqueness constraints for node identifiers in the Music Recommendation Graph
// =============================================================================
// Safe to run multiple times (idempotent via IF NOT EXISTS).

CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User)
REQUIRE u.id IS UNIQUE;

CREATE CONSTRAINT artist_id_unique IF NOT EXISTS
FOR (a:Artist)
REQUIRE a.id IS UNIQUE;

CREATE CONSTRAINT genre_id_unique IF NOT EXISTS
FOR (g:Genre)
REQUIRE g.id IS UNIQUE;

CREATE CONSTRAINT track_id_unique IF NOT EXISTS
FOR (t:Track)
REQUIRE t.id IS UNIQUE;
