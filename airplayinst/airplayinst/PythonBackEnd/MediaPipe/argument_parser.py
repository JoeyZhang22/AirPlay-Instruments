import argparse


def add_argument():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--model",
        help="Name of gesture recognition model.",
        required=False,
        default="/Users/joeyzhang/Documents/git/school/AirPlay-Instruments/AirplayInst/airplayinst/PythonBackEnd/MediaPipe/gesture_recognizer.task",
    )
    parser.add_argument(
        "--numHands",
        help="Max number of hands that can be detected by the recognizer.",
        required=False,
        default=2,
    )
    parser.add_argument(
        "--minHandDetectionConfidence",
        help="The minimum confidence score for hand detection to be considered "
        "successful.",
        required=False,
        default=0.5,
    )
    parser.add_argument(
        "--minHandPresenceConfidence",
        help="The minimum confidence score of hand presence score in the hand "
        "landmark detection.",
        required=False,
        default=0.5,
    )
    parser.add_argument(
        "--minTrackingConfidence",
        help="The minimum confidence score for the hand tracking to be "
        "considered successful.",
        required=False,
        default=0.5,
    )

    # Finding the camera ID can be very reliant on platform-dependent methods.
    # One common approach is to use the fact that camera IDs are usually indexed sequentially by the OS, starting from 0.
    # Here, we use OpenCV and create a VideoCapture object for each potential ID with 'cap = cv2.VideoCapture(i)'.
    # If 'cap' is None or not 'cap.isOpened()', it indicates the camera ID is not available.
    parser.add_argument("--cameraId", help="Id of camera.", required=False, default=0)
    parser.add_argument(
        "--frameWidth",
        help="Width of frame to capture from camera.",
        required=False,
        default=920,
    )
    parser.add_argument(
        "--frameHeight",
        help="Height of frame to capture from camera.",
        required=False,
        default=720,
    )
    parser.add_argument(
        "--handedness",
        help="Which hand is preferable to strum",
        required=False,
        default="right",
    )


    # ADDITIONAL ARGS added for instrument mode and config file path
    parser.add_argument(
        "--instrument",
        choices=["C", "E", "P"],
        required=True,
        help="Instrument type: C (Chord), E (Expressive), P (Percussive)",
    )
    parser.add_argument("--config", required=True, help="Path to chord_config.json")

    return parser.parse_args()
