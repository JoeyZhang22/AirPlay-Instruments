import sys
import time

import socket
import struct

import cv2
import MediaPipe.mediapipe_utils as mediapipe_utils
import MediaPipe.opencv_utils as opencv_utils

division_area = mediapipe_utils.Area

# TESTER
TEST_ENABLED = True

# Global variables to calculate FPS
COUNTER, FPS = 0, 0
START_TIME = time.time()
FPS_REFREASH_COUNT = 15

# Create a socket object
if TEST_ENABLED != True:
    print("here")
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    host_name = socket.gethostname()
    host_ip = '127.0.0.1'
    port = 60003
    socket_address = (host_ip, port)
    server_socket.bind(socket_address)
    server_socket.listen(5)
    print(f"Listening at {socket_address}")
    client_socket, addr = server_socket.accept()
    print(f"Connection from: {addr}")

# update FPS on display
def update_fps():
    global FPS, COUNTER, START_TIME, FPS_REFREASH_COUNT

    # Calculate the FPS
    if COUNTER % FPS_REFREASH_COUNT == 0:
        COUNTER = 0
        FPS = FPS_REFREASH_COUNT / (time.time() - START_TIME)
        START_TIME = time.time()

def increment_fps():
    global COUNTER
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
    corner_names.append("Crash Right")
    corner_names.append("Ride Bell")

    # Bottom Corners
    corner_names.append("Hi-Hat Open")
    corner_names.append("Tom Low")

    # Top Circles
    top_circle_names.append("Tom Mid High")
    top_circle_names.append("Tom High")

    # Bottom Circles
    bottom_circle_names.append("Snare Center")
    bottom_circle_names.append("Kick")

def populate_percersive_names_rect(top_names, bottom_names):
    # Top Corners
    top_names.append("Crash Right")
    top_names.append("Tom High")
    top_names.append("Tom Mid High")
    top_names.append("Ride Bell")

    # Bottom Circles
    bottom_names.append("Hi-Hat Open")
    bottom_names.append("Snare Center")
    bottom_names.append("Kick")
    bottom_names.append("Tom Low")

def define_areas(handedness, instrument_type, name_list=['Dominant7', 'Major', 'Minor']): #removed name_list variable because chord matrix is not implemented on gui yet
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

    if instrument_type == "Chord":
        # define area names based on handedness, the prefered hand will be used for strum area
        left_areas = []
        right_areas = []

        if handedness == "left":
            populate_strum_names(left_areas)
            right_areas = name_list
        else:
            populate_strum_names(right_areas)
            left_areas = name_list

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
    elif instrument_type == "Expressive":
        # define area names based on handedness, the prefered hand will be used for strum area
        left_areas = name_list

        left_stride = 1 / len(left_areas)
        for i in range(len(left_areas)):
            areas.append(
                division_area(
                    left_areas[i], "Rectangle", 0, 0 + left_stride * i, 0.4, left_stride * (i + 1)
                )
            )

        # Define right area which will later be used to manipulate the expression
        manipulate_area_name = 'Manipulation'
        areas.append(
            division_area(
                manipulate_area_name, "Rectangle", 0.4, 0, 1, 1
            )
        )
    else:
        # define area names based on handedness, the prefered hand will be used for strum area
        top_areas = []
        bottom_areas = []

        populate_percersive_names_rect(top_areas, bottom_areas)

        # Percusiion area parameters
        percussion_area_type = "Rectangle"
        box_height = 0.25
        top_areas_initial_height = 0.25
        bottom_areas_initial_height = 1 - box_height

        # initialize expressive areas, for dimension we use normalized values to match results from the recognizer
        top_stride = 1 / len(top_areas)
        for i in range(len(top_areas)):
            if i == 0 or i == len(top_areas)-1:
                areas.append(
                    division_area(
                        top_areas[i],
                        percussion_area_type,
                        top_stride * i,
                        top_areas_initial_height + box_height,
                        top_stride * (i + 1), 
                        top_areas_initial_height + box_height + box_height,
                        instrument_type=instrument_type
                    )
                )
            else:
                areas.append(
                    division_area(
                        top_areas[i],
                        percussion_area_type,
                        top_stride * i,
                        top_areas_initial_height,
                        top_stride * (i + 1), 
                        top_areas_initial_height + box_height,
                        instrument_type=instrument_type
                    )
                )

        bottom_stride = 1 / len(bottom_areas)
        for i in range(len(bottom_areas)):
            areas.append(
                division_area(
                    bottom_areas[i], 
                    percussion_area_type, 
                    bottom_stride * i, 
                    bottom_areas_initial_height, 
                    bottom_stride * (i + 1), 
                    bottom_areas_initial_height + box_height,
                    instrument_type=instrument_type
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
    chord_list,
    area_list,
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
    areas = define_areas(handedness, instrument_type, name_list=area_list)

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
        opencv_utils.draw_fps(current_frame, FPS)

        # Draw the divison lines
        opencv_utils.draw_division_lines(current_frame, areas, instrument_type=="Expressive")

        for recognition_result in recognition_result_list:
            if not recognition_result:
                continue

            increment_fps()
            update_fps()
            opencv_utils.draw_gesture_labels(recognition_result, current_frame)

            # Temp: remove gesture_landmarks from result
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
            current_resolution = (1440, 900)
            resized_frame = cv2.resize(recognition_frame, current_resolution)
            if TEST_ENABLED:
                cv2.imshow("gesture_recognition", resized_frame)
            else:
                # Compress the frame into JPEG format (adjust quality as needed)
                encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]  # Quality from 0 to 100
                _, buffer = cv2.imencode('.jpg', resized_frame, encode_param)

                # Pack the length of the compressed data
                message_size = struct.pack("L", len(buffer))

                # Send the message size and the compressed frame data
                client_socket.sendall(message_size + buffer.tobytes())

        # Read the key input
        key = cv2.waitKey(1)
        if key == 27:       # Press ESC to close the graphic module
            break
        elif key == 113:    # Press Q to switch instrument types
            instrument_type = "Chord" if instrument_type == "Percussion" else "Percussion"
            # Update areas to match new areas
            areas = define_areas(handedness, instrument_type, chord_list)

    # Destruction upon exit
    recognizer.close()
    camera.release()
    cv2.destroyAllWindows()