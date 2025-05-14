INSTALL h3 FROM community;
LOAD 'h3';

WITH boston_restaurants AS (
    SELECT 
        p.name,
        p.address,
        p.locality,
        p.region,
        p.postcode,
        p.latitude,
        p.longitude,
        p.tel,
        p.website,
        c.category_name,
        c.category_label,
        c.level1_category_name,
        c.level2_category_name,
        c.level3_category_name
    FROM places p
    LEFT JOIN categories c ON p.fsq_category_ids[1] = c.category_id
    WHERE 
        p.locality ILIKE '%boston%'
        AND p.date_closed IS NULL
        AND p.latitude IS NOT NULL
        AND p.longitude IS NOT NULL
        AND c.level1_category_name ILIKE '%dining%'
)
SELECT 
    COALESCE(level1_category_name, 'Uncategorized') as main_category,
    h3_latlng_to_cell(latitude, longitude, 9) as h3_hex,
    COUNT(*) as place_count
FROM boston_restaurants
GROUP BY level1_category_name, h3_hex
ORDER BY place_count DESC; 