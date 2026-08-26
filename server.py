from http.server import BaseHTTPRequestHandler, HTTPServer

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            message = "Hello Finzla Technologies Nigeria Limited!"
            
        elif self.path == "/health":
            message = "200 OK"
    
        elif self.path == "/version":
            message = "Version: 1.0"
        
        else:
            self.send_response(404)
            self.end_headers()
            return
        
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
                    
        self.wfile.write(message.encode())
        
        
server = HTTPServer(("0.0.0.0", 8000), MyHandler)
print("Server running on port 8000...")

server.serve_forever()       