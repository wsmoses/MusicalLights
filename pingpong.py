import socket
from time import sleep

UDP_IP="10.42.0.109"
UDP_PORT = 8080
sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
llen = 600
speed = 5


test = [255, 0, 0] + [0]*3*(llen-1)
test_hex = ''.join('{:02x}'.format(x) for x in test)
sock.sendto(bytes.fromhex(test_hex), (UDP_IP, UDP_PORT))

def broadcast(hex_list):
	test_hex = ''.join('{:02x}'.format(x) for x in hex_list)
	sock.sendto(bytes.fromhex(test_hex), (UDP_IP, UDP_PORT))

while True:
	for dec in range(3):
		inc = 0 if dec == 2 else dec + 1
		for x in range(255 // speed):
			test.pop()
			test.pop()
			test.pop()
			old = test[0:3]
			old[inc] += speed
			old[dec] -= speed
			test = old + test
			broadcast(test)
			sleep(0.05)
