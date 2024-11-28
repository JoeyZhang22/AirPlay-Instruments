# Scripts to run MediaPipe for gesture recognition.
import copy
import time

import mediapipe as mp

from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from mediapipe.framework.formats import landmark_pb2

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


class Area:
    def __init__(self, name, x_min, y_min, x_max, y_max):
        self.name = name

        # Dimensions are in normalized form (i.e. 0-1)
        self.x_min = x_min
        self.y_min = y_min
        self.x_max = x_max
        self.y_max = y_max

    def is_within(self, hand_landmarks):
        counter = 0

        for landmark in hand_landmarks:
            if (
                landmark.x > self.x_min
                and landmark.x < self.x_max
                and landmark.y > self.y_min
                and landmark.y < self.y_max
            ):
                counter += 1

        if counter >= len(hand_landmarks) * within_percentage:
            return True
        else:
            return False

    def draw_label(
        self, current_frame, frame_width, frame_height, line_color, text_color
    ):
        return
