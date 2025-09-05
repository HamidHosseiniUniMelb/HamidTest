-- using Gevel to visualize a spatial index
-- tables to use
-- public.victoria_line with index: public.victoria_line_index
-- public.victoria_point_index
-- public.victoria_polygon_index

-- create smaller table
-- check srid of big table
create table public.comonash_polygon as 
(select * from public.victoria_polygon t where st_intersects(t.way,(select t.way from public.victoria_polygon t where t.admin_level = '6' and name = 'City of Monash')));

-- create spatial index
CREATE INDEX public_comonash_polygon_gix ON public.comonash_polygon USING GIST (way); 

-- will create a table containing components of the index
drop table if exists public.comonash_polygon_gix_vis; 

-- populate it
create table public.comonash_polygon_gix_vis as 
(select level, ST_SetSRID(replace(a::text, '2DF', '')::box2d::geometry,900913) as geom from gist_print('public_comonash_polygon_gix') as t(level int, valid bool, a box2df));

-- check content
-- it is a big table, best to index it as well :)
CREATE INDEX public_comonash_polygon_gix_vis_gix ON public.comonash_polygon_gix_vis USING GIST (geom); 


select * from public.comonash_polygon_gix_vis limit 100;


-- same, but on victoria buildings

