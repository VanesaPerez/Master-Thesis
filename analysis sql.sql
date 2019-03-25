-- Adjust Reference System
ALTER TABLE decision_points ALTER COLUMN geom TYPE geometry(MultiPoint,32632) USING ST_Transform(geom,32632);
ALTER TABLE point_landmarks ALTER COLUMN geom TYPE geometry(MultiPoint,32632) USING ST_Transform(geom,32632);

--SELECT * FROM decision_points;
--SELECT distinct(participid) FROM decision_points order by participid;
--SELECT distinct(participid) FROM point_landmarks order by participid;

-- Remove participant 15/17
SELECT * INTO decision_points_no15 FROM decision_points WHERE participid != 15;
SELECT * INTO decision_points_no17 FROM decision_points WHERE participid != 17;
SELECT * INTO point_landmarks_no15 FROM point_landmarks WHERE participid != 15;
SELECT * INTO point_landmarks_no17 FROM point_landmarks WHERE participid != 17;


-- Split decision points by route
DROP TABLE IF EXISTS decision_points_1;
SELECT * INTO decision_points_1 FROM decision_points_no17 WHERE routeid = 1;

DROP TABLE IF EXISTS decision_points_2;
SELECT * INTO decision_points_2 FROM decision_points_no17 WHERE routeid = 2;

DROP TABLE IF EXISTS decision_points_3;
SELECT * INTO decision_points_3 FROM decision_points_no17 WHERE routeid = 3;


-- Split point landmarks by route
DROP TABLE IF EXISTS point_landmarks_1;
SELECT * INTO point_landmarks_1 FROM point_landmarks_no17 WHERE routeid = 1;

DROP TABLE IF EXISTS point_landmarks_2;
SELECT * INTO point_landmarks_2 FROM point_landmarks_no17 WHERE routeid = 2;

DROP TABLE IF EXISTS point_landmarks_3;
SELECT * INTO point_landmarks_3 FROM point_landmarks_no17 WHERE routeid = 3;


-- Test: Create route conntection table for participant 1 route 1
-- create test table
--DROP TABLE IF EXISTS segments_route_1_part_1;

--SELECT * INTO decision_points_1_1 FROM decision_points_1 WHERE participid = 1 ORDER BY id;
-- Test: Create route conntection table for one route of one participant
--SELECT *, sum(distance) over (order by from_id) as agg_distance INTO segments_route_1_part_1 FROM (
--	SELECT routeid, participid,(lag(id, 1) over (order by id)) as from_id, id as to_id,
--		ST_MakeLine(geom, lag(geom,1) over (order by id)) as geom,
--		ST_Distance(geom, lag(geom,1) over (order by id)) as distance
--	FROM (SELECT id, (ST_Dump(geom)).geom as geom, routeid, participid, seqdp, typedp FROM decision_points_1_1) as dp
--) as foo
--WHERE distance IS NOT NULL;

--SELECT * FROM segments_route_1_part_1;


-- Create route conntection table for all participant: Route 1
DROP TABLE IF EXISTS segments_route_1;
DROP TABLE IF EXISTS segments_route_norm_1;

SELECT *, sum(distance) over (PARTITION BY participid order by to_id) as agg_distance INTO segments_route_1 FROM (
	SELECT routeid, participid,(lag(id, 1) over (PARTITION BY participid order by id)) as from_id, id as to_id, typedp,
		ST_MakeLine(geom, lag(geom,1) over (PARTITION BY participid order by id)) as geom,
		coalesce(ST_Distance(geom, lag(geom,1) over (PARTITION BY participid order by id)),0) as distance
	FROM (SELECT id, (ST_Dump(geom)).geom as geom, routeid, participid, seqdp, typedp FROM decision_points_1) as dp
) as foo
WHERE distance IS NOT NULL;

SELECT * FROM segments_route_1;

WITH length as (
SELECT participid, max(agg_distance) as length FROM segments_route_1 GROUP BY participid ORDER BY participid
)
SELECT seg.*, (seg.agg_distance/length.length*1000) as norm_distance INTO segments_route_norm_1
FROM length, segments_route_1 as seg
WHERE length.participid = seg.participid;

SELECT * FROM segments_route_norm_1;



-- Create route conntection table for all participant: Route 2
DROP TABLE IF EXISTS segments_route_2;
DROP TABLE IF EXISTS segments_route_norm_2;

SELECT *, sum(distance) over (PARTITION BY participid order by to_id) as agg_distance INTO segments_route_2 
FROM (
	SELECT routeid, participid,(lag(id, 1) over (PARTITION BY participid order by id)) as from_id, id as to_id, typedp,
		ST_MakeLine(geom, lag(geom,1) over (PARTITION BY participid order by id)) as geom,
		coalesce(ST_Distance(geom, lag(geom,1) over (PARTITION BY participid order by id)),0) as distance
	FROM (SELECT id, (ST_Dump(geom)).geom as geom, routeid, participid, seqdp, typedp FROM decision_points_2) as dp
) as foo;

SELECT * FROM segments_route_2;

WITH length as (
SELECT participid, max(agg_distance) as length FROM segments_route_2 GROUP BY participid ORDER BY participid
)
SELECT seg.*, (seg.agg_distance/length.length*1000) as norm_distance INTO segments_route_norm_2
FROM length, segments_route_2 as seg
WHERE length.participid = seg.participid;

SELECT * FROM segments_route_norm_2;


-- Create route conntection table for all participant: Route 3
DROP TABLE IF EXISTS segments_route_3;
DROP TABLE IF EXISTS segments_route_norm_3;

SELECT *, sum(distance) over (PARTITION BY participid order by to_id) as agg_distance INTO segments_route_3 FROM (
	SELECT routeid, participid,(lag(id, 1) over (PARTITION BY participid order by id)) as from_id, id as to_id, typedp,
		ST_MakeLine(geom, lag(geom,1) over (PARTITION BY participid order by id)) as geom,
		coalesce(ST_Distance(geom, lag(geom,1) over (PARTITION BY participid order by id)),0) as distance
	FROM (SELECT id, (ST_Dump(geom)).geom as geom, routeid, participid, seqdp, typedp FROM decision_points_3) as dp
) as foo
WHERE distance IS NOT NULL;

SELECT * FROM segments_route_3;

WITH length as (
SELECT participid, max(agg_distance) as length FROM segments_route_3 GROUP BY participid ORDER BY participid
)
SELECT seg.*, (seg.agg_distance/length.length*1000) as norm_distance INTO segments_route_norm_3
FROM length, segments_route_3 as seg
WHERE length.participid = seg.participid;

SELECT * FROM segments_route_norm_3;


-- Make a line of all points by participant: Route1
DROP TABLE IF EXISTS route_1_lines;

SELECT DISTINCT routeid, participid, ST_Collect(geom ORDER BY from_id) as geom INTO route_1_lines
FROM segments_route_1
GROUP BY routeid, participid
ORDER BY routeid, participid;

SELECT * FROM route_1_lines;

-- Make a line of all points by participant: Route2
DROP TABLE IF EXISTS route_2_lines;

SELECT DISTINCT routeid, participid, ST_Collect(geom ORDER BY from_id) as geom INTO route_2_lines
FROM segments_route_2
GROUP BY routeid, participid 
ORDER BY routeid, participid;

SELECT * FROM route_2_lines;

-- Make a line of all points by participant: Route3
DROP TABLE IF EXISTS route_3_lines;

SELECT DISTINCT routeid, participid, ST_Collect(geom ORDER BY from_id) as geom INTO route_3_lines
FROM segments_route_3
GROUP BY routeid, participid 
ORDER BY routeid, participid;

SELECT * FROM route_3_lines;


-- Connect landmarks to route 1
DROP TABLE IF EXISTS landmarks_on_route_1;

SELECT pl.*, ST_ClosestPoint(route.geom, (ST_Dump(pl.geom)).geom) as closestpoint INTO landmarks_on_route_1 
FROM point_landmarks_1 as pl, route_1_lines as route 
WHERE pl.routeid = route.routeid AND pl.participid = route.participid;

SELECT * FROM landmarks_on_route_1;

-- Connect landmarks to route 2
DROP TABLE IF EXISTS landmarks_on_route_2;

SELECT pl.*, ST_ClosestPoint(route.geom, (ST_Dump(pl.geom)).geom) as closestpoint INTO landmarks_on_route_2
FROM point_landmarks_2 as pl, route_2_lines as route 
WHERE pl.routeid = route.routeid AND pl.participid = route.participid;

-- Connect landmarks to route 3
DROP TABLE IF EXISTS landmarks_on_route_3; 

SELECT pl.*, ST_ClosestPoint(route.geom, (ST_Dump(pl.geom)).geom) as closestpoint INTO landmarks_on_route_3
FROM point_landmarks_3 as pl, route_3_lines as route 
WHERE pl.routeid = route.routeid AND pl.participid = route.participid;


-- Measure along route
--SELECT ST_GeometryType(ST_LineMerge(geom)) FROM route_1_lines;
--SELECT * FROM landmarks_on_route_1 ;

-- Calculate distances of landmarks along the route: Route 1
DROP TABLE IF EXISTS landmarks_on_route_dist_1;
DROP TABLE IF EXISTS landmarks_on_route_dist_norm_1;

WITH measure AS (
SELECT routeid, participid, ST_AddMeasure(ST_LineMerge(geom), 0, ST_Length(geom)) geom, ST_Length(geom) l FROM route_1_lines
)
--SELECT ST_GeometryType(geom) FROM measure
SELECT point.id, point.geom, point.routeid, point.participid, point.typelandm, point.lmarkname, point.closestpoint,
	measure.l-ST_LineLocatePoint(measure.geom, point.closestpoint)*measure.l as distance INTO landmarks_on_route_dist_1 
FROM measure, landmarks_on_route_1 as point
WHERE measure.routeid = point.routeid and measure.participid = point.participid;

--SELECT * FROM landmarks_on_route_dist_1;

WITH length as (
SELECT participid, max(agg_distance) as length FROM segments_route_1 GROUP BY participid ORDER BY participid
)
SELECT lm.*, (lm.distance/length.length*1000) as norm_distance INTO landmarks_on_route_dist_norm_1
FROM length, landmarks_on_route_dist_1 as lm
WHERE length.participid = lm.participid;

--SELECT * FROM landmarks_on_route_dist_norm_1;

-- Calculate distances of landmarks along the route: Route 2
DROP TABLE IF EXISTS landmarks_on_route_dist_2;
DROP TABLE IF EXISTS landmarks_on_route_dist_norm_2;

WITH measure AS (
SELECT routeid, participid, ST_AddMeasure(ST_LineMerge(geom), 0, ST_Length(geom)) geom, ST_Length(geom) l FROM route_2_lines
)
--SELECT ST_GeometryType(geom) FROM measure
SELECT point.id, point.geom, point.routeid, point.participid, point.typelandm, point.lmarkname, point.closestpoint,
	measure.l-ST_LineLocatePoint(measure.geom, point.closestpoint)*measure.l as distance INTO landmarks_on_route_dist_2
FROM measure, landmarks_on_route_2 as point
WHERE measure.routeid = point.routeid and measure.participid = point.participid;

--SELECT * FROM landmarks_on_route_dist_2;

WITH length as (
SELECT participid, max(agg_distance) as length FROM segments_route_2 GROUP BY participid ORDER BY participid
)
SELECT lm.*, (lm.distance/length.length*1000) as norm_distance INTO landmarks_on_route_dist_norm_2
FROM length, landmarks_on_route_dist_2 as lm
WHERE length.participid = lm.participid;

--SELECT * FROM landmarks_on_route_dist_norm_2;


-- Calculate distances of landmarks along the route: Route 1
DROP TABLE IF EXISTS landmarks_on_route_dist_3;
DROP TABLE IF EXISTS landmarks_on_route_dist_norm_3;

WITH measure AS (
SELECT routeid, participid, ST_AddMeasure(ST_LineMerge(geom), 0, ST_Length(geom)) geom, ST_Length(geom) l FROM route_3_lines
)
--SELECT ST_GeometryType(geom) FROM measure
SELECT point.id, point.geom, point.routeid, point.participid, point.typelandm, point.lmarkname, point.closestpoint,
	measure.l-ST_LineLocatePoint(measure.geom, point.closestpoint)*measure.l as distance INTO landmarks_on_route_dist_3 
FROM measure, landmarks_on_route_3 as point
WHERE measure.routeid = point.routeid and measure.participid = point.participid;

WITH length as (
SELECT participid, max(agg_distance) as length FROM segments_route_3 GROUP BY participid ORDER BY participid
)
SELECT lm.*, (lm.distance/length.length*1000) as norm_distance INTO landmarks_on_route_dist_norm_3
FROM length, landmarks_on_route_dist_3 as lm
WHERE length.participid = lm.participid;

--SELECT * FROM landmarks_on_route_dist_norm_3;



-- Exporting to CSV
COPY segments_route_1 TO '/tmp/segments_route_1.csv' DELIMITER ',' CSV HEADER;
COPY segments_route_2 TO '/tmp/segments_route_2.csv' DELIMITER ',' CSV HEADER;
COPY segments_route_3 TO '/tmp/segments_route_3.csv' DELIMITER ',' CSV HEADER;

COPY segments_route_norm_1 TO '/tmp/segments_route_norm_1.csv' DELIMITER ',' CSV HEADER;
COPY segments_route_norm_2 TO '/tmp/segments_route_norm_2.csv' DELIMITER ',' CSV HEADER;
COPY segments_route_norm_3 TO '/tmp/segments_route_norm_3.csv' DELIMITER ',' CSV HEADER;


COPY landmarks_on_route_dist_1 TO '/tmp/landmarks_on_route_dist_1.csv' DELIMITER ',' CSV HEADER;
COPY landmarks_on_route_dist_2 TO '/tmp/landmarks_on_route_dist_2.csv' DELIMITER ',' CSV HEADER;
COPY landmarks_on_route_dist_3 TO '/tmp/landmarks_on_route_dist_3.csv' DELIMITER ',' CSV HEADER;

COPY landmarks_on_route_dist_norm_1 TO '/tmp/landmarks_on_route_dist_norm_1.csv' DELIMITER ',' CSV HEADER;
COPY landmarks_on_route_dist_norm_2 TO '/tmp/landmarks_on_route_dist_norm_2.csv' DELIMITER ',' CSV HEADER;
COPY landmarks_on_route_dist_norm_3 TO '/tmp/landmarks_on_route_dist_norm_3.csv' DELIMITER ',' CSV HEADER;


-- Count number of landmarks per route
SELECT count(*), routeid FROM point_landmarks group by routeid;
SELECT count(*), routeid FROM point_landmarks where typelandm = 'LL' group by routeid;

SELECT count(*), routeid FROM point_landmarks_no17 group by routeid;
SELECT count(*), routeid FROM point_landmarks_no17 where typelandm = 'LL' group by routeid;
