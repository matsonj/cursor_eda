#!/usr/bin/env python3

import duckdb
import folium
from folium.plugins import MarkerCluster, HeatMap
import pandas as pd
from pathlib import Path
import ast

def get_color(bbq_type):
    """Return a color based on BBQ type."""
    color_map = {
        'Confirmed BBQ': 'red',
        'Potential BBQ': 'orange',
        'BBQ-Related': 'blue'
    }
    return color_map.get(bbq_type, 'gray')

def format_categories(categories_str):
    """Format categories list, handling DuckDB array types."""
    if not categories_str or categories_str == '[]':
        return "No categories available"
    try:
        # Convert string representation of array to actual list
        categories = ast.literal_eval(categories_str)
        return ', '.join(categories)
    except:
        return str(categories_str)

def main():
    # Connect to the database
    conn = duckdb.connect('local.db')

    # Load the spatial extension
    conn.execute("INSTALL spatial; LOAD spatial;")

    # Get business density data
    density_query = """
    SELECT 
        latitude,
        longitude,
        COUNT(*) OVER (
            ORDER BY latitude, longitude 
            ROWS BETWEEN 100 PRECEDING AND 100 FOLLOWING
        ) as weight
    FROM places
    WHERE 
        region = 'WA' 
        AND locality IN (
            'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
            'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
            'Bothell', 'Mill Creek', 'Snohomish'
        )
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL
        AND ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant');
    """
    density_df = conn.execute(density_query).df()

    # Read and execute the SQL query for BBQ restaurants
    bbq_query = """
    SELECT 
        name,
        address,
        locality,
        region,
        postcode,
        latitude,
        longitude,
        fsq_category_labels,
        CASE 
            WHEN ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > BBQ Joint') THEN 'Confirmed BBQ'
            WHEN ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant > Southern Restaurant') THEN 'Potential BBQ'
            ELSE 'BBQ-Related'
        END as bbq_type
    FROM places
    WHERE 
        region = 'WA' 
        AND locality IN (
            'Everett', 'Lynnwood', 'Marysville', 'Edmonds', 
            'Mukilteo', 'Arlington', 'Monroe', 'Lake Stevens', 
            'Bothell', 'Mill Creek', 'Snohomish'
        )
        AND ARRAY_CONTAINS(fsq_category_labels, 'Dining and Drinking > Restaurant')
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
        );
    """
    bbq_df = conn.execute(bbq_query).df()

    # Get potential locations data
    potential_locations_query = """
    WITH restaurant_areas AS (
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
        HAVING COUNT(*) >= 5
    )
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
    """
    potential_locations_df = conn.execute(potential_locations_query).df()

    # Create output directory if it doesn't exist
    output_dir = Path('output')
    output_dir.mkdir(exist_ok=True)

    # Create a base map centered on Snohomish County
    map_center = [48.0336, -122.0333]  # Approximate center of Snohomish County
    m = folium.Map(location=map_center, zoom_start=10)

    # Add the heatmap layer
    heat_data = [[row['latitude'], row['longitude'], row['weight']] for idx, row in density_df.iterrows()]
    HeatMap(
        heat_data,
        radius=15,
        blur=20,
        max_zoom=1,
        name='Restaurant Density'
    ).add_to(m)

    # Create separate marker clusters for each BBQ type
    clusters = {
        'Confirmed BBQ': MarkerCluster(name='Confirmed BBQ Restaurants').add_to(m),
        'Potential BBQ': MarkerCluster(name='Potential BBQ Restaurants').add_to(m),
        'BBQ-Related': MarkerCluster(name='BBQ-Related Establishments').add_to(m)
    }

    # Add markers for each restaurant
    for idx, row in bbq_df.iterrows():
        # Create popup content
        popup_content = f"""
        <b>{row['name']}</b><br>
        {row['address'] if row['address'] else 'No address available'}<br>
        {row['locality']}, {row['region']} {row['postcode']}<br>
        Type: {row['bbq_type']}<br>
        Categories: {format_categories(str(row['fsq_category_labels']))}
        """
        
        # Add marker to the appropriate cluster
        folium.Marker(
            location=[row['latitude'], row['longitude']],
            popup=folium.Popup(popup_content, max_width=300),
            tooltip=f"{row['name']} ({row['bbq_type']})",
            icon=folium.Icon(color=get_color(row['bbq_type']))
        ).add_to(clusters[row['bbq_type']])

    # Add potential locations as bounded boxes
    potential_locations_layer = folium.FeatureGroup(name='Recommended Locations')
    
    for idx, row in potential_locations_df.iterrows():
        # Create a bounding box around the center point
        # Using 0.01 degrees for the box size (approximately 1km)
        lat_min = row['center_lat'] - 0.01
        lat_max = row['center_lat'] + 0.01
        lon_min = row['center_lon'] - 0.01
        lon_max = row['center_lon'] + 0.01
        
        # Create popup content
        popup_content = f"""
        <b>{row['locality']} Area {idx + 1}</b><br>
        Total Restaurants: {row['total_restaurants']}<br>
        Notable Restaurants: {row['other_restaurants'].split(',')[0]}, {row['other_restaurants'].split(',')[1]}
        """
        
        # Add the rectangle to the map
        folium.Rectangle(
            bounds=[[lat_min, lon_min], [lat_max, lon_max]],
            color='#FF7F00',
            fill=True,
            fill_color='#FF7F00',
            fill_opacity=0.2,
            weight=2,
            popup=folium.Popup(popup_content, max_width=300)
        ).add_to(potential_locations_layer)
    
    potential_locations_layer.add_to(m)

    # Add layer control
    folium.LayerControl().add_to(m)

    # Save the map
    output_path = output_dir / 'snohomish_restaurants_map.html'
    m.save(str(output_path))
    print(f"Map has been created and saved to {output_path}")

if __name__ == "__main__":
    main() 