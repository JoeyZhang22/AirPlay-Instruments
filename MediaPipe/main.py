# Copyright 2023 The MediaPipe Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Main scripts

import argparse
import sys
import time

import cv2
import mediapipe_utils
import opencv_utils

# Global variables to calculate FPS
COUNTER, FPS = 0, 0
START_TIME = time.time()
FPS_REFREASH_COUNT = 10

# update FPS on display
def update_FPS():
  global FPS, COUNTER, START_TIME, FPS_REFREASH_COUNT
  
  # Calculate the FPS
  if COUNTER % FPS_REFREASH_COUNT == 0:
    FPS = FPS_REFREASH_COUNT / (time.time() - START_TIME)
    START_TIME = time.time()

  COUNTER += 1

def run(model: str, num_hands: int,
        min_hand_detection_confidence: float,
        min_hand_presence_confidence: float, min_tracking_confidence: float,
        camera_id: int, width: int, height: int, sync: bool) -> None:
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
  # init camera
  camera = opencv_utils.open_camera(camera_id, width, height)

  recognition_frame = None
  recognition_result_list = []

  # init recognizer
  recognizer = mediapipe_utils.Recognizer(
              model, 
              num_hands,
              min_hand_detection_confidence,
              min_hand_presence_confidence, 
              min_tracking_confidence)

  # Continuously capture images from the camera and run inference
  while camera.isOpened():
    success, image = camera.read()
    if not success:
      sys.exit(
          'ERROR: Unable to read from webcam. Please verify your webcam settings.'
      )

    image = cv2.flip(image, 1)

    # Convert the image from BGR to RGB as required by the TFLite model.
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Run gesture recognizer using the model asynchrnously.
    if sync:
      recognizer.run_sync(rgb_image)
    else:
      recognizer.run_async(rgb_image, time.time_ns() // 1_000_000)

    # Show the FPS
    current_frame = image
    opencv_utils.draw_fps(current_frame, FPS)

    # Get the recognized output
    recognition_result_list = recognizer.get_recognized_output()
    if recognition_result_list:
      update_FPS()
      opencv_utils.draw_gesture_labels(recognition_result_list, current_frame)

    recognition_frame = current_frame
    recognition_result_list.clear()

    # Diplay the frame with labelling
    if recognition_frame is not None:
        # Standarize resolution
        resized_frame = cv2.resize(recognition_frame, (1920, 1080))
        cv2.imshow('gesture_recognition', resized_frame)

    # Stop the program if the ESC key is pressed.
    if cv2.waitKey(1) == 27:
        break

  # Destruction upon exit
  recognizer.close()
  camera.release()
  cv2.destroyAllWindows()


def main():
  parser = argparse.ArgumentParser(
      formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  parser.add_argument(
      '--model',
      help='Name of gesture recognition model.',
      required=False,
      default='gesture_recognizer.task')
  parser.add_argument(
      '--numHands',
      help='Max number of hands that can be detected by the recognizer.',
      required=False,
      default=1)
  parser.add_argument(
      '--minHandDetectionConfidence',
      help='The minimum confidence score for hand detection to be considered '
           'successful.',
      required=False,
      default=0.5)
  parser.add_argument(
      '--minHandPresenceConfidence',
      help='The minimum confidence score of hand presence score in the hand '
           'landmark detection.',
      required=False,
      default=0.5)
  parser.add_argument(
      '--minTrackingConfidence',
      help='The minimum confidence score for the hand tracking to be '
           'considered successful.',
      required=False,
      default=0.5)
  
  # Finding the camera ID can be very reliant on platform-dependent methods.
  # One common approach is to use the fact that camera IDs are usually indexed sequentially by the OS, starting from 0.
  # Here, we use OpenCV and create a VideoCapture object for each potential ID with 'cap = cv2.VideoCapture(i)'.
  # If 'cap' is None or not 'cap.isOpened()', it indicates the camera ID is not available.
  parser.add_argument(
      '--cameraId', help='Id of camera.', required=False, default=0)
  parser.add_argument(
      '--frameWidth',
      help='Width of frame to capture from camera.',
      required=False,
      default=640)
  parser.add_argument(
      '--frameHeight',
      help='Height of frame to capture from camera.',
      required=False,
      default=480)
  args = parser.parse_args()

  run(args.model, int(args.numHands), float(args.minHandDetectionConfidence),
      args.minHandPresenceConfidence, args.minTrackingConfidence,
      int(args.cameraId), int(args.frameWidth), int(args.frameHeight), False)


if __name__ == '__main__':
  main()