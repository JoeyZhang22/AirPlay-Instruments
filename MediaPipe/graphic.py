import sys
import time

import cv2
import socket
import struct

import cv2
import MediaPipe.mediapipe_utils as mediapipe_utils
import MediaPipe.opencv_utils as opencv_utils

division_area = mediapipe_utils.Area

# Global variables to calculate FPS
COUNTER, FPS = 0, 0
START_TIME = time.time()
FPS_REFREASH_COUNT = 10

# Create a socket object
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
host_name = socket.gethostname()
host_ip = socket.gethostbyname(host_name)
port = 60003
socket_address = (host_ip, port)
socket_address = (host_ip, port)
try:
    server_socket.bind(socket_address)
    server_socket.listen(5)
    print(f"Listening at {socket_address}")
    client_socket, addr = server_socket.accept()
    print(f"Connection from: {addr}")
except socket.error as e:
    print(f"Error binding or accepting connection: {e}")
    sys.exit(1)



# update FPS on display
def update_fps():
    global FPS, COUNTER, START_TIME, FPS_REFREASH_COUNT

    # Calculate the FPS
    if COUNTER % FPS_REFREASH_COUNT == 0:
        COUNTER = 0
        FPS = FPS_REFREASH_COUNT / (time.time() - START_TIME)
        START_TIME = time.time()

    COUNTER += 1


def populate_strum_names(names):
    names.append("Strum up")
    names.append("Neutral")
    names.append("Strum down")


def populate_chord_names(names):
    names.append("Major")
    names.append("Minor")
    names.append("Special")

def populate_percersive_names(corner_names, top_circle_names, bottom_circle_names):
    # Top Corners
    corner_names.append("Crash")
    corner_names.append("Ride")

    # Bottom Corners
    corner_names.append("High-Hat")
    corner_names.append("Low Tom")

    # Top Circles
    top_circle_names.append("High Tom")
    top_circle_names.append("Mid Tom")

    # Bottom Circles
    bottom_circle_names.append("Snare")
    bottom_circle_names.append("Bass")


def define_areas(handedness, instrument_type):
    """
    For now, the screen is divided to 6 parts by default:
      Top-left:     Strum up
      Mid-left:     Neutral
      Bottom-left:  Strum down

      Top-right:     Major
      Mid-right:     Minor
      Bottom-right:  Special
    """
    areas = []

    if instrument_type is "Expressive":
        # define area names based on handedness, the prefered hand will be used for strum area
        left_areas = []
        right_areas = []

        if handedness == "left":
            populate_strum_names(left_areas)
            populate_chord_names(right_areas)
        else:
            populate_strum_names(right_areas)
            populate_chord_names(left_areas)

        # initialize expressive areas, for dimension we use normalized values to match results from the recognizer
        left_stride = 1 / len(left_areas)
        for i in range(len(left_areas)):
            areas.append(
                division_area(
                    left_areas[i], "Rectangle", 0, 0 + left_stride * i, 0.5, left_stride * (i + 1)
                )
            )

        right_stride = 1 / len(right_areas)
        for i in range(len(right_areas)):
            areas.append(
                division_area(
                    right_areas[i], "Rectangle", 0.5, 0 + right_stride * i, 1, right_stride * (i + 1)
                )
            )
    else:
        # define area names for percussion areas
        corner_areas = []
        top_circle_areas = []
        bottom_circle_areas = []

        populate_percersive_names(corner_areas, top_circle_areas, bottom_circle_areas)

        # initialize percussion areas, for dimension we use normalized values to match results from the recognizer
        stride = 1 / (len(top_circle_areas) + 2)

        # define corner areas
        areas.append(
                division_area(
                    corner_areas[0], "Corner", radius = stride, center=(0, 0)
                )
            )
        areas.append(
                division_area(
                    corner_areas[1], "Corner", radius = stride, center=(1, 0)
                )
            )
        
        areas.append(
                division_area(
                    corner_areas[2], "Corner", radius = stride, center=(0, 1)
                )
            )
        areas.append(
                division_area(
                    corner_areas[3], "Corner", radius = stride, center=(1, 1)
                )
            )
     
        # define circle areas
        circle_ratio = 0.5
        for i in range(len(top_circle_areas)):
            areas.append(
                division_area(
                    top_circle_areas[i], "Circle", radius = stride*circle_ratio, center=((i+1.5) * stride, stride*circle_ratio)
                )
            )

        for i in range(len(bottom_circle_areas)):
            areas.append(
                division_area(
                    bottom_circle_areas[i], "Circle", radius = stride*circle_ratio, center=((i+1.5) * stride, 1 - stride*circle_ratio)
                )
            )

    return areas


def run_graphic(
    model: str,
    num_hands: int,
    min_hand_detection_confidence: float,
    min_hand_presence_confidence: float,
    min_tracking_confidence: float,
    camera_id: int,
    width: int,
    height: int,
    sync: bool,
    result_queue,
    result_event,
    handedness,
    instrument_type,
) -> None:
    """Continuously run inference on images acquired from the camera.

    Args:
        model: Name of the gesture recognition model bundle.
        num_hands: Max number of hands can be detected by the recognizer.
        min_hand_detection_confidence: The minimum confidence score for hand detection
                                        to be considered successful.
        min_hand_presence_confidence: The minimum confidence score of hand presence score
                                      in the hand landmark detection.
        min_tracking_confidence: The minimum confidence score for the hand tracking to be
                                  considered successful.
        camera_id: The camera id to be passed to OpenCV.
        width: The width of the frame captured from the camera.
        height: The height of the frame captured from the camera.
    """
    # Init camera
    camera = opencv_utils.open_camera(camera_id, width, height)

    recognition_frame = None
    recognition_result_list = []

    # Init recognizer
    recognizer = mediapipe_utils.Recognizer(
        model,
        num_hands,
        min_hand_detection_confidence,
        min_hand_presence_confidence,
        min_tracking_confidence,
    )

    # Define areas
    areas = define_areas(handedness, instrument_type)

    # Continuously capture images from the camera and run inference
    while camera.isOpened():
        success, image = camera.read()
        if not success:
            sys.exit(
                "ERROR: Unable to read from webcam. Please verify your webcam settings."
            )

        image = cv2.flip(image, 1)
        # Convert the image from BGR to RGB as required by the TFLite model.
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # Run gesture recognizer using the model asynchrnously.
        if sync:
            recognizer.run_sync(rgb_image)
        else:
            recognizer.run_async(rgb_image, time.time_ns() // 1_000_000)

        # Get the recognized output
        recognition_result_list = recognizer.get_recognized_output(areas)

        # Show the FPS
        current_frame = image
        #opencv_utils.draw_fps(current_frame, FPS)

        # Draw the divison lines
        opencv_utils.draw_division_lines(current_frame, areas)

        for recognition_result in recognition_result_list:
            if not recognition_result:
                continue
            update_fps()
            opencv_utils.draw_gesture_labels(recognition_result, current_frame)

            # Temp: remoe gesture_landmarks from result
            recognition_result[0].pop("Gesture_Landmarks")
            if len(recognition_result) > 1:
                recognition_result[1].pop("Gesture_Landmarks")

            result_queue.put(recognition_result)
            result_event.set()

        recognition_frame = current_frame
        recognition_result_list.clear()

        # Diplay the frame on window with labelling
        if recognition_frame is not None:
            # Standarize resolution
            resized_frame = cv2.resize(recognition_frame, (1440, 900))
            # cv2.imshow("gesture_recognition", resized_frame)

            # Compress the frame into JPEG format (adjust quality as needed)
            encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]  # Quality from 0 to 100
            _, buffer = cv2.imencode('.jpg', resized_frame, encode_param)

            # Pack the length of the compressed data
            message_size = struct.pack("L", len(buffer))

            # Send the message size and the compressed frame data
            client_socket.sendall(message_size + buffer.tobytes())

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        # Stop the program if the ESC key is pressed.
        if cv2.waitKey(1) == 27:
            break

    # Destruction upon exit
    recognizer.close()
    camera.release()
    cv2.destroyAllWindows()