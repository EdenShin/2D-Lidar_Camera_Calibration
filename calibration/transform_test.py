import numpy as np
import cv2

DELTA = np.matrix([-27.3456,-24.4341,-100.7541]).T
PHI = np.matrix([[0.9995, 0.0165, -0.0268], [0.0154,-0.9990,-0.0421], [-0.0275,0.0417,-0.9988]])
K = np.array([0.1335, -0.2579, -0.0037, 0.0005, 0])
C = np.array([326.405476764440830, 235.055227337685270])
F = np.array([472.684529357136970, 633.367424121568890])

def getImage(imgname):
	img = cv2.imread(imgname)
	return img

def readBin(file):
  points = np.empty([4,0]) 
  with open(file, mode='rb') as f:
    data = np.fromfile(f, dtype=np.float32)
    #print(data.shape)
    points = np.reshape(data, (-1,4))
    #print(points)    
  return points

def Point2Img(img, points):
	# delete background points
	print len(points)
	i = 0
	while True:
		if i == len(points)-1:
			break
		if points[i][0] > 0:
			points = np.delete(points, i, 0)
			i = i - 1
		i = i + 1
	print len(points)

	#start transform
	pts = points.T
	pts = np.matrix([pts[1], pts[2], pts[0]])
	pts = pts * 1000

	invphi = np.linalg.inv(PHI)
	#print invphi

	cpts = np.dot(invphi, pts) + DELTA
	#print cpts

	xc = cpts[0]
	#print xc
	yc = cpts[1]
	zc = cpts[2]

	a = xc / zc
	#print a
	b = yc / zc
	#print np.shape(a), np.shape(b)

	r = np.sqrt(np.power(a, 2) + np.power(b, 2))
	#print r

	ad = np.multiply(a, (1 + np.multiply(K[0], np.power(r, 2)) + np.multiply(K[1], np.power(r, 4)) + np.multiply(K[4], np.power(r, 6)))) 
	+ 2 * K[2] * np.multiply(a, b) + K[3] * (np.power(r, 2) + 2 * np.power(a, 2))
	bd = np.multiply(b, (1 + np.multiply(K[0], np.power(r, 2)) + np.multiply(K[1], np.power(r, 4)) + np.multiply(K[4], np.power(r, 6))))
	+ K[2] * (np.power(r, 2) + 2 * np.power(b, 2)) + 2 * K[3] * np.multiply(a, b)

	x = F[0] * a + C[0];
	y = F[1] * b + C[1];
	for i in range(np.shape(x)[1]):
		if x[0, i] >= 0 and x[0, i] < 640 and y[0, i] >=0 and y[0, i] < 480:
			img = cv2.circle(img, (int(round(x[0, i])), int(round(y[0, i]))), 3, (255, 0, 0), -1)
	cv2.imshow('img', img)
	cv2.waitKey(0)
	cv2.destroyAllWindows()

img = getImage('data4.jpg')
pts = readBin('lidar40.bin')
Point2Img(img, pts)