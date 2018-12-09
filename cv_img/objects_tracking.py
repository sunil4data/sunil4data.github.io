import cv2

# Try it with live webcam
#cap = cv2.VideoCapture(0)

# Reference sample video can be downloaded from http://www.cvc.uab.es/~bagdanov/master/videos.html
cap = cv2.VideoCapture('./res/car-overhead-1.avi')

frame0_gray = None
while cap.isOpened():

    ret_bool, frame_color = cap.read()

    frame_gray = cv2.cvtColor(frame_color, cv2.COLOR_BGR2GRAY)

    # Gaussian Blur kernel of size 21x21 pixels square to remove noise from the gray frames
    # so that we do not track noise pixels
    frame_gray = cv2.GaussianBlur(frame_gray, (21, 21), 0)

    if frame0_gray is None:
        frame0_gray = frame_gray
        print(frame0_gray.shape)
        continue

    # Absolute difference is used to identify moving object
    # irrespective of background & object being lighter or darker or visa-versa
    frame_delta = cv2.absdiff(frame0_gray, frame_gray)

    # Moving object gray pixel values are 30 points less/more than background
    frame_thresh = cv2.threshold(frame_delta, 30, 255, cv2.THRESH_BINARY)[1]

    # Dilation is effectively MAX POOLING Convolution operation
    # to brighten/glow areas within the reach of kernel size
    # so that CONTOUR operation can collect them together as solid object
    # SIDE NOTE: Erosion is MIN POOLING Convolution to highlight/sharpen the real bright pixels
    frame_thresh = cv2.dilate(frame_thresh, None, iterations=0)

    (_, cntrs, _) = cv2.findContours(frame_thresh.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    for contour in cntrs:
        if cv2.contourArea(contour) < 100:
            continue

        # Show green bounding box around moving object if contour area is 100+ pixel width x length wise
        (x, y, w, h) = cv2.boundingRect(contour)
        cv2.rectangle(frame_color, (x, y), (x+w, y+h), (0, 255, 0), 3)

    # Visualize different frames in their own separate window
    cv2.imshow('Original Color Frame', frame_color)
    cv2.imshow('Captured Gray Frames', frame_gray)
    cv2.imshow('Delta Frames', frame_delta)
    cv2.imshow('Delta Frames Processed', frame_thresh)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()