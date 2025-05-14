SELECT name, address, latitude, longitude, locality, region, fsq_category_labels
FROM places
WHERE locality = 'Oakland'
  AND region = 'CA'
  AND array_to_string(fsq_category_labels, ',') LIKE '%Restaurant%'; 