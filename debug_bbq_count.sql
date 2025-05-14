INSTALL spatial;
LOAD spatial;

SELECT COUNT(*) AS bbq_restaurant_count
FROM places p
LEFT JOIN categories c ON p.fsq_category_ids[1] = c.category_id
WHERE p.locality ILIKE '%boston%'
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
  AND p.longitude BETWEEN -71.1912 AND -70.8085; 