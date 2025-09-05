-- INTRO TO SQL

-- Basic SELECT statements

-- pattern: SELECT columnames FROM tablename WHERE condition_that_evaluates_to_true
-- find out all the tables in the database
-- '*' selects all the columns of a table
-- do not forget ';' at the end of the statement
-- use qualified table names to specify tables not in your schema

SELECT * FROM spatial.us_cities;

-- if you want to select just some columns, specify their names
-- you can also specify an alias for the table name, to reduce the typing
-- below, we call 't' the table 'us_cities' from the schema 'spatial' 
-- we then ask only for the column 'state_abrv' from the table 't'

SELECT t.state_abrv FROM spatial.us_cities t;

-- if you want to find out what columns a table has in Postgres
-- this is equivalent to the known statement 'DESCRIBE TABLE tablename' as known in e.g. Oracle. 
-- Note for advanced users: in PG, it can be done using '\d+' if you are using the command line pgsql program.

SELECT * FROM information_schema.tables;

-- this is a rich table, 
-- we can constrain our select to a few important attributes of the tables we care about
-- note that splitting the SELECT statement across a few lines makes it legible
-- but this is why you need the ';' , so that the system knows where the statement ends.

SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'us_cities';