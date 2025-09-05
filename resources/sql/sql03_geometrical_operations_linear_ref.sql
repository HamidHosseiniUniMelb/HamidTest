-- Linear referencing

-- preparation - we will find a police station - a point. This is Brunswick station
-- and a road that is nearest
with station as 
(SELECT id, code, geom FROM spatial.victoria_police_stations
where id=36) 
SELECT vr."OBJECTID", st_geometrytype(vr.geom), vr.geom <-> st.geom AS dist
FROM spatial.victoria_roads2023 as vr,
station as st
ORDER BY
  dist
LIMIT 1;

-- we can check which road this is
SELECT vr.geom FROM spatial.victoria_roads2023 as vr
where vr."OBJECTID"=526584;


-- now we can find the linear referencing of the station along the road
with roads as (SELECT vr."OBJECTID",vr.geom FROM spatial.victoria_roads2023 as vr),
stations as 
(SELECT id, code, geom FROM spatial.victoria_police_stations)
SELECT ST_LineLocatePoint((ST_DUMP(rd.geom)).geom::geometry,st.geom) FROM roads as rd, stations as st
where st.id=36 AND 
rd."OBJECTID"=526584;

-- THis returns the compement if reversed:

with roads as (SELECT vr."OBJECTID",vr.geom FROM spatial.victoria_roads2023 as vr),
stations as 
(SELECT id, code, geom FROM spatial.victoria_police_stations)
SELECT ST_LineLocatePoint(ST_REVERSE((ST_DUMP(rd.geom)).geom::geometry),st.geom) FROM roads as rd, stations as st
where st.id=36 AND 
rd."OBJECTID"=526584;
