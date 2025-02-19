import socket
import cv2
import numpy as np
import sys
import time

def receive_image(sock, buffer):
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            break
        buffer += chunk
        if b'\xff\xd9' in buffer:
            break

    end_index = buffer.find(b'\xff\xd9') + 2
    image_data = buffer[:end_index]
    buffer = buffer[end_index:]

    return image_data, buffer

def main(server_address):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(server_address)
    buffer = b''
    total_rev_data_size = 0
    frame_counter = 0
    start_time = time.time()

    try:
        while True:
            image_data, buffer = receive_image(sock, buffer)
            total_rev_data_size += len(image_data)
            frame_counter += 1
            cur_time = time.time()
            time_diff = cur_time - start_time
            print(f"Recv speed: {total_rev_data_size * 8 / time_diff / 1_000_000:.2f} Mbit/s, {frame_counter / time_diff:.2f} fps", end='\r')
            if cur_time - start_time >= 5:
                frame_counter = 0
                total_rev_data_size = 0
                start_time = cur_time

            image = cv2.imdecode(np.frombuffer(image_data, np.uint8), cv2.IMREAD_COLOR)

            if image is not None:
                cv2.imshow('Received Image', image)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
            else:
                print("Error decoding image")
    finally:
        sock.close()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python play.py <ip> <port>")
        sys.exit(1)

    server_address = (sys.argv[1], int(sys.argv[2]))
    main(server_address)