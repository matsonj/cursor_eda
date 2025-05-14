import pandas as pd
import folium
from folium.plugins import HeatMap
from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

# Read the CSV file
df = pd.read_csv('results.csv')

# Create a map centered at the mean latitude and longitude
center_lat = df['latitude'].mean()
center_lon = df['longitude'].mean()
m = folium.Map(location=[center_lat, center_lon], zoom_start=13)

# Prepare data for the heatmap
heat_data = [[row['latitude'], row['longitude']] for _, row in df.iterrows()]

# Add the heatmap layer
HeatMap(heat_data).add_to(m)

# Save the map to an HTML file
m.save('restaurant_map.html')

# Serve the map using Python's built-in HTTP server
class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.getcwd(), **kwargs)

httpd = HTTPServer(('localhost', 8000), Handler)
print("Serving at http://localhost:8000/restaurant_map.html")
httpd.serve_forever() 