#!/usr/bin/env python3

from http.server import HTTPServer, SimpleHTTPRequestHandler
import os
from pathlib import Path

def main():
    # Change to the output directory
    os.chdir(Path('output'))
    
    # Create server
    server_address = ('', 8000)
    httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
    
    print("Serving map at http://localhost:8000/snohomish_restaurants_map.html")
    print("Press Ctrl+C to stop the server")
    
    # Start server
    httpd.serve_forever()

if __name__ == "__main__":
    main() 