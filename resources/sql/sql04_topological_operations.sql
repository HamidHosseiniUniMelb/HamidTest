-- Topological queries (incl with mask)

--recall:
-- Topological query
-- find cities in states - WHERE syntax
SELECT s.state, r.name FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r 
WHERE ST_WITHIN(r.geom,s.geom);

-- topology used for a spatial join - join syntax 
-- play with topological relationships ST_Within, ST_Contains
--EXPLAIN ANALYZE 
-- find cities in states - using join syntax
 SELECT uss.state, usc.city
  FROM spatial.us_states uss 
  JOIN spatial.us_cities usc
  ON ST_Within(usc.location,uss.geom);

 SELECT uss.state, usc.city
  FROM spatial.us_states uss 
  JOIN spatial.us_cities usc
  ON ST_Contains(usc.location,uss.geom); 

-- intersection geometry
SELECT ST_AsText(ST_Intersection('POINT(0 0)'::geometry, 'LINESTRING ( 0 0, 0 2 )'::geometry));

-- let's try to find rivers that form boundaries: we will ask for rivers that 
-- overlap forming a one dimensional geometry (1- line string) on the boundary
-- this will yield nothing - think why?
SELECT r.name,
	s.state,
	ST_AsText(ST_Intersection(s.geom,r.geom)), 
	ST_Length(ST_Intersection(s.geom,r.geom)) 
FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r 
WHERE ST_RELATE(s.geom,r.geom,'F***1****');

-- find the intersection of the state with rivers
SELECT r.name as river,s.state state,ST_Relate(s.geom,r.geom) as relation, ST_Length(ST_Intersection(s.geom,r.geom)) as length FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE r.name = 'Potomac' ORDER BY length DESC;

-- we see that even if these rivers are boundary rivers, they have intersections with the rivers that cross, they do not overlap along a 1D segment. 
-- Can we test that the rivers are boundaries at some stage?
-- this would mean that the intersection of intersections of the river with the states can yield a 2D geometry
-- note the restriction to remove self identical results (<>) and remove symmetric results (>) trick
SELECT s1.state, s2.state,ST_asText(ST_Intersection(s1.geom,s2.geom)) as intersecgeom,ST_Relate(s1.geom,s2.geom) as relationship FROM 
	(SELECT r.name as river,s.state as state,ST_Intersection(s.geom,r.geom) as geom FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE r.name = 'Potomac') as s1
	JOIN (SELECT r.name as river,s.state as state, ST_Intersection(s.geom,r.geom) as geom FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE r.name = 'Potomac') as s2
	ON ST_Intersects(s1.geom,s2.geom) WHERE s1.state < s2.state;

--experiment with other spatial predicates - distance of 500 units
-- note that we transform the geoms for distance computation in DWITHIN
SELECT s.state as state, 
	r.name as river, 
	ST_Distance(ST_Transform(r.geom,2850),
	ST_Transform(s.geom,2850)) as distance 
FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r 
	WHERE ST_DWITHIN(ST_Transform(r.geom,2850),ST_Transform(s.geom,2850),500)
	ORDER BY distance DESC;
	
--- Topological relationship assurance
-- with QGIS demo
-- we remove any existing content to just see that we can do this from scratch
--let's create a table for points
DROP TABLE mypoints;
CREATE TABLE mypoints (
gid serial UNIQUE NOT NULL,
geom geometry(point, 4326),
label_sample varchar(255),
CONSTRAINT mypoint_pkey PRIMARY KEY (gid)
);
CREATE INDEX mypoints_gix ON mypoints USING GIST (geom);



--and another for some soil polygons
DROP TABLE soil;
CREATE TABLE soil (
gid serial NOT NULL,
geom geometry(polygon, 4326),
mylabel varchar(255),
CONSTRAINT soil_pkey PRIMARY KEY (gid)
);
CREATE INDEX soil_gix ON soil USING GIST (geom);

-- we will try to fill these using QGIS, for simplicity
-- DEMONSTRATE QGIS EDITING HERE - create polygons and points in soils and mypoints

-- check that the data have been stored
select * from soil;
select * from mypoints;

--- SPATIAL TRIGGER
-- now, let's make sure that any new point we add is within a polygon (topological constraint)
-- in postgis, we have the trigger function (below) and the trigger where this function is applied (further below)
-- trigger function
CREATE OR REPLACE FUNCTION check_pointWithinPolygon()
RETURNS trigger AS $body$
    BEGIN
    IF TG_OP = 'INSERT'  THEN
	if ((SELECT count(*) FROM (SELECT s.gid FROM soil AS s WHERE st_Within(NEW.geom, s.geom)) as foo) > 0) THEN
		RETURN NEW; 
	ELSE
		RAISE DEBUG 'inserted feature GID:% , LABEL: % is not within a soil patch', NEW.gid, NEW.label_sample;
	END IF;
end if;
END;
$body$ LANGUAGE plpgsql;

COMMIT;


-- use the trigger function in a trigger
-- takes the mention of the table on which it is used
DROP TRIGGER myPointInSoil ON mypoints;
CREATE TRIGGER myPointInSoil BEFORE INSERT OR UPDATE
ON mypoints FOR EACH ROW
EXECUTE PROCEDURE check_pointWithinPolygon();

COMMIT;



