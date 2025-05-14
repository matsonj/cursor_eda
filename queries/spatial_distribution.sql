-- Load spatial extension
INSTALL spatial;
LOAD spatial;

WITH restaurant_stats AS (
    SELECT 
        ST_POINT(longitude, latitude) as location,
        CASE 
            WHEN array_to_string(fsq_category_labels, ',') LIKE '%African%' THEN 'African'
            ELSE 'Other'
        END as category
    FROM places
    WHERE locality = 'Oakland'
        AND region = 'CA'
        AND array_to_string(fsq_category_labels, ',') LIKE '%Restaurant%'
        AND (date_closed IS NULL OR date_closed = '')
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL
),
distance_stats AS (
    SELECT 
        r1.category as category1,
        r2.category as category2,
        AVG(ST_DISTANCE(r1.location, r2.location)) as avg_distance,
        MIN(ST_DISTANCE(r1.location, r2.location)) as min_distance,
        MAX(ST_DISTANCE(r1.location, r2.location)) as max_distance
    FROM restaurant_stats r1
    CROSS JOIN restaurant_stats r2
    WHERE r1.location != r2.location
    GROUP BY 1, 2
)
SELECT * FROM distance_stats
ORDER BY category1, category2; 