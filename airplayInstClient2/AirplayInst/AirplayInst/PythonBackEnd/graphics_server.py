import cv2
import socket
import struct
import threading
import queue
import time

# Create a socket object
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
host_name = socket.gethostname()
host_ip = socket.gethostbyname(host_name)
port = 60003
socket_address = (host_ip, port)
server_socket.bind(socket_address)
server_socket.listen(5)
print(f"Listening at {socket_address}")
client_socket, addr = server_socket.accept()
print(f"Connection from: {addr}")

# OpenCV video capture
cap = cv2.VideoCapture(0)

while cap.isOpened():
    print("I am listening")
    ret, frame = cap.read()
    if not ret:
        break

    # Compress the frame into JPEG format (adjust quality as needed)
    encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]  # Quality from 0 to 100
    _, buffer = cv2.imencode('.jpg', frame, encode_param)

    # Pack the length of the compressed data
    message_size = struct.pack("L", len(buffer))

    # Send the message size and the compressed frame data
    client_socket.sendall(message_size + buffer.tobytes())

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release resources
cap.release()
cv2.destroyAllWindows()
client_socket.close()
server_socket.close()