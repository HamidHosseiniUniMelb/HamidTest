-- Raster analysis

-- get a raster
-- as you see, not really worth looking at it, 
-- it is a binary encoded image
SELECT rid, rast
FROM spatial.victoria_dem_30m limit 1;

-- Get number of bands
-- each raster tile has the same number of bands.
-- rast is the name of the attribute storing the binary raster
SELECT rid, ST_NumBands(rast) As numbands
FROM spatial.victoria_dem_30m limit 5;

-- check the band metadata
SELECT rid, (myraster.md).*
FROM (SELECT rid, ST_BandMetaData(rast, 1) AS md
    FROM spatial.victoria_dem_30m
    LIMIT 5) As myraster;

-- Get raster metadata
-- Rasters in Postgis are split amongst many raster tiles.
-- The metadata are returned fro each tile, separately.
-- selects all elements in a single cell - not practical
-- all cells have the same metdata for the netire raster encoded
-- (note the limit constraint, without this it will take forever....)
SELECT rid, ST_MetaData(rast) As md
FROM spatial.victoria_dem_30m limit 1

-- and this is how you get the SRID of a raster
SELECT rid, ST_SRID(rast) As srid
FROM spatial.victoria_dem_30m limit 1

-- to get the metadata in a more manageable manner
-- you can expand the content of the returned md cell
SELECT rid, (myraster.md).*
 FROM (SELECT rid, ST_MetaData(rast) As md
FROM spatial.victoria_dem_30m limit 1) As myraster;

-- From world to raster values
-- retrieving a value of a raster at a location specified by a geometry (representative point of road)

-- we first identify the representative points of the longest roads in Victoria
-- then perform the retrieval of the values
with mygeom as (SELECT ST_Transform(ST_PointOnSurface(geom),7855)as midpt from spatial.victoria_roads2023 as t 
		order by ST_length(geom) DESC limit 20)
SELECT rid, ST_Value(r.rast,mygeom.midpt)	ptval 
FROM spatial.victoria_dem_30m as r 
JOIN mygeom on ST_Intersects(r.rast,mygeom.midpt)

-- explore https://www.postgis.net/docs/RT_ST_Value.html
-- for more ideas how to union results for multiple cells.
