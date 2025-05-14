-- Load spatial extension
INSTALL spatial;
LOAD spatial;

WITH restaurant_stats AS (
    SELECT 
        CASE 
            WHEN array_to_string(fsq_category_labels, ',') LIKE '%African%' THEN 'African'
            ELSE 'Other'
        END as category,
        COUNT(*) as count,
        AVG(latitude) as avg_lat,
        AVG(longitude) as avg_lon
    FROM places
    WHERE locality = 'Oakland'
        AND region = 'CA'
        AND array_to_string(fsq_category_labels, ',') LIKE '%Restaurant%'
        AND (date_closed IS NULL OR date_closed = '')
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL
    GROUP BY 1
)
SELECT * FROM restaurant_stats; 