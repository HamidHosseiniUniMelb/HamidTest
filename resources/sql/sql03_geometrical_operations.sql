-- GEOMETRICAL OPERATIONS
--**********************************

-- GEOMETRIES

-- POLYGONS
-- how many geometries are there in a polygon with hole?
-- CREATING A TEMPORARY VIEW INSTEAD OF TABLE FOR THIS, FOR A CHANGE.
DROP VIEW mypoly;
CREATE or REPLACE VIEW mypoly as 
SELECT 1::integer as id,ST_GeomFromText('POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10),(20 30, 35 35, 30 20, 20 30))',-1) as GEOM;  

-- Check the number of geometries
SELECT ST_NumGeometries(ST_GeomFromText('POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10),(20 30, 35 35, 30 20, 20 30))')) as mypoly;

-- getting parts of geometries
-- get the exterior ring
SELECT ST_asText(ST_ExteriorRing(ST_GeomFromText('POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10),(20 30, 35 35, 30 20, 20 30))'))) as exterior;
--testing multipolygon

SELECT ST_NumGeometries(ST_GeomFromText('MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)),((15 5, 40 10, 10 20, 5 10, 15 5)))')) as mymultipoly;

--lines
SELECT ST_NumPoints(ST_GeomFromEWKT('LINESTRING(0 0 0,5 0 3,5 10 5)'));
SELECT ST_asTEXT(ST_PointN(ST_GeomFromEWKT('LINESTRING(0 0 0,5 0 3,5 10 5)'),1));
SELECT ST_asTEXT(ST_StartPoint(ST_GeomFromEWKT('LINESTRING(0 0 0,5 0 3,5 10 5)')));

-- GEOMETRY VALIDATION
-- exploring geometry validation
SELECT ST_IsSimple(ST_GeomFromText('LINESTRING(1 1,2 2,2 3.5,1 3,1 2,2 1)'));

SELECT ST_IsValid(ST_GeomFromText('LINESTRING(0 0, 1 1)')) As good_line,
	ST_IsValid(ST_GeomFromText('POLYGON((0 0, 1 1, 1 2, 1 1, 0 0))')) As bad_poly;

SELECT ST_IsValid(ST_GeomFromText('LINESTRING(0 0, 1 1)')) As good_line,
	ST_IsValidReason(ST_GeomFromText('POLYGON((0 0, 1 1, 1 2, 1 1, 0 0))')) As bad_poly;

-- Spatial Operations
-- Thematic
SELECT s.state,ST_asTEXT(s.geom) as shape FROM spatial.us_states as s WHERE s.state = 'New York';
-- Topologic
SELECT s.state, r.name FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE ST_WITHIN(r.geom,s.geom);
-- topologic used for a spatial join - join syntax 
-- play with topological relationships ST_Within, ST_Contains
--EXPLAIN ANALYZE 
 SELECT uss.state, usc.city
  FROM spatial.us_states uss 
  JOIN spatial.us_cities usc
  ON ST_Within(usc.location,uss.geom);

-- Geometric
-- geometry
--area
SELECT s.state, ST_Area(s.geom::geography) as area FROM spatial.us_states as s;

--length
SELECT ST_Length(ST_GeomFromEWKT('LINESTRING(0 0 0,5 0 3,5 10 5)'));

-- combined thematic and geometric
SELECT s.state, ST_Area(s.geom,true) as area, ST_Area(s.geom::geography),ST_asTEXT(geom), ST_asText(ST_Transform(geom,2850)) projected FROM spatial.us_states as s WHERE s.state = 'New York';


-- QGIS interaction
--another option to create a spatial table is during the create statement directly:
--let's create a table for points
DROP TABLE mypoints;
CREATE TABLE mypoints (
gid serial NOT NULL,
geom geometry(point, 4326),
label_sample varchar(255),
CONSTRAINT mypoint_pkey PRIMARY KEY (gid)
);


-- try to insert data into the mypoints table:
INSERT INTO mypoints (gid,geom,label_sample)
  VALUES (DEFAULT,ST_GeomFromText('POINT(144.9631 -37.8136)', 4326), 'A Place');

-- serial values can be ommitted - in both parts of the insert statement
INSERT INTO mypoints (geom,label_sample)
  VALUES (ST_GeomFromText('POINT(144.9631 -37.8136)', 4326), 'A Place');


-- import data using QGIS -- not shown
--ogr2ogr -f PostgreSQL  PG:"host=hostIP user=username dbname=yourdbname password=yourpassword active_schema=yourschema" myshp.shp


-- DEMONSTRATE QGIS EDITING HERE - create polygons and points in soils and mypoints
-- check that the data have been stored
select * from mypoints;

-- convex hull
-- put into view to show in QGIS
-- to do this, you need to specify that ID is your primary key in the QGIS menu ( in the new QGIS).
DROP VIEW tomkom.us_cities_hull;
create or replace view tomkom.us_cities_hull as 
select 1::integer as id, st_convexhull(st_collect(usc.location)) as geom from spatial.us_cities as usc;
select * from tomkom.us_cities_hull;


-- line simplification
-- create table, draw some line in QGIS, and simplify
DROP TABLE myline;
CREATE TABLE myline (
gid serial UNIQUE NOT NULL,
label varchar(255),
geom geometry(linestring,4326),
CONSTRAINT myline_pkey PRIMARY KEY (gid)
);
COMMIT;
-- optional, index
CREATE INDEX myline_gix ON myline USING GIST (geom);


-- simplification of geometry - play with the tolerance.
SELECT ST_NPoints(ST_SIMPLIFY(ST_GeomFromText('LINESTRING(-71.160281 42.258729,-71.160837 42.259113,-71.161144 42.25932)'),0.0001)); 

create or replace view simpleline as select '1'::integer as “id”,ST_SIMPLIFY(geom,0.2) from myline; 


-- Set-oriented queries
-- recall topological relationship above on states and rivers
SELECT s.state, r.name FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE ST_WITHIN(r.geom,s.geom);

-- we now want the parts of the rivers that are within a given state(geometrical and topological combination)
SELECT s.state as state,r.name as river, ST_asTEXT(ST_Intersection(r.geom,s.geom)) as intersection FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE ST_intersects(r.geom,s.geom) ORDER BY s.state;
-- without the tpological query at the end - just so you see taht I can filter by thematic query too
SELECT s.state as state,r.name as river, ST_asTEXT(ST_Intersection(r.geom,s.geom)) as intersection FROM SPATIAL.US_STATES AS s, SPATIAL.US_RIVERS as r WHERE s.state = 'California' ORDER BY r.name;

