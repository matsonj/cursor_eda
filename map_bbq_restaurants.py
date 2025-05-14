import pandas as pd
import folium
from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

# Read the CSV file
df = pd.read_csv('bbq_results.csv')

# Create a map centered at the mean latitude and longitude
center_lat = df['latitude'].mean()
center_lon = df['longitude'].mean()
m = folium.Map(location=[center_lat, center_lon], zoom_start=13)

# Add markers for each BBQ restaurant
for _, row in df.iterrows():
    folium.Marker(
        location=[row['latitude'], row['longitude']],
        popup=row['name'],
        tooltip=row['name']
    ).add_to(m)

# Save the map to an HTML file
m.save('bbq_restaurant_map.html')

# Serve the map using Python's built-in HTTP server
class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.getcwd(), **kwargs)

httpd = HTTPServer(('localhost', 8000), Handler)
print("Serving at http://localhost:8000/bbq_restaurant_map.html")
httpd.serve_forever() 