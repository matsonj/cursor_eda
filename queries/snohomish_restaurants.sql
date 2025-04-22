-- Query to get BBQ restaurants in Snohomish County
SELECT 
    p.name,
    p.address,
    p.locality,
    p.region,
    p.postcode,
    p.latitude,
    p.longitude,
    p.fsq_category_labels,
    -- Create a point geometry for mapping
    ST_Point(p.longitude, p.latitude) as geom,
    -- Add a type column to distinguish between confirmed and potential BBQ places
    CASE 
        WHEN ARRAY_CONTAINS(p.fsq_category_labels, 'Dining and Drinking > Restaurant > BBQ Joint') THEN 'Confirmed BBQ'
        WHEN ARRAY_CONTAINS(p.fsq_category_labels, 'Dining and Drinking > Restaurant > Southern Restaurant') THEN 'Potential BBQ'
        ELSE 'BBQ-Related'
    END as bbq_type
FROM 
    places p 
WHERE 
    region = 'WA' 
    AND (
        locality ILIKE '%Snohomish%' 
        OR locality IN (
            'Everett', 
            'Lynnwood', 
            'Marysville', 
            'Edmonds', 
            'Mukilteo', 
            'Arlington', 
            'Monroe', 
            'Lake Stevens', 
            'Bothell', 
            'Mill Creek'
        )
    )
    -- Ensure it's a restaurant first
    AND ARRAY_CONTAINS(p.fsq_category_labels, 'Dining and Drinking > Restaurant')
    -- Exclude non-restaurant businesses
    AND NOT ARRAY_CONTAINS(p.fsq_category_labels, 'Health and Medicine')
    AND NOT ARRAY_CONTAINS(p.fsq_category_labels, 'Veterinarian')
    AND NOT ARRAY_CONTAINS(p.fsq_category_labels, 'Medical Center')
    AND NOT ARRAY_CONTAINS(p.fsq_category_labels, 'Hospital')
    AND (
        -- Confirmed BBQ places
        ARRAY_CONTAINS(p.fsq_category_labels, 'Dining and Drinking > Restaurant > BBQ Joint')
        OR ARRAY_CONTAINS(p.fsq_category_labels, 'Dining and Drinking > Restaurant > Southern Restaurant')
        -- Name-based BBQ identification (more specific)
        OR (
            LOWER(p.name) LIKE '%bbq%'
            OR LOWER(p.name) LIKE '%barbecue%'
            OR LOWER(p.name) LIKE '%barbeque%'
            OR LOWER(p.name) LIKE '%smokehouse%'
            OR LOWER(p.name) LIKE '%smoker%'
            OR LOWER(p.name) LIKE '%smoked%'
            OR LOWER(p.name) LIKE '%smoking%'
            OR LOWER(p.name) LIKE '%pit%'
            OR LOWER(p.name) LIKE '%ribs%'
            OR LOWER(p.name) LIKE '%jeff%'
        )
    )
ORDER BY 
    bbq_type,
    p.locality, 
    p.name;

-- Query to specifically find Jeff's BBQ in Marysville
SELECT 
    p.name,
    p.address,
    p.locality,
    p.region,
    p.postcode,
    p.latitude,
    p.longitude,
    p.fsq_category_labels
FROM 
    places p 
WHERE 
    region = 'WA' 
    AND locality = 'Marysville'
    AND LOWER(p.name) LIKE '%jeff%'
ORDER BY 
    p.name; 