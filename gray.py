from scipy import ndimage
import numpy as np
import matplotlib.pyplot as plt
import time
import struct
a = ndimage.imread('cat.jpg',mode = 'RGB')
def rgb2gray(rgb):

    r, g, b = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b

    return gray

gray = rgb2gray(a)
gray2 = gray.T.flatten()
gray2 = [int(i) for i in gray2]
import serial



ser = serial.Serial('/dev/ttyUSB0', 115200)  # open serial port
gray3= [chr(i) for i in gray2]
    #Open named port 
mystr = ''
for i in  gray3:
    mystr += i

ser.baudrate = 115200 
g=0
#f =ser.write(mystr.encode())
#print(f)
for i in gray2:
    ff = ser.write(struct.pack('B',i))
    g+=1    
    print(g,i, ff)
#    time.sleep(5)

    #Send back the received data
ser.close()        
