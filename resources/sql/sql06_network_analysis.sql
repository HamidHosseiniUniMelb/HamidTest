-- Lecture 7: Networks
-- Check your pgrouting version
select * from pgr_version()
-- Creation of a PG_ROUTING dataset from a network input
-- reaplce <username> with your schema name

CREATE TABLE username.us_interstates as (SELECT * FROM spatial.us_interstates);

ALTER TABLE username.us_interstates ADD CONSTRAINT username_us_interstates_id_pkey PRIMARY KEY (id);

ALTER TABLE username.us_interstates ADD COLUMN "source" integer;
ALTER TABLE username.us_interstates ADD COLUMN "target" integer;

-- Run topology function
SELECT pgr_createTopology('username.us_interstates', 0.00001, 'the_geom', 'gid');

-- you can then use the tables


-- computing paths - replace originID and destinationID
SELECT * FROM pgr_dijkstra('SELECT id, source, target, length as cost FROM username.us_interstates', originID, destinationID, false);

