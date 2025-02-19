import socket
import time
import sys

def main(target_address):
    # Create a TCP/IP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Connect the socket to the target address
    sock.connect(target_address)

    total_data = 0
    start_time = time.time()

    try:
        while True:
            data = sock.recv(4096)
            if not data:
                break
            total_data += len(data)

            current_time = time.time()
            elapsed_time = current_time - start_time

            if elapsed_time >= 0.2:  # 5Hz frequency
                # Calculate the data rate in Mbit/s
                data_rate = (total_data * 8) / (elapsed_time * 1_000_000)
                print(f"Data rate: {data_rate:.2f} Mbit/s")

                # Reset counters
                total_data = 0
                start_time = current_time

    finally:
        sock.close()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python bandwidth.py <ip> <port>")
        sys.exit(1)

    target_address = (sys.argv[1], int(sys.argv[2]))
    main(target_address)