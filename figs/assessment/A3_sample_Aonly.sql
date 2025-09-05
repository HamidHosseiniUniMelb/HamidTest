-- question 1
WITH direct AS
  (SELECT ST_DISTANCE(ST_MakePoint(144.8433,
                        -37.6709)::geography,
            ST_MakePoint(-0.4543,
              51.4700)::geography,
            TRUE) AS distance),
     indirect AS
  (SELECT ST_DISTANCE(ST_MakePoint(144.8433,
                        -37.6709)::geography,
            ST_MakePoint(103.9915,
              1.3644)::geography,
            TRUE)+ ST_DISTANCE(ST_MakePoint(103.9915,
                                 1.3644)::geography,

                     ST_MakePoint(-0.4543,
                       51.4700)::geography, TRUE) AS distance)
SELECT 100*(indirect.distance-direct.distance)/direct.distance AS percent,
       (indirect.distance-direct.distance)/1000 AS kilometres
FROM direct,indirect;

-- question 2
SELECT cntry_name AS name, ST_Perimeter(geom,
                             TRUE) / 1000 AS border,
       pop_cntry AS pop
FROM spatial.world_countries
WHERE pop_cntry > 25000
ORDER BY ST_Perimeter(geom, TRUE) ASC
LIMIT 10;

-- question 3
SELECT c.interstate AS interstate_name
FROM spatial.us_states AS a, spatial.us_states AS b,
     spatial.us_interstates AS c
WHERE a.state = 'Utah'
  AND b.state = 'Illinois'
  AND ST_Crosses(c.geom, a.geom)
  AND ST_Crosses(c.geom, b.geom)
ORDER BY interstate_name;

-- question 4
SELECT b.cntry_name AS name,
       b.pop_cntry/(ST_area(b.geom::geography,
                      TRUE)/1000000) AS pop_density
FROM spatial.world_countries AS a, spatial.world_countries AS b
WHERE St_Touches(a.geom, b.geom)
  AND a.cntry_name = 'Brazil'
ORDER BY ST_Length(ST_Intersection(ST_Boundary(a.geom),
                     ST_Boundary(b.geom)), TRUE) DESC;
					 
-- question 5
WITH traversed_edges AS
  (SELECT edge
   FROM pgr_dijkstraVia('SELECT id, source, target, st_length(geom, TRUE) as cost,
        (CASE WHEN car_rev THEN st_length(geom, TRUE) ELSE -1 END) AS reverse_cost 
        FROM spatial.carlton_edges where car', ARRAY[1926,
          311, 1844, 1416], directed:=TRUE))
SELECT st_area(st_buffer(st_transform(st_union(geom),
                           7855),
                 20)) AS area
FROM spatial.carlton_edges
WHERE id IN
    (SELECT *
     FROM traversed_edges);

-- question 6
SELECT sum(st_length(geom, TRUE))/1000 AS WALK_DISTANCE_KMS
FROM pgr_dijkstra('SELECT id, 
                            source, 
                            target, 
                            st_length(geom, TRUE) AS cost 
                       FROM spatial.carlton_edges WHERE foot',
       973, 1355, directed:=FALSE)
JOIN spatial.carlton_edges ON edge = id;

-- question 7
SELECT count(*)
FROM pgr_floydWarshall('SELECT id, source, target, st_length(geom, TRUE) as cost FROM spatial.carlton_edges where foot',
       FALSE)
WHERE (start_vid = 145)
  AND (agg_cost >= 1500
       AND agg_cost <= 2000);

-- question 8
SELECT max((ST_SummaryStats(ST_Clip(rast,

                              ST_Transform(lga.geom,
                                7855)))).max) AS max_elev,
       min((ST_SummaryStats(ST_Clip(rast,

                              ST_Transform(lga.geom,
                                7855)))).min) AS min_elev
FROM spatial.victoria_dem_30m_o_2, spatial.victoria_lgas AS lga
WHERE lga_name = 'MANSFIELD'
  AND ST_Intersects(rast,
        ST_Transform(lga.geom, 7855));

-- question 9
WITH ten_longest_roads AS
  (SELECT osmways.osm_id as id, osmways.name, osmways.way,
          ST_StartPoint(osmways.way) AS startpoint, ST_EndPoint(osmways.way) AS endpoint
   FROM spatial.melbourne_osm_roads AS osmways
   ORDER BY ST_length(osmways.way) DESC
   LIMIT 10),
     ten_longest_start_end AS
  (SELECT id, name, 'START' AS TYPE,
          ST_StartPoint(way) AS POINT
   FROM ten_longest_roads
   UNION SELECT id, name, 'END' AS TYPE,
                ST_EndPoint(way) AS POINT
   FROM ten_longest_roads),
     join_raster_start_end AS
  (SELECT id, name, TYPE, POINT,
          ST_Value(dem.rast,
            1, ST_Transform(POINT,
                 7855), TRUE, 'nearest') AS elev
   FROM ten_longest_start_end, spatial.victoria_dem_30m_o_2 AS dem
   WHERE ST_Intersects(dem.rast,
           ST_Transform(POINT, 7855)))
SELECT r.name AS name, st_length(r.way) AS LENGTH,
       s.elev AS start_elev, e.elev AS end_elev,
       e.elev-s.elev AS diff_elev
FROM ten_longest_roads AS r, join_raster_start_end AS s,
     join_raster_start_end AS e
WHERE s.type = 'START'
  AND e.type = 'END'
  AND r.id = s.id
  AND r.id = e.id
ORDER BY 2 DESC;


-- question 10
SELECT ST_X(ST_Transform(elev_points.geom,
              4326)) AS lon,
       ST_Y(ST_Transform(elev_points.geom,
              4326)) AS lat, elev_points.val AS height, campus
FROM
  (SELECT (ST_PixelAsPoints(ST_Clip(rast,

                              ST_UnaryUnion(ST_Transform(unimelb_campus.geom,
                                              7855))))).*
   FROM spatial.victoria_dem_30m_o_2, spatial.unimelb_campus) AS elev_points, spatial.unimelb_campus
WHERE ST_Intersects(ST_Transform(unimelb_campus.geom,
                      7855),
        elev_points.geom)
ORDER BY elev_points.val DESC
LIMIT 1;
