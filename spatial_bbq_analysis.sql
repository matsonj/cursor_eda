INSTALL spatial;
LOAD spatial;
INSTALL h3;
LOAD h3;

-- Query to identify top 3 H3 tiles with high restaurant density and no BBQ restaurants
WITH restaurant_density AS (
    SELECT 
        h3_lat_lng_to_cell(p.latitude, p.longitude, 9) AS h3_cell,
        COUNT(*) as restaurant_count
    FROM places p
    WHERE 
        p.locality ILIKE '%boston%'
        AND p.date_closed IS NULL
        AND p.latitude BETWEEN 42.2279 AND 42.3975
        AND p.longitude BETWEEN -71.1912 AND -70.8085
    GROUP BY h3_cell
),
bbq_locations AS (
    SELECT 
        h3_lat_lng_to_cell(p.latitude, p.longitude, 9) AS h3_cell
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
    GROUP BY h3_cell
)
SELECT 
    rd.h3_cell,
    h3_cell_to_lat(rd.h3_cell) AS latitude,
    h3_cell_to_lng(rd.h3_cell) AS longitude,
    rd.restaurant_count
FROM restaurant_density rd
WHERE NOT EXISTS (
    SELECT 1
    FROM bbq_locations bl
    WHERE bl.h3_cell = rd.h3_cell
)
ORDER BY rd.restaurant_count DESC
LIMIT 3; 