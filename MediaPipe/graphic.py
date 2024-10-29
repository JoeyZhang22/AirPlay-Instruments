import sys
import time

import cv2
import mediapipe_utils
import opencv_utils

division_area = mediapipe_utils.Area

# Global variables to calculate FPS
COUNTER, FPS = 0, 0
START_TIME = time.time()
FPS_REFREASH_COUNT = 10


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
    names.append("Strump down")

def populate_chord_names(names):
    names.append("Major")
    names.append("Minor")
    names.append("Special")

def define_areas(handedness):
    """
    For now, the screen is divided to 6 parts:
      Top-left:     Strum up
      Mid-left:     Neutral
      Bottom-left:  Strump down

      Top-right:     Major
      Mid-right:     Minor
      Bottom-right:  Special
    """
    # define area names based on handedness, the prefered hand will be used for strum area
    left_areas = []
    right_areas = []
    if handedness is "left":
        populate_strum_names(left_areas)
        populate_chord_names(right_areas)
    else:
        populate_strum_names(right_areas)
        populate_chord_names(left_areas)

    # initialize areas, for dimension we use normalized values to match results from the recognizer
    areas = []
    left_stride = 1/len(left_areas)
    for i in range(len(left_areas)):
        areas.append(division_area(left_areas[i], 0, 0 + left_stride * i, 0.5, left_stride * (i + 1)))

    right_stride = 1/len(right_areas)
    for i in range(len(right_areas)):
        areas.append(division_area(right_areas[i], 0.5, 0 + right_stride * i, 1, right_stride * (i + 1)))

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
    areas = define_areas(handedness)

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
        opencv_utils.draw_division_lines(current_frame, areas)

        for recognition_result in recognition_result_list:
            if not recognition_result:
                continue
            update_fps()
            opencv_utils.draw_gesture_labels(recognition_result, current_frame)
            result_queue.put(recognition_result)
            result_event.set()

        recognition_frame = current_frame
        recognition_result_list.clear()

        # Diplay the frame on window with labelling
        if recognition_frame is not None:
            # Standarize resolution
            resized_frame = cv2.resize(recognition_frame, (1440, 900))
            cv2.imshow("gesture_recognition", resized_frame)

        # Stop the program if the ESC key is pressed.
        if cv2.waitKey(1) == 27:
            break

    # Destruction upon exit
    recognizer.close()
    camera.release()
    cv2.destroyAllWindows()
