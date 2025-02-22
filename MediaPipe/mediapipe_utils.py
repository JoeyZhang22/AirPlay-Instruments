# Scripts to run MediaPipe for gesture recognition.
import copy
import time

from typing import List
from enum import Enum

import numpy as np

import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from mediapipe.framework.formats import landmark_pb2
from mediapipe.framework.formats.landmark_pb2 import NormalizedLandmark

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles


# Class to provide adapted MediaPipe interface for Decisionbox
class Recognizer:
    def __init__(
        self,
        model: str,
        num_hands: int,
        min_hand_detection_confidence: float,
        min_hand_presence_confidence: float,
        min_tracking_confidence: float,
    ):

        # Define Callback function to save results
        def save_result(
            result: vision.GestureRecognizerResult,
            unused_output_image: mp.Image,
            timestamp_ms: int,
        ):
            self.recognition_result_list.append(result)
            self.timestamp_second = time.time()

        # Initialize the gesture recognizer model
        self.recognition_result_list = []
        self.base_options = python.BaseOptions(model_asset_path=model)
        self.options = vision.GestureRecognizerOptions(
            base_options=self.base_options,
            running_mode=vision.RunningMode.LIVE_STREAM,
            num_hands=num_hands,
            min_hand_detection_confidence=min_hand_detection_confidence,
            min_hand_presence_confidence=min_hand_presence_confidence,
            min_tracking_confidence=min_tracking_confidence,
            result_callback=save_result,
        )
        self.recognizer = vision.GestureRecognizer.create_from_options(self.options)
        self.timestamp_second = time.time()

    # To be implemented...
    def run_sync(self, rgb_image):
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_image)
        self.recognizer.recognize(mp_image)

    # This one doesn't return, but start recognizing work in the background
    def run_async(self, rgb_image, time_ms):
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_image)
        self.recognizer.recognize_async(mp_image, time_ms)

    # Recognized result getter
    def get_recognized_output(self, areas):
        # If there is no new recognition result return immediately
        if not self.recognition_result_list:
            return []

        transformed_output = self.transform_recognized_output(areas)
        self.recognition_result_list.clear()
        return transformed_output

    # This function transform the output from the MP recognizer to the input for Decision Block
    def transform_recognized_output(self, areas):
        """
        Output for decision block format:
        Output = {
        "Handedness" :
        "Area" :
        "Gesture_Type" :
        "Gesture_Landmarks" :
        "Score" :
        "Time" :
        "Finger_Status" :
        }
        """

        recognition_results = copy.deepcopy(self.recognition_result_list)

        transformed_results = []
        for recognition_result in recognition_results:
            transformed_outputs = []
            # Transform the results for decision box
            for hand_index, hand_landmarks in enumerate(
                recognition_result.hand_landmarks
            ):
                transformed_output = dict()

                transformed_output["Handedness"] = recognition_result.handedness[
                    hand_index
                ][0].category_name
                transformed_output["Handedness"] = (
                    "Left" if transformed_output["Handedness"] == "Right" else "Right"
                )  # Mirror the handedness
                transformed_output["Gesture_Type"] = recognition_result.gestures[
                    hand_index
                ][0].category_name
                transformed_output["Gesture_Landmarks"] = hand_landmarks
                transformed_output["Score"] = round(
                    recognition_result.gestures[hand_index][0].score, 2
                )
                transformed_output["Time"] = self.timestamp_second

                transformed_output["Area"] = "None"

                # determine which area this head appears at
                for area in areas:
                    if area.is_within(hand_landmarks):
                        transformed_output["Area"] = area.name
                        break

                transformed_outputs.append(transformed_output)

            transformed_results.append(transformed_outputs)

        return transformed_results

    # Close recognizer
    def close(self):
        self.recognizer.close()


# MediaPipe drawing solutions
def draw_landmarks(image, hand_landmarks):
    # Draw hand landmarks on the frame
    hand_landmarks_proto = landmark_pb2.NormalizedLandmarkList()
    hand_landmarks_proto.landmark.extend(
        [
            landmark_pb2.NormalizedLandmark(x=landmark.x, y=landmark.y, z=landmark.z)
            for landmark in hand_landmarks
        ]
    )

    mp_drawing.draw_landmarks(
        image,
        hand_landmarks_proto,
        mp_hands.HAND_CONNECTIONS,
        mp_drawing_styles.get_default_hand_landmarks_style(),
        mp_drawing_styles.get_default_hand_connections_style(),
    )


# If more than this within_percentage of the hand appeared in the area, then return true for Area.is_within()
within_percentage = 0.8

# Class for screen division
class Area:
    def __init__(self, name, type="Rectangle", x_min=-1, y_min=-1, x_max=-1, y_max=-1, radius=-1, center=(-1,-1), instrument_type=None):
        self.name = name
        self.type = type

        # Dimensions are in normalized form (i.e. 0.0-1.0)
        self.x_min = x_min
        self.y_min = y_min
        self.x_max = x_max
        self.y_max = y_max

        self.radius = radius
        self.center = center

        self.instrument_type = instrument_type

    def is_within(self, hand_landmarks):
        counter = 0

        # Only check a set of paticular landmarks
        target_hand_landmarks = []
        target_landmark_indices = [2, 3, 4]

        if self.instrument_type == "Percussion":
            for target_landmark_index in target_landmark_indices:
                target_hand_landmarks.append(hand_landmarks[target_landmark_index])
        else:
            target_hand_landmarks = hand_landmarks
        
        # Check if all target landmarks are inside of current area
        if self.type == "Rectangle":
            for landmark in target_hand_landmarks:
                if (
                    landmark.x > self.x_min
                    and landmark.x < self.x_max
                    and landmark.y > self.y_min
                    and landmark.y < self.y_max
                ):
                    counter += 1
        else:
            for landmark in target_hand_landmarks:
                center_x, center_y = self.center
                distance_squared = (landmark.x - center_x)**2 + (landmark.y - center_y)**2
                if distance_squared <= self.radius**2:
                    counter += 1
                

        if counter >= len(target_hand_landmarks) * within_percentage:
            return True
        else:
            return False

    def draw_label(
        self, current_frame, frame_width, frame_height, line_color, text_color
    ):
        return

# Better Finger Detection
def calculate_vector(p1: NormalizedLandmark, p2: NormalizedLandmark) -> np.ndarray:
    """Calculate the vector from p1 to p2."""
    return np.array([p2.x - p1.x, p2.y - p1.y, p2.z - p1.z])

def calculate_angle(v1: np.ndarray, v2: np.ndarray) -> float:
    """Calculate the angle between two vectors."""
    v1_norm = np.linalg.norm(v1)
    v2_norm = np.linalg.norm(v2)
    if v1_norm == 0 or v2_norm == 0:
        return 0.0
    cos_theta = np.dot(v1, v2) / (v1_norm * v2_norm)
    return np.arccos(cos_theta) * 180.0 / np.pi

def is_finger_up(hand_landmarks: List[NormalizedLandmark]) -> dict:
    """
    Determine whether each finger is extended (up) using hand landmarks and relative angles.

    Parameters:
        hand_landmarks (List[NormalizedLandmark]): List of 21 hand landmarks.

    Returns:
        dict: A dictionary indicating if each finger is extended (True or False).
    """
    fingers_status = {
        "thumb": False,
        "index": False,
        "middle": False,
        "ring": False,
        "pinky": False
    }

    # Palm base vector (wrist to palm center)
    wrist = hand_landmarks[0]
    palm_base = hand_landmarks[9]  # Landmark at the center of the palm
    palm_vector = calculate_vector(wrist, palm_base)

    # Thumb detection
    thumb_tip = hand_landmarks[4]
    thumb_ip = hand_landmarks[3]
    thumb_mcp = hand_landmarks[2]
    thumb_cmc = hand_landmarks[1]

    thumb_tip_to_ip = calculate_vector(thumb_tip, thumb_ip)
    thumb_cmc_to_mcp = calculate_vector(thumb_cmc, thumb_mcp)
    thumb_angle = calculate_angle(thumb_tip_to_ip, thumb_cmc_to_mcp)
    fingers_status["thumb"] = thumb_angle > 140  # Angle threshold for extended thumb

    # Fingers detection (Index, Middle, Ring, Pinky)
    for finger, (tip_idx, pip_idx, mcp_idx) in zip(
        ["index", "middle", "ring", "pinky"],
        [(8, 6, 5), (12, 10, 9), (16, 14, 13), (20, 18, 17)]
    ):
        tip = hand_landmarks[tip_idx]
        pip = hand_landmarks[pip_idx]
        mcp = hand_landmarks[mcp_idx]

        # Calculate vectors
        tip_to_pip = calculate_vector(tip, pip)
        mcp_to_pip = calculate_vector(mcp, pip)

        # Calculate angle between segments
        segment_angle = calculate_angle(mcp_to_pip, tip_to_pip)

        # Finger is extended if the angle is close to 180 degrees and the tip is farther from the wrist along the palm vector's direction
        wrist_to_tip = calculate_vector(wrist, tip)
        projection = np.dot(wrist_to_tip, palm_vector) / np.linalg.norm(palm_vector)
        fingers_status[finger] = segment_angle > 160 and projection > 0

    return fingers_status