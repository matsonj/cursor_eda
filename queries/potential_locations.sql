-- Load spatial extension
INSTALL spatial;
LOAD spatial;

-- Check restaurant counts by locality
SELECT 
    locality,
    COUNT(*) as total_places,
    COUNT(CASE WHEN ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant') THEN 1 END) as restaurants,
    COUNT(CASE WHEN 
        ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > BBQ Joint')
        OR ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > Southern Restaurant')
        OR LOWER(name) LIKE '%bbq%'
        OR LOWER(name) LIKE '%barbecue%'
        OR LOWER(name) LIKE '%barbeque%'
        OR LOWER(name) LIKE '%smokehouse%'
        OR LOWER(name) LIKE '%smoker%'
        OR LOWER(name) LIKE '%smoked%'
        OR LOWER(name) LIKE '%smoking%'
        OR LOWER(name) LIKE '%pit%'
        OR LOWER(name) LIKE '%ribs%'
    THEN 1 END) as bbq_places
FROM places
WHERE 
    region = 'WA' 
    AND locality IN (
        'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
        'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
        'Bothell', 'Mill Creek', 'Snohomish'
    )
GROUP BY locality
ORDER BY total_places DESC;

-- First, let's check the density distribution
WITH density_areas AS (
    -- Calculate restaurant density by grid cell
    SELECT 
        ROUND(latitude, 3) as lat_grid,
        ROUND(longitude, 3) as lon_grid,
        COUNT(*) as restaurant_count,
        AVG(latitude) as center_lat,
        AVG(longitude) as center_lon,
        STRING_AGG(name, ', ') as sample_restaurants
    FROM places
    WHERE 
        region = 'WA' 
        AND locality IN (
            'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
            'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
            'Bothell', 'Mill Creek', 'Snohomish'
        )
        AND ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant')
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL
    GROUP BY 
        ROUND(latitude, 3),
        ROUND(longitude, 3)
)
SELECT 
    lat_grid,
    lon_grid,
    restaurant_count,
    center_lat,
    center_lon,
    sample_restaurants,
    NTILE(5) OVER (ORDER BY restaurant_count) as density_quintile
FROM density_areas
WHERE restaurant_count > 5  -- Only show areas with meaningful density
ORDER BY restaurant_count DESC
LIMIT 10;

-- Query to find high-density areas without nearby BBQ restaurants
WITH density_areas AS (
    -- Calculate restaurant density by grid cell
    SELECT 
        ROUND(latitude, 3) as lat_grid,
        ROUND(longitude, 3) as lon_grid,
        COUNT(*) as restaurant_count,
        AVG(latitude) as center_lat,
        AVG(longitude) as center_lon
    FROM places
    WHERE 
        region = 'WA' 
        AND locality IN (
            'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
            'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
            'Bothell', 'Mill Creek', 'Snohomish'
        )
        AND ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant')
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL
    GROUP BY 
        ROUND(latitude, 3),
        ROUND(longitude, 3)
),
density_percentiles AS (
    -- Calculate density percentiles
    SELECT 
        *,
        PERCENT_RANK() OVER (ORDER BY restaurant_count) as density_rank
    FROM density_areas
),
existing_bbq AS (
    -- Get all BBQ restaurant locations
    SELECT 
        latitude,
        longitude,
        ST_Point(longitude, latitude) as geom
    FROM places
    WHERE 
        region = 'WA' 
        AND locality IN (
            'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
            'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
            'Bothell', 'Mill Creek', 'Snohomish'
        )
        AND (
            ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > BBQ Joint')
            OR ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > Southern Restaurant')
            OR LOWER(name) LIKE '%bbq%'
            OR LOWER(name) LIKE '%barbecue%'
            OR LOWER(name) LIKE '%barbeque%'
            OR LOWER(name) LIKE '%smokehouse%'
            OR LOWER(name) LIKE '%smoker%'
            OR LOWER(name) LIKE '%smoked%'
            OR LOWER(name) LIKE '%smoking%'
            OR LOWER(name) LIKE '%pit%'
            OR LOWER(name) LIKE '%ribs%'
        )
),
candidate_areas AS (
    -- Find areas that are high density and not near existing BBQ
    SELECT 
        d.*,
        MIN(ST_Distance(
            ST_Point(d.center_lon, d.center_lat),
            b.geom
        )) as min_distance_to_bbq
    FROM density_percentiles d
    CROSS JOIN existing_bbq b
    WHERE d.density_rank >= 0.8  -- Top 20% density
    GROUP BY 
        d.lat_grid,
        d.lon_grid,
        d.restaurant_count,
        d.center_lat,
        d.center_lon,
        d.density_rank
    HAVING MIN(ST_Distance(
        ST_Point(d.center_lon, d.center_lat),
        b.geom
    )) > 1609.34  -- More than 1 mile (1609.34 meters)
)
-- Get top 3 areas by restaurant count
SELECT 
    lat_grid,
    lon_grid,
    restaurant_count,
    center_lat,
    center_lon,
    min_distance_to_bbq,
    ROUND(min_distance_to_bbq * 0.000621371, 2) as min_distance_to_bbq_miles
FROM candidate_areas
ORDER BY restaurant_count DESC
LIMIT 3;

WITH restaurant_clusters AS (
    -- Find clusters of restaurants
    SELECT 
        ROUND(latitude, 3) as lat_grid,
        ROUND(longitude, 3) as lon_grid,
        COUNT(*) as restaurant_count,
        AVG(latitude) as center_lat,
        AVG(longitude) as center_lon,
        STRING_AGG(name, ', ') as sample_restaurants
    FROM places
    WHERE 
        region = 'WA' 
        AND locality IN (
            'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
            'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
            'Bothell', 'Mill Creek', 'Snohomish'
        )
        AND ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant')
    GROUP BY 
        ROUND(latitude, 3),
        ROUND(longitude, 3)
    HAVING COUNT(*) >= 5  -- Only consider areas with at least 5 restaurants
),
bbq_locations AS (
    -- Get BBQ restaurant locations
    SELECT 
        name,
        latitude,
        longitude,
        locality,
        ST_Point(longitude, latitude) as geom
    FROM places
    WHERE 
        region = 'WA' 
        AND locality IN (
            'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
            'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
            'Bothell', 'Mill Creek', 'Snohomish'
        )
        AND (
            ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > BBQ Joint')
            OR ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > Southern Restaurant')
            OR LOWER(name) LIKE '%bbq%'
            OR LOWER(name) LIKE '%barbecue%'
            OR LOWER(name) LIKE '%barbeque%'
            OR LOWER(name) LIKE '%smokehouse%'
            OR LOWER(name) LIKE '%smoker%'
            OR LOWER(name) LIKE '%smoked%'
            OR LOWER(name) LIKE '%smoking%'
            OR LOWER(name) LIKE '%pit%'
            OR LOWER(name) LIKE '%ribs%'
        )
),
potential_locations AS (
    -- Find restaurant clusters and their distance to nearest BBQ
    SELECT 
        rc.*,
        MIN(ST_Distance(
            ST_Point(rc.center_lon, rc.center_lat),
            bl.geom
        )) as min_distance_to_bbq,
        STRING_AGG(bl.name, ', ') FILTER (
            WHERE ST_Distance(
                ST_Point(rc.center_lon, rc.center_lat),
                bl.geom
            ) < 3218.69  -- 2 miles
        ) as nearby_bbq_places
    FROM restaurant_clusters rc
    CROSS JOIN bbq_locations bl
    GROUP BY 
        rc.lat_grid,
        rc.lon_grid,
        rc.restaurant_count,
        rc.center_lat,
        rc.center_lon,
        rc.sample_restaurants
)
-- Get top locations by restaurant count where BBQ is more than 1 mile away
SELECT 
    restaurant_count,
    center_lat,
    center_lon,
    ROUND(min_distance_to_bbq * 0.000621371, 2) as distance_to_nearest_bbq_miles,
    nearby_bbq_places,
    sample_restaurants
FROM potential_locations
WHERE min_distance_to_bbq > 1609.34  -- More than 1 mile
  AND restaurant_count >= (
      SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY restaurant_count)
      FROM potential_locations
  )
ORDER BY restaurant_count DESC
LIMIT 3;

-- Find high-traffic areas without BBQ restaurants
WITH restaurant_areas AS (
    -- Get all restaurants with their BBQ status
    SELECT 
        name,
        latitude,
        longitude,
        locality,
        CASE 
            WHEN ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > BBQ Joint')
                OR ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > Southern Restaurant')
                OR LOWER(name) LIKE '%bbq%'
                OR LOWER(name) LIKE '%barbecue%'
                OR LOWER(name) LIKE '%barbeque%'
                OR LOWER(name) LIKE '%smokehouse%'
                OR LOWER(name) LIKE '%smoker%'
                OR LOWER(name) LIKE '%smoked%'
                OR LOWER(name) LIKE '%smoking%'
                OR LOWER(name) LIKE '%pit%'
                OR LOWER(name) LIKE '%ribs%'
            THEN true 
            ELSE false 
        END as is_bbq,
        -- Create a 0.5 mile grid (approximately)
        ROUND(latitude, 2) as lat_grid,
        ROUND(longitude, 2) as lon_grid
    FROM places
    WHERE 
        region = 'WA' 
        AND locality IN (
            'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
            'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
            'Bothell', 'Mill Creek', 'Snohomish'
        )
        AND ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant')
),
grid_stats AS (
    -- Calculate statistics for each grid cell
    SELECT 
        locality,
        lat_grid,
        lon_grid,
        COUNT(*) as total_restaurants,
        SUM(CASE WHEN is_bbq THEN 1 ELSE 0 END) as bbq_restaurants,
        STRING_AGG(CASE WHEN is_bbq THEN name ELSE NULL END, ', ') as bbq_names,
        STRING_AGG(CASE WHEN NOT is_bbq THEN name ELSE NULL END, ', ') FILTER (WHERE NOT is_bbq) as other_restaurants,
        AVG(latitude) as center_lat,
        AVG(longitude) as center_lon
    FROM restaurant_areas
    GROUP BY 
        locality,
        lat_grid,
        lon_grid
    HAVING COUNT(*) >= 5  -- Only consider areas with at least 5 restaurants
)
-- Find top areas with no BBQ restaurants
SELECT 
    locality,
    total_restaurants,
    center_lat,
    center_lon,
    bbq_restaurants,
    bbq_names,
    other_restaurants
FROM grid_stats
WHERE bbq_restaurants = 0
ORDER BY total_restaurants DESC
LIMIT 3; 