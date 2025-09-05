-- INTRO TO SPATIAL SQL
--**********************************

-- Basic SELECT statements - in your own namespace!
-- If you execute this, and you do not have the table 'states', it should fail.

SELECT * FROM "states";

-- in case you already have the table, you can drop it, to enable the experiments below to run
DROP TABLE "states" CASCADE;

-- create the missing table - just an ordinary table
-- try to understand all the parameters
CREATE TABLE "states" (
	"id" integer NOT NULL,
	"name" text,
	"abbreviatiON" character(2),
	CONstraint "state_pkey" Primary Key ("id") -- this wil be the primary key
);

-- fill some data into states - note, not all of the US, we only need a few
-- note, you need to fill the VALUES in in the order they are specified in the brackets after the table name 
INSERT INTO "states" (id, name, abbreviatiON) VALUES (1,'New York','NY');
INSERT INTO "states" (id, name, abbreviatiON) VALUES (2,'California','CA');
INSERT INTO "states" (id, name, abbreviatiON) VALUES (3,'Ohio','OH');
INSERT INTO "states" (id, name, abbreviatiON) VALUES (32,'New Jersey','NJ');

-- check constraints - we have specified some above!
SELECT * FROM information_schema.table_constraints WHERE table_name='states';

--**********************************
-- Let's make this table SPATIAL!
-- we will be creating a point column representing the states (maybe at a very coarse granularity
-- substitute your schema name in the query below
-- this adds a geometry column called 'geom' and registers it in the system)
-- the SRID is 4326, and will contain 2D points
SELECT addGeometryColumn('yourschemaname','states','geom',4326,'POINT',2);
COMMIT;

-- inspect the geometry_columns table that this column above has registered
SELECT * FROM public.geometry_columns gc WHERE gc.f_table_name='states';

-- there is an alternative, we could have registered this as a geography column. 
-- If you run the statement below, you should not see the column we have registered.
SELECT * FROM public.geography_columns gc;

--**********************************
-- LOADING DATA
-- OK, let's populate some data
-- we want to populate data based on a non-spatial join
-- first inspect what you have
-- inspect the geometries and see how the columns are serialized into WKT, 
-- without the 'ST_GeomAsText' we would have an ugly binary object
SELECT ST_ASText(t2.geom), t2.state FROM states AS t1
JOIN spatial.us_states AS t2 ON t1.name = t2.state;

-- then update values
-- fill in some data based on a thematic join
-- note the similarity with the above SELECT statement
-- also note the use of the ST_PointOnSurface method - check documentation for what it does.
UPDATE states AS t1  
SET t1.geom = ST_PointONSurface(t2.geom) 
FROM spatial.us_states AS t2 
WHERE t1.name = t2.state;

-- ASIDE; 
-- Explore ST_GeomAsText variants, and how it outputs information for other kinds of geometries
SELECT name,ST_ASText(geom) FROM spatial.us_rivers;
SELECT state, ST_ASEWKT(geom) FROM spatial.us_states;

--**********************************
-- Working with Spatial Reference Systems (SRIDs)
-- We can create a table with a spatial column directly
-- in this case, we will create one with a geography column
-- note that if we create an explicit geography, it gets registered elsewhere
DROP TABLE testgeog;
CREATE TABLE testgeog(gid serial PRIMARY KEY, geom geography(POINT,4326) );

DROP TABLE testgeom;
CREATE TABLE testgeom(gid serial PRIMARY KEY, geom geometry(POINT,4326) );
COMMIT;

-- this will not find them ( see, that we have swapped the geographies here)
-- modify these statements to see the correct outputs.
SELECT * FROM public.geometry_columns gc WHERE gc.f_table_name='testgeog';
SELECT * FROM public.geography_columns gc WHERE gc.f_table_name='testgeog';
	
--- inspecting the SRID
-- let's see what the srid means
SELECT * FROM spatial_ref_sys LIMIT 20; -- big table, so we limit to a subset

-- you can also find only some of the relevant attributes.
SELECT srid,srtext FROM spatial_ref_sys WHERE srid = 4326;

--**********************************
-- Measuring DISTANCES

-- let's find the distance to a given constant place
-- demonstrating working with geography vs geometry

-- first, the basic command `ST_Distance(geom1,geom2, optional spheroid::boolean)`
SELECT ST_Distance(ST_PointONSurface(geom), ST_GeomFromText('POINT(144 -37)', 4326)) AS dist FROM spatial.us_states;

--looks like weird outcome. What does this mean?

-- explore:

-- geography_cast_dist: casting centroids to geography, MEL in 4326 - automatically picks spheroid [OK]
-- sphere_dist: explicit sphere computation via spheroid=false flag [approximate]
-- pythagoras_dist: takes geometry points and computes on Euclidean plane [wrong!]
-- geog2times_spheroid_dist: inputs cast to geography [OK]
-- spheroid_dist_geom: explicit spheroid specification [OK]

SELECT state,
ST_Distance(ST_PointOnSurface(geom)::geography, ST_GeomFromText('POINT(144 -37)', 4326)) AS geography_cast_dist, 
ST_Distance(ST_PointOnSurface(geom), ST_GeomFromText('POINT(144 -37)', 4326), false) AS sphere_dist, 
ST_Distance(ST_PointOnSurface(geom), ST_GeomFromText('POINT(144 -37)', 4326)) As pythagoras_dist, 
ST_Distance(ST_PointOnSurface(geom)::geography, ST_GeomFromText('POINT(144 -37)')::geography) AS geog2times_spheroid_dist, 
ST_Distance(ST_PointOnSurface(geom), ST_GeomFromText('POINT(144 -37)', 4326), true) AS spheroid_dist_geom FROM spatial.us_states;


-- see what happens to Areas
-- We can compute the area using the spheroidical method (using the 'true' flag)
-- or by projecting first into a planar system
-- the spheroidical method is computationally expensive, but sometimes 
-- e.g. if computing an area across a large part of the world -- the only option.
SELECT state,
ST_Area(geom,true) AS spheroid_area,
ST_Area(ST_Transform(geom,2850)) AS proj_area
FROM spatial.us_states;

-- let's inspect how the geometries change if we transform them
-- EPSG 2850 is NAD83, Utah Central, applicable to an extent to the entire US
-- experiment with ST_ASEWKT for altered output
SELECT state,ST_ASText(geom), ST_ASText(ST_Transform(geom,2850)) FROM spatial.us_states;

--**********************************
-- Filling in spatial data form QGIS

-- another option to create a spatial table is during the create statement directly:
-- let's create a table for points
DROP TABLE mypoints;
CREATE TABLE mypoints (
gid serial NOT NULL, -- this will be an auto incremented ID
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


-- now, import data using QGIS
-- we can remove any existing content to just see that we can do this FROM scratch
-- in that case, DROP the mypoints table, and re-create it first.
-- HInts on QGIS editing are demonstrated in practicals or in class.

-- check that the data have been stored
SELECT * FROM mypoints;


-- Using command line tools
-- a great option is using a command line tool (you need to install GDAL on your machine, GDAL.org)
-- here, importing from a shapefile
-- ogr2ogr -f PostgreSQL  PG:"host=hostIP user=username dbname=yourdbname pASsword=yourpASsword active_schema=yourschema" myshp.shp
