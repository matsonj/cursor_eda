-- Load spatial extension
INSTALL spatial;
LOAD spatial;

WITH restaurant_locations AS (
    SELECT 
        name,
        fsq_category_labels,
        ST_POINT(longitude, latitude) as location,
        CASE 
            WHEN array_to_string(fsq_category_labels, ',') LIKE '%African%' THEN 1
            ELSE 0
        END as is_african
    FROM places
    WHERE locality = 'Oakland'
        AND region = 'CA'
        AND array_to_string(fsq_category_labels, ',') LIKE '%Restaurant%'
        AND (date_closed IS NULL OR date_closed = '')
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL
),
-- Use existing restaurant locations as potential centers
potential_centers AS (
    SELECT 
        r1.location as center_point,
        COUNT(CASE WHEN ST_DISTANCE(r1.location, r2.location) <= 0.002 THEN 1 END) as nearby_restaurants,
        -- About 200 meters in degrees
        MAX(CASE 
            WHEN r2.is_african = 1 AND ST_DISTANCE(r1.location, r2.location) <= 0.02 
            -- About 2km in degrees
            THEN 1 
            ELSE 0 
        END) as has_african_nearby,
        COUNT(CASE WHEN r2.is_african = 1 THEN 1 END) as total_african_restaurants
    FROM restaurant_locations r1
    CROSS JOIN restaurant_locations r2
    GROUP BY r1.location
)
SELECT 
    ST_X(center_point) as longitude,
    ST_Y(center_point) as latitude,
    nearby_restaurants,
    total_african_restaurants,
    ROUND(ST_DISTANCE(
        center_point,
        ST_POINT(-122.2711, 37.8044)  -- Downtown Oakland
    ) * 111.32, 2) as km_from_downtown  -- Convert degrees to kilometers
FROM potential_centers
WHERE has_african_nearby = 0
    AND nearby_restaurants >= 3
ORDER BY nearby_restaurants DESC
LIMIT 3; 