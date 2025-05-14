-- Query to identify top 3 locations with high restaurant density and no BBQ restaurants within 0.25 miles
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
),
bbq_locations AS (
    SELECT 
        p.latitude,
        p.longitude
    FROM places p
    LEFT JOIN categories c ON p.fsq_category_ids[1] = c.category_id
    WHERE 
        p.locality ILIKE '%boston%'
        AND p.date_closed IS NULL
        AND c.level1_category_name = 'Dining and Drinking'
        AND (
            c.category_name ILIKE '%bbq%'
            OR c.category_label ILIKE '%bbq%'
            OR c.level2_category_name ILIKE '%bbq%'
            OR c.level3_category_name ILIKE '%bbq%'
            OR c.level4_category_name ILIKE '%bbq%'
            OR c.level5_category_name ILIKE '%bbq%'
            OR c.level6_category_name ILIKE '%bbq%'
        )
        AND p.latitude BETWEEN 42.2279 AND 42.3975
        AND p.longitude BETWEEN -71.1912 AND -70.8085
)
SELECT 
    rd.latitude,
    rd.longitude,
    rd.restaurant_count
FROM restaurant_density rd
WHERE NOT EXISTS (
    SELECT 1
    FROM bbq_locations bl
    WHERE ST_Distance(
        ST_Point(rd.longitude, rd.latitude),
        ST_Point(bl.longitude, bl.latitude)
    ) <= 0.25
)
ORDER BY rd.restaurant_count DESC
LIMIT 3; 