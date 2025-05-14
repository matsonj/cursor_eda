import duckdb

def setup_spatial_extension():
    """Install and load the spatial extension in DuckDB."""
    conn = duckdb.connect("local.db")
    conn.execute("INSTALL spatial;")
    conn.execute("LOAD spatial;")
    conn.close()
    print("Spatial extension installed and loaded successfully.")

if __name__ == "__main__":
    setup_spatial_extension() 