WITH bbq_restaurants AS (
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
)
SELECT 
    name,
    address,
    latitude,
    longitude,
    tel,
    website
FROM bbq_restaurants; 