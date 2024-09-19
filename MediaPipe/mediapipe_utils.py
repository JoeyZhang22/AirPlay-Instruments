# Scripts to run MediaPipe for gesture recognition.
import copy

import mediapipe as mp

from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from mediapipe.framework.formats import landmark_pb2

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles

# Class to provide adapted MediaPipe interface for Decisionbox
class Recognizer():
  def __init__(self, model: str, num_hands: int,
              min_hand_detection_confidence: float,
              min_hand_presence_confidence: float, 
              min_tracking_confidence: float):

    # Define Callback function to save results
    def save_result(result: vision.GestureRecognizerResult,
                    unused_output_image: mp.Image, 
                    timestamp_ms: int):
      self.recognition_result_list.append(result)

    # Initialize the gesture recognizer model
    self.recognition_result_list = []
    self.base_options = python.BaseOptions(model_asset_path = model)
    self.options = vision.GestureRecognizerOptions(
                                            base_options = self.base_options,
                                            running_mode = vision.RunningMode.LIVE_STREAM,
                                            num_hands = num_hands,
                                            min_hand_detection_confidence = min_hand_detection_confidence,
                                            min_hand_presence_confidence = min_hand_presence_confidence,
                                            min_tracking_confidence = min_tracking_confidence,
                                            result_callback = save_result)
    self.recognizer = vision.GestureRecognizer.create_from_options(self.options)
  
  # To be implemented...
  def run_sync(self, rgb_image):
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_image)
    self.recognizer.recognize(mp_image)

  # This one doesn't return, but start recognizing work in the background
  def run_async(self, rgb_image, time_ms):
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_image)
    self.recognizer.recognize_async(mp_image, time_ms)

  # Recognized result getter
  def get_recognition_result(self):
    recognition_result = copy.deepcopy(self.recognition_result_list)
    self.recognition_result_list.clear()
    return recognition_result

  # This function transform the output from the MP recognizer to the input for Decision Block
  def transform_recognition_output(self):
    transformed_output = dict()

  # Close recognizer
  def close(self):
    self.recognizer.close()

# MediaPipe drawing solutions
def draw_landmarks(image, hand_landmarks):
  # Draw hand landmarks on the frame
  hand_landmarks_proto = landmark_pb2.NormalizedLandmarkList()
  hand_landmarks_proto.landmark.extend([
    landmark_pb2.NormalizedLandmark(
      x=landmark.x, y=landmark.y, z=landmark.z) for landmark in hand_landmarks])

  mp_drawing.draw_landmarks(
    image,
    hand_landmarks_proto,
    mp_hands.HAND_CONNECTIONS,
    mp_drawing_styles.get_default_hand_landmarks_style(),
    mp_drawing_styles.get_default_hand_connections_style())
  
