import duckdb
import folium
from folium.plugins import HeatMap
import pandas as pd

# Query for all restaurants in Boston
all_restaurants_query = '''
SELECT latitude, longitude
FROM places
WHERE locality ILIKE '%boston%'
  AND date_closed IS NULL
  AND latitude BETWEEN 42.2279 AND 42.3975
  AND longitude BETWEEN -71.1912 AND -70.8085;
'''

# Query for all BBQ restaurants in Boston
bbq_restaurants_query = '''
SELECT p.latitude, p.longitude, p.name
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
'''

# Query for proposed new locations (from spatial_bbq_analysis.sql)
proposed_locations_query = '''
WITH restaurant_density AS (
    SELECT 
        h3_latlng_to_cell(p.latitude, p.longitude, 9) AS h3_cell,
        COUNT(*) as restaurant_count
    FROM places p
    WHERE 
        p.locality ILIKE '%boston%'
        AND p.date_closed IS NULL
        AND p.latitude BETWEEN 42.2279 AND 42.3975
        AND p.longitude BETWEEN -71.1912 AND -70.8085
    GROUP BY h3_cell
),
bbq_locations AS (
    SELECT 
        h3_latlng_to_cell(p.latitude, p.longitude, 9) AS h3_cell
    FROM places p
    LEFT JOIN categories c ON p.fsq_category_ids[1] = c.category_id
    WHERE 
        p.locality ILIKE '%boston%'
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
        AND p.longitude BETWEEN -71.1912 AND -70.8085
    GROUP BY h3_cell
)
SELECT 
    rd.h3_cell,
    h3_cell_to_lat(rd.h3_cell) AS latitude,
    h3_cell_to_lng(rd.h3_cell) AS longitude,
    rd.restaurant_count
FROM restaurant_density rd
WHERE NOT EXISTS (
    SELECT 1
    FROM bbq_locations bl
    WHERE bl.h3_cell = rd.h3_cell
)
ORDER BY rd.restaurant_count DESC
LIMIT 3;
'''

def main():
    # Connect to DuckDB
    con = duckdb.connect('local.db')
    con.execute('INSTALL spatial;')
    con.execute('LOAD spatial;')
    con.execute('INSTALL h3 FROM community;')
    con.execute('LOAD h3;')

    # Query data
    all_restaurants = con.execute(all_restaurants_query).fetchdf()
    bbq_restaurants = con.execute(bbq_restaurants_query).fetchdf()
    proposed_locations = con.execute(proposed_locations_query).fetchdf()

    # Center map on Boston
    boston_center = [42.3601, -71.0589]
    m = folium.Map(location=boston_center, zoom_start=12)

    # Add heatmap of all restaurants
    if not all_restaurants.empty:
        HeatMap(all_restaurants[['latitude', 'longitude']].values, radius=10, blur=15, min_opacity=0.3).add_to(m)

    # Add blue pins for BBQ restaurants
    for _, row in bbq_restaurants.iterrows():
        folium.Marker(
            location=[row['latitude'], row['longitude']],
            popup=row.get('name', 'BBQ Restaurant'),
            icon=folium.Icon(color='blue', icon='cutlery', prefix='fa')
        ).add_to(m)

    # Add red pins for proposed new H3 cell locations
    for _, row in proposed_locations.iterrows():
        folium.Marker(
            location=[row['latitude'], row['longitude']],
            popup=f"Recommended H3 Cell (Count: {row['restaurant_count']})",
            icon=folium.Icon(color='red', icon='star', prefix='fa')
        ).add_to(m)

    # Save map
    m.save('bbq_opportunity_map.html')
    print('Map saved as bbq_opportunity_map.html')

if __name__ == '__main__':
    main() 