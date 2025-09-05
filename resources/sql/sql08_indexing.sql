
--- INDEXING
-- explore timing measurement with and without indexes


-- find if you have an index
select
    t.relname as table_name,
    i.relname as index_name,
    a.attname as column_name
from
    pg_class t,
    pg_class i,
    pg_index ix,
    pg_attribute a
where
    t.oid = ix.indrelid
    and i.oid = ix.indexrelid
    and a.attrelid = t.oid
    and a.attnum = ANY(ix.indkey)
    and t.relkind = 'r'
    and t.relname like 'us_states'
order by
    t.relname,
    i.relname;

-- DROP index if it already exists
DROP INDEX spatial."spatial.us_states_GEOM_idx";

EXPLAIN ANALYZE
SELECT state,ST_Distance(ST_PointOnSurface(geom), ST_GeomFromText('POINT(-74 40)', 4326),true) As spheroid_dist FROM spatial.us_states;

CREATE INDEX "spatial.us_states_GEOM_idx"
  ON spatial.us_states
  USING gist
  (geom);

EXPLAIN ANALYZE
SELECT state,ST_Distance(ST_PointOnSurface(geom), ST_GeomFromText('POINT(-74 40)', 4326),true) As spheroid_dist FROM spatial.us_states;

-- explore the visual explanation in pgadmin - point to index scan (single yellow column) as opposed to sequence scan (all yellow columns)
EXPLAIN ANALYZE
SELECT s.state, r.name FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE ST_WITHIN(r.geom,s.geom)

--we can compare results to pure bbox query &&

DROP INDEX spatial."spatial.us_states_GEOM_idx";
EXPLAIN ANALYZE
SELECT s.state, r.name FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE ST_WITHIN(r.geom,s.geom)

-- recreate the index, to not forget...
CREATE INDEX "spatial.us_states_GEOM_idx"
  ON spatial.us_states
  USING gist
  (geom);
  
--INDEX maintenance:
-- VACUUM recovers space lost during updates/inserts/deletes
VACUUM spatial.us_states
ANALYZE spatial.us_states
--reorders the data physically on disc following an index
CLUSTER spatial.us_states USING spatial.us_states_GEOM_idx;
-- recommended to re-analyze after clustering
ANALYZE spatial.us_states;


-- another similar example, here using ST_Touches

EXPLAIN ANALYZE
SELECT t1.county,t2.county FROM spatial.us_counties as t1, spatial.us_counties as t2 WHERE ST_TOUCHES(t1.geom,t2.geom) ;

DROP INDEX spatial."spatial.us_counties_GEOM_idx";

EXPLAIN ANALYZE
SELECT t1.county,t2.county FROM spatial.us_counties as t1, spatial.us_counties as t2 WHERE ST_TOUCHES(t1.geom,t2.geom) ;

CREATE INDEX "spatial.us_counties_GEOM_idx"
  ON spatial.us_counties
  USING gist
  (geom);

CLUSTER spatial.us_counties USING "spatial.us_counties_GEOM_idx";
VACUUM ANALYZE spatial.us_counties;
