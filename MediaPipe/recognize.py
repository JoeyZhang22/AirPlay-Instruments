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
class MP_Recognizer():
  def __init__(self, model: str, num_hands: int,
              min_hand_detection_confidence: float,
              min_hand_presence_confidence: float, 
              min_tracking_confidence: float):

    # Define Callback function to save results
    def save_result(result: vision.GestureRecognizerResult,
                    unused_output_image: mp.Image, 
                    timestamp_ms: int):

      # Calculate and Update the FPS
      #if FPS_PARAMS["COUNTER"] % fps_refresh_frame_count == 0:
      #    FPS_PARAMS["FPS"] = fps_refresh_frame_count / (time.time() - FPS_PARAMS["START_TIME"])
       #   FPS_PARAMS["START_TIME"] = time.time()

      self.recognition_result_list.append(result)
      #FPS_PARAMS["COUNTER"] += 1

    # Initialize the gesture recognizer model
    self.recognition_result_list = []
    self.base_options = python.BaseOptions(model_asset_path=model)
    self.options = vision.GestureRecognizerOptions(base_options=self.base_options,
                                            running_mode=vision.RunningMode.LIVE_STREAM,
                                            num_hands=num_hands,
                                            min_hand_detection_confidence=min_hand_detection_confidence,
                                            min_hand_presence_confidence=min_hand_presence_confidence,
                                            min_tracking_confidence=min_tracking_confidence,
                                            result_callback=save_result)
    self.recognizer = vision.GestureRecognizer.create_from_options(self.options)
  
  # This one doesn't return, but start working in the background
  def run_async(self, rgb_image, time_ms):
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_image)
    self.recognizer.recognize_async(mp_image, time_ms)

  # Result getter
  def get_recognized_output(self):
    transformed_output = self.transform_recognized_output()
    self.recognition_result_list.clear()
    return transformed_output

  # This function transform the output from the MP recognizer to the input for Decision Block
  def transform_recognized_output(self, ):
    # transform_output = dict()
    transform_output = copy.deepcopy(self.recognition_result_list)
    return transform_output

  # To be implemented...
  def run_sync(self):
    return
  
  # Close recognizer
  def close(self):
    self.recognizer.close()