"""
Reads restaurant data for Oakland, CA from DuckDB,
creates a Folium map with opportunity areas, and serves it via a simple HTTP server.
"""

import duckdb
import pandas as pd
import folium
from folium.plugins import HeatMap
from pathlib import Path
import http.server
import socketserver
import threading
import time

DB_PATH = "local.db"
QUERY_PATH = "queries/get_area_restaurants.sql"
OUTPUT_DIR = Path("maps")
OUTPUT_HTML = OUTPUT_DIR / "oakland_restaurants.html"
SERVER_PORT = 8001

# Define opportunity areas with their bounds (approx 200m radius)
OPPORTUNITY_AREAS = [
    {
        "name": "Area 1 - West Oakland",
        "center": [37.799492498768515, -122.21672065064652],
        "color": "red",
        "radius": 0.002  # roughly 200 meters
    },
    {
        "name": "Area 2 - Fruitvale",
        "center": [37.75229016864812, -122.20010322109415],
        "color": "blue",
        "radius": 0.002
    },
    {
        "name": "Area 3 - East Oakland",
        "center": [37.74898280157442, -122.17422593980609],
        "color": "green",
        "radius": 0.002
    }
]

def fetch_data(db_path: str, query_path: str) -> pd.DataFrame:
    """Fetches data from DuckDB using the specified query file."""
    query = Path(query_path).read_text()
    conn = duckdb.connect(db_path)
    conn.execute("LOAD spatial;")  # Load spatial extension
    df = conn.execute(query).fetchdf()
    conn.close()
    return df

def create_map(df: pd.DataFrame, output_path: Path):
    """Creates a Folium map with opportunity areas and their restaurants."""
    # Center the map roughly on Oakland
    map_center = [37.8044, -122.2711]
    oakland_map = folium.Map(location=map_center, zoom_start=12)

    # Add opportunity areas
    for area in OPPORTUNITY_AREAS:
        # Create a circle for the area
        folium.Circle(
            location=area["center"],
            radius=200,  # meters
            color=area["color"],
            fill=True,
            fillOpacity=0.2,
            popup=area["name"],
            weight=3
        ).add_to(oakland_map)

        # Add a label
        folium.Popup(
            area["name"],
            parse_html=True
        ).add_to(folium.Marker(
            location=area["center"],
            icon=folium.DivIcon(
                html=f'<div style="font-size: 14px; font-weight: bold; color: {area["color"]}">{area["name"]}</div>'
            )
        )).add_to(oakland_map)

        # Add restaurants for this area
        area_restaurants = df[df["area_number"] == OPPORTUNITY_AREAS.index(area) + 1]
        for _, restaurant in area_restaurants.iterrows():
            # Handle category labels - they come as numpy arrays
            categories = [cat for cat in restaurant['fsq_category_labels'] if isinstance(cat, str)]
            popup_content = f"{restaurant['name']}<br>{', '.join(categories)}"
            
            folium.CircleMarker(
                location=[restaurant["latitude"], restaurant["longitude"]],
                radius=6,
                color=area["color"],
                fill=True,
                popup=popup_content,
                weight=2
            ).add_to(oakland_map)

    # Add a heatmap layer of all restaurants with lower opacity
    heat_data = [[row['latitude'], row['longitude']] for idx, row in df.iterrows()]
    HeatMap(
        heat_data,
        radius=15,
        blur=10,
        max_zoom=13,
        min_opacity=0.3
    ).add_to(oakland_map)

    # Add a legend
    legend_html = """
    <div style="position: fixed; bottom: 50px; right: 50px; z-index: 1000; background-color: white; 
                padding: 10px; border: 2px solid grey; border-radius: 5px">
    <h4>Opportunity Areas</h4>
    """
    for area in OPPORTUNITY_AREAS:
        legend_html += f"""
        <p>
            <span style="color: {area['color']};">●</span>
            {area['name']}
        </p>
        """
    legend_html += "</div>"
    oakland_map.get_root().html.add_child(folium.Element(legend_html))

    # Save the map
    output_path.parent.mkdir(parents=True, exist_ok=True)
    oakland_map.save(str(output_path))
    print(f"Map saved to {output_path}")

def start_server(port: int, directory: str = "."):
    """Starts a simple HTTP server in a separate thread."""
    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=directory, **kwargs)

    httpd = socketserver.TCPServer(("", port), Handler)
    print(f"Serving HTTP on port {port} from directory '{directory}'")
    print(f"Open http://localhost:{port}/{OUTPUT_HTML.name} in your browser.")
    httpd.serve_forever()

if __name__ == "__main__":
    print("Fetching restaurant data...")
    data_df = fetch_data(DB_PATH, QUERY_PATH)
    print(f"Fetched {len(data_df)} restaurants.")

    if not data_df.empty:
        print("Creating map...")
        create_map(data_df, OUTPUT_HTML)

        print("Starting server...")
        server_thread = threading.Thread(
            target=start_server, args=(SERVER_PORT, OUTPUT_DIR.name)
        )
        server_thread.daemon = True
        server_thread.start()

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nShutting down server...") 