INSTALL spatial;
LOAD spatial;

-- Find the densest restaurant locations in Boston (no BBQ exclusion)
WITH restaurant_density AS (
    SELECT 
        p.latitude,
        p.longitude,
        COUNT(*) as restaurant_count
    FROM places p
    WHERE 
        p.locality ILIKE '%boston%'
        AND p.date_closed IS NULL
        AND p.latitude BETWEEN 42.2279 AND 42.3975
        AND p.longitude BETWEEN -71.1912 AND -70.8085
    GROUP BY p.latitude, p.longitude
)
SELECT 
    latitude,
    longitude,
    restaurant_count
FROM restaurant_density
ORDER BY restaurant_count DESC
LIMIT 10; 