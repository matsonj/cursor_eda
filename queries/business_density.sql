-- Load spatial extension
INSTALL spatial;
LOAD spatial;

-- Query to analyze business density by locality
SELECT 
    locality,
    COUNT(*) as total_businesses,
    COUNT(CASE WHEN ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant') THEN 1 END) as restaurants,
    MIN(latitude) as min_lat,
    MAX(latitude) as max_lat,
    MIN(longitude) as min_lon,
    MAX(longitude) as max_lon,
    AVG(latitude) as center_lat,
    AVG(longitude) as center_lon
FROM 
    places
WHERE 
    region = 'WA' 
    AND locality IN (
        'Everett', 
        'Lynnwood', 
        'Marysville', 
        'Edmonds', 
        'Mukilteo', 
        'Arlington', 
        'Monroe', 
        'Lake Stevens', 
        'Bothell', 
        'Mill Creek',
        'Snohomish'
    )
GROUP BY 
    locality
ORDER BY 
    total_businesses DESC; 