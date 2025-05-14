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
),
bbq_restaurants AS (
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
        AND (
            c.category_name ILIKE '%bbq%' OR
            c.category_label ILIKE '%bbq%' OR
            c.level2_category_name ILIKE '%bbq%' OR
            c.level3_category_name ILIKE '%bbq%'
        )
),
hex_counts AS (
    SELECT 
        h3_latlng_to_cell(latitude, longitude, 9) as h3_hex,
        COUNT(*) as restaurant_count
    FROM boston_restaurants
    GROUP BY h3_hex
),
hexes_without_bbq AS (
    SELECT 
        hc.h3_hex,
        hc.restaurant_count
    FROM hex_counts hc
    LEFT JOIN bbq_restaurants bbq ON h3_latlng_to_cell(bbq.latitude, bbq.longitude, 9) = hc.h3_hex
    WHERE bbq.name IS NULL
)
SELECT 
    h3_hex,
    restaurant_count
FROM hexes_without_bbq
ORDER BY restaurant_count DESC
LIMIT 3; 