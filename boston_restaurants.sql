-- Query to analyze restaurants in Boston by category
WITH boston_restaurants AS (
    SELECT 
        p.name,
        p.address,
        p.locality,
        p.region,
        p.postcode,
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
        AND p.date_closed IS NULL  -- Only currently open places
)
SELECT 
    COALESCE(level1_category_name, 'Uncategorized') as main_category,
    COALESCE(level2_category_name, 'Uncategorized') as sub_category,
    COUNT(*) as restaurant_count
FROM boston_restaurants
GROUP BY level1_category_name, level2_category_name
ORDER BY restaurant_count DESC; 