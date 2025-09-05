-- playing with persistent topology
-- creating a topology layer
-- setting up postgis
-- repalce <username> below with your schema name
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
SET search_path = topology,public;

-- make sure we are tidy
SELECT topology.DropTopology('us_states_topo');
DROP TABLE username.us_states; --replace username with your schema name - we want to create this in your own schema

--Will make a copy of spatial.us_states in my own schema
CREATE TABLE username.us_states AS SELECT * FROM spatial.us_states;
ALTER TABLE username.us_states ADD CONSTRAINT username_usstates_id_pkey PRIMARY KEY (id);


-- registers a topology
SELECT topology.CreateTopology('us_states_topo', 4326);
-- check it exists
SELECT * 
FROM information_schema.tables 
WHERE table_schema = 'us_states_topo';

-- adds a topo column to this topology, for a given table (us_states), and adds the column topo_geom to it
SELECT topology.AddTopoGeometryColumn('us_states_topo', 'username','us_states', 'topo_geom', 'MULTIPOLYGON');
SELECT * FROM username.us_states;
-- populates the topology
UPDATE username.us_states SET topo_geom = topology.toTopoGeom(geom, 'us_states_topo',1);
SELECT * FROM username.us_states;
SELECT * FROM topology.TopologySummary('us_states_topo');