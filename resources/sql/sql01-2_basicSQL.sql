-- Basic SELECT statements
SELECT * from "publishers";

-- below, replace <username> with your schema (user) name

DROP TABLE "username"."publishers";
-- basic creation of table
-- we usually prefix this tatement with the DROP TABLE statemnet before, to make sure it does not exist
CREATE TABLE "username"."publishers" (
	"id" integer NOT NULL CONSTRAINT publishers_id_positive  CHECK (id>0),
	"name" text,
	"address" text
);

select *
	from INFORMATION_SCHEMA.table_constraints
	where table_name = 'publishers';


-- describe the table
select column_name, data_type, character_maximum_length
	from INFORMATION_SCHEMA.COLUMNS 
	where table_name = 'publishers';


--insert twice thew same entry
-- works because no constraint (e.g., PK) was specified on column ID
INSERT INTO publishers (id, name, address) VALUES (150,'Kids Can Press','Kids Can Press, 29 Birch Ave. Toronto');
INSERT INTO publishers (id, name, address) VALUES (150,'Kids Can Press','Kids Can Press, 29 Birch Ave. Toronto');

-- check content
select * from publishers;




-- try with constraint
DROP TABLE "publishers";
-- recreate the table with a PK constraint
CREATE TABLE "tomkom"."publishers" (
	"id" integer,
	"name" text,
	"address" text,
	Constraint "publishers_pkey" Primary Key ("id")
);

-- check contents
select * from publishers;

--insert twice thew same entry, fails
INSERT INTO publishers (id, name, address) VALUES (150,'Kids Can Press','Kids Can Press, 29 Birch Ave. Toronto');

ALTER TABLE "publishers" 
	Drop CONSTRAINT "publishers_pkey";


INSERT INTO publishers (id, name, address) VALUES (150,'Kids Can Press','Kids Can Press, 29 Birch Ave. Toronto');

-- instead of dropping tables, we can redefine them
-- alter table
-- add column

ALTER TABLE "publishers" 
	ADD COLUMN "state_id" integer;

-- insert some data including a state_id value
INSERT INTO publishers (id, name, address,state_id) VALUES (160,'Melbourne University Press','Melbourne University Press, The University of Melbourne',4);

-- note taht the other records will now have this value empty
select * from publishers;

-- let's delete this for now
DELETE from publishers * where id = 160;


--create the missing table
CREATE TABLE "states" (
	"id" integer NOT NULL,
	"name" text,
	"abbreviation" character(2),
	Constraint "state_pkey" Primary Key ("id")
);

-- fill some data into states
INSERT INTO states (id, name, abbreviation) VALUES (1,'New York','NY');

ALTER TABLE "publishers" 
	Add CONSTRAINT publishers_state_fk FOREIGN KEY (state_id) REFERENCES "states" ("id");

-- this will fail, no state for 2 (canada) specified
INSERT INTO publishers (id, name, address,state_id) VALUES (160,'Kids Can Press','Kids Can Press, 29 Birch Ave. Toronto',2);

-- this will work, uses NY
INSERT INTO publishers (id, name, address, state_id) VALUES (91,'Henry Holt & Company, Inc.','Henry Holt & Company, Inc. 115 West 18th Street New York, NY 10011',1);

select * from publishers;

-- we can experiment with the Cascade option on DROP if we have time - need to recreate the table after this, from line 70 onwards
DROP TABLE states;
DROP TABLE states CASCADE;

-- some more data
INSERT INTO states (id, name, abbreviation) VALUES (2,'Canada','CA');
INSERT INTO states (id, name, abbreviation) VALUES (3,'United Kingdom','UK');
INSERT INTO publishers (id, name, address, state_id) VALUES (113,'OReilly & Associates','	OReilly & Associates, Inc. 101 Morris St, Sebastopol, CA 95472',2);
-- different syntax for insert - also note the typo
INSERT INTO "states" VALUES (32,'New Yersey','NJ');

-- Postgres allows bulk imports
-- other delimiters: ',' automatically assumed for CSV. Also can specify if you have a header. Header must match table structure.
--COPY "states"  FROM '/Users/mtomko/Documents/Teaching/UoM_IE/GEOM90018_SpatialDatabases/GEOM90018_2016/data/authors.tsv' WITH DELIMITER E'\t';

-- demonstrating UDPATE
select * from states;

UPDATE "states" SET name='New Jersey' WHERE id=32;

select * from states;

-- DELETE
DELETE FROM "states" WHERE id = 32;
select * from states;

--- SQL - SELECT queries

SELECT * FROM "states";

SELECT name, abbreviation FROM "states";

SELECT name, abbreviation FROM "states" WHERE name = 'Canada';

SELECT name, abbreviation FROM "states" WHERE id > 3;

-- join example
SELECT p.id, p.name, s.name,s.abbreviation FROM states s
	JOIN publishers p ON p.state_id = s.id;

--JOIN with restriction
SELECT p.id, p.name, s.name,s.abbreviation FROM states s
	JOIN publishers p ON p.state_id = s.id
	WHERE s.abbreviation = 'NY';

-- A select can lead to a creation of a table
CREATE TABLE mytab AS (SELECT name, abbreviation FROM "states" WHERE id > 3);

select * from publishers;

  