WITH restaurant_categories AS (
    SELECT 
        name,
        fsq_category_labels,
        date_closed
    FROM places
    WHERE locality = 'Oakland'
        AND region = 'CA'
        AND array_to_string(fsq_category_labels, ',') LIKE '%Restaurant%'
        AND (date_closed IS NULL OR date_closed = '')  -- Only active restaurants
),
flattened_categories AS (
    SELECT 
        name,
        UNNEST(fsq_category_labels) as category
    FROM restaurant_categories
),
category_counts AS (
    SELECT 
        category,
        COUNT(*) as restaurant_count
    FROM flattened_categories
    WHERE category LIKE '%Restaurant%'  -- Only count actual restaurant categories
    GROUP BY category
    ORDER BY restaurant_count DESC
)
SELECT 
    category,
    restaurant_count,
    ROUND(restaurant_count * 100.0 / SUM(restaurant_count) OVER (), 2) as percentage
FROM category_counts; 