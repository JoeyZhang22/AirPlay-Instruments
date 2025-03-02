import cv2
import socket
import struct
import numpy as np

def receive_frames(host, port):
    # Create a socket object
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Connect to the server
    client_socket.connect((host, port))
    print(f"Connected to server at {host}:{port}")

    try:
        while True:
            # Receive the size of the incoming frame
            message_size_data = client_socket.recv(8)
            if not message_size_data:
                break

            # Unpack the message size
            message_size = struct.unpack("L", message_size_data)[0]

            # Receive the frame data
            frame_data = b""
            while len(frame_data) < message_size:
                packet = client_socket.recv(message_size - len(frame_data))
                if not packet:
                    break
                frame_data += packet

            # Decode the frame
            frame = cv2.imdecode(np.frombuffer(frame_data, dtype=np.uint8), cv2.IMREAD_COLOR)
            if frame is None:
                print("Failed to decode frame")
                continue

            # Display the frame
            cv2.imshow("Received Frame", frame)

            # Break the loop if 'q' is pressed
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    finally:
        # Release resources
        client_socket.close()
        cv2.destroyAllWindows()
        print("Connection closed")

if __name__ == "__main__":
    import argparse

    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Python client to receive OpenCV frames from a server.")
    parser.add_argument("--host", type=str, default="localhost", help="Server host (default: localhost)")
    parser.add_argument("--port", type=int, default=60004, help="Server port (default: 60003)")
    args = parser.parse_args()

    # Start receiving frames
    receive_frames(args.host, args.port)