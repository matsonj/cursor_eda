WITH opportunity_areas AS (
    SELECT 
        ST_POINT(-122.21672065064652, 37.799492498768515) as area1,
        ST_POINT(-122.20010322109415, 37.75229016864812) as area2,
        ST_POINT(-122.17422593980609, 37.74898280157442) as area3
),
restaurants AS (
    SELECT 
        name,
        fsq_category_labels,
        ST_POINT(longitude, latitude) as location,
        CASE 
            WHEN ST_DISTANCE(ST_POINT(longitude, latitude), area1) <= 0.002 THEN 1
            WHEN ST_DISTANCE(ST_POINT(longitude, latitude), area2) <= 0.002 THEN 2
            WHEN ST_DISTANCE(ST_POINT(longitude, latitude), area3) <= 0.002 THEN 3
            ELSE 0
        END as area_number
    FROM places, opportunity_areas
    WHERE locality = 'Oakland'
        AND region = 'CA'
        AND array_to_string(fsq_category_labels, ',') LIKE '%Restaurant%'
        AND (date_closed IS NULL OR date_closed = '')
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL
)
SELECT 
    area_number,
    name,
    fsq_category_labels,
    ST_X(location) as longitude,
    ST_Y(location) as latitude
FROM restaurants
WHERE area_number > 0
ORDER BY area_number, name; 