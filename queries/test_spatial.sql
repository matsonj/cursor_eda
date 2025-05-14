-- Load spatial extension
INSTALL spatial;
LOAD spatial;

-- Simple test: count restaurants within 1 mile of downtown Oakland
SELECT 
    COUNT(*) as restaurants_near_downtown
FROM places
WHERE locality = 'Oakland'
    AND region = 'CA'
    AND array_to_string(fsq_category_labels, ',') LIKE '%Restaurant%'
    AND (date_closed IS NULL OR date_closed = '')
    AND ST_DISTANCE(
        ST_POINT(longitude, latitude),
        ST_POINT(-122.2711, 37.8044)  -- Downtown Oakland
    ) <= 1609;  -- 1 mile in meters 