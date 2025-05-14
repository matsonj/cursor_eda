WITH base_data AS (
    SELECT * FROM read_csv('data/restaurant_analysis.csv')
),
top_level_categories AS (
    SELECT 
        CASE 
            WHEN category LIKE '%Mexican%' THEN 'Mexican'
            WHEN category LIKE '%Asian%' THEN 'Asian'
            WHEN category LIKE '%American%' THEN 'American'
            WHEN category LIKE '%Italian%' THEN 'Italian'
            WHEN category LIKE '%BBQ%' THEN 'BBQ'
            WHEN category LIKE '%Seafood%' THEN 'Seafood'
            WHEN category LIKE '%Indian%' THEN 'Indian'
            WHEN category LIKE '%Mediterranean%' THEN 'Mediterranean'
            WHEN category LIKE '%Latin American%' THEN 'Latin American'
            WHEN category LIKE '%African%' THEN 'African'
            WHEN category LIKE '%Middle Eastern%' THEN 'Middle Eastern'
            WHEN category LIKE '%European%' THEN 'European'
            WHEN category LIKE '%Caribbean%' THEN 'Caribbean'
            ELSE 'Other'
        END as top_category,
        category as full_category,
        restaurant_count
    FROM base_data
    WHERE category != 'Dining and Drinking > Restaurant'  -- Exclude generic restaurant category
),
category_totals AS (
    SELECT 
        top_category,
        SUM(restaurant_count) as total_count,
        ROUND(SUM(restaurant_count) * 100.0 / SUM(SUM(restaurant_count)) OVER (), 2) as percentage
    FROM top_level_categories
    GROUP BY top_category
    ORDER BY total_count DESC
),
top_subcategories AS (
    SELECT 
        top_category,
        full_category,
        restaurant_count,
        ROW_NUMBER() OVER (PARTITION BY top_category ORDER BY restaurant_count DESC) as rank
    FROM top_level_categories
)
SELECT 
    t.top_category,
    t.total_count,
    t.percentage,
    s.full_category as most_common_subcategory,
    s.restaurant_count as subcategory_count
FROM category_totals t
LEFT JOIN top_subcategories s ON t.top_category = s.top_category AND s.rank = 1
ORDER BY t.total_count DESC; 