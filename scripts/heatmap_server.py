import duckdb
import folium
from folium.plugins import HeatMap
from http.server import HTTPServer, SimpleHTTPRequestHandler
import os
import json
from typing import List, Tuple
import re

def get_heatmap_data() -> List[Tuple[float, float, float]]:
    """Run the SQL query and return data for the heatmap."""
    conn = duckdb.connect("local.db")
    
    # Install and load H3 extension
    conn.execute("INSTALL h3 FROM community")
    conn.execute("LOAD h3")
    
    # Read and execute the SQL query
    with open("queries/places_by_category_heatmap.sql", "r") as f:
        query = f.read()
    
    # Execute the query and fetch results
    results = conn.execute(query).fetchall()
    
    # Convert H3 hex to lat/lng and create heatmap data
    heatmap_data = []
    for _, h3_hex, count in results:
        # Convert H3 hex to lat/lng
        lat_lng = conn.execute(f"SELECT h3_cell_to_lat({h3_hex}), h3_cell_to_lng({h3_hex})").fetchone()
        if lat_lng:
            lat, lng = lat_lng
            heatmap_data.append((lat, lng, count))
    
    conn.close()
    return heatmap_data

def get_bbq_data() -> List[Tuple[float, float, str]]:
    """Run the BBQ SQL query and return data for the BBQ pins."""
    conn = duckdb.connect("local.db")
    
    # Read and execute the BBQ SQL query
    with open("queries/bbq_places.sql", "r") as f:
        query = f.read()
    
    # Execute the query and fetch results
    results = conn.execute(query).fetchall()
    
    # Create BBQ pin data
    bbq_data = []
    for name, _, lat, lng, _, _ in results:
        if lat is not None and lng is not None:
            bbq_data.append((lat, lng, name))
    
    conn.close()
    return bbq_data

def get_top_hexes() -> List[int]:
    """Run the top_hexes_without_bbq SQL query and return the top 3 hexes as integers."""
    conn = duckdb.connect("local.db")
    with open("queries/top_hexes_without_bbq.sql", "r") as f:
        query = f.read()
    results = conn.execute(query).fetchall()
    conn.close()
    return [row[0] for row in results]

def get_hex_boundaries(hexes: List[int]) -> List[List[Tuple[float, float]]]:
    """Get the boundary coordinates for each hex as a list of (lat, lng) tuples."""
    conn = duckdb.connect("local.db")
    conn.execute("INSTALL h3 FROM community;")
    conn.execute("LOAD 'h3';")
    boundaries = []
    for h in hexes:
        # Get WKT polygon
        result = conn.execute(f"SELECT h3_cell_to_boundary_wkt({h})").fetchone()
        if result and result[0]:
            wkt = result[0]
            # Parse WKT POLYGON ((lng lat, lng lat, ...))
            match = re.match(r"POLYGON \(\((.+)\)\)", wkt)
            if match:
                points = match.group(1).split(", ")
                coords = [(float(latlng.split()[1]), float(latlng.split()[0])) for latlng in points]
                boundaries.append(coords)
    conn.close()
    return boundaries

def create_heatmap(heatmap_data: List[Tuple[float, float, float]], bbq_data: List[Tuple[float, float, str]]):
    m = folium.Map(location=[42.3601, -71.0589], zoom_start=13)
    HeatMap(heatmap_data).add_to(m)
    for lat, lng, name in bbq_data:
        folium.Marker([lat, lng], popup=name, icon=folium.Icon(color='red')).add_to(m)
    # Highlight top 3 hexes
    top_hexes = get_top_hexes()
    hex_boundaries = get_hex_boundaries(top_hexes)
    for boundary in hex_boundaries:
        # Folium expects (lat, lng) tuples
        folium.Polygon(
            locations=boundary,
            color='yellow',
            weight=5,
            fill=True,
            fill_color='yellow',
            fill_opacity=0.3,
            popup='Top non-BBQ hex'
        ).add_to(m)
    m.save("static/heatmap.html")

def run_server():
    """Run a simple HTTP server to serve the heatmap."""
    # Create static directory if it doesn't exist
    os.makedirs("static", exist_ok=True)
    
    # Create the heatmap
    heatmap_data = get_heatmap_data()
    bbq_data = get_bbq_data()
    create_heatmap(heatmap_data, bbq_data)
    
    # Change to the static directory
    os.chdir("static")
    
    # Start the server
    server_address = ("", 8000)
    httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
    print("Server running at http://localhost:8000/heatmap.html")
    httpd.serve_forever()

if __name__ == "__main__":
    run_server() 