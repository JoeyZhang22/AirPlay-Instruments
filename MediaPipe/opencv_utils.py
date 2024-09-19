import cv2
import mediapipe_utils

# Visualization parameters
row_size = 50  # pixels
left_margin = 24  # pixels
text_color = (0, 0, 0)  # black
font_thickness = 1

# Label box parameters
label_text_color = (255, 255, 255)  # white
label_font_size = 0.75
label_thickness = 1

# Division lines parameters
line_color = (255, 0, 0)  # grey
line_thickness = 2

def open_camera(camera_id, width, height):
  # Start capturing video input from the camera
  cap = cv2.VideoCapture(camera_id)
  cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
  cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
  return cap

def draw_fps(current_frame, FPS):
  fps_text = 'FPS = {:.1f}'.format(FPS)
  text_location = (left_margin, row_size)
  cv2.putText(current_frame, fps_text, text_location, cv2.FONT_HERSHEY_DUPLEX,
              label_font_size, text_color, font_thickness, cv2.LINE_AA)

def draw_gesture_labels(recognition_result_list, current_frame):
  # Draw landmarks and write the text for each hand.
  for hand_index, hand_landmarks in enumerate(recognition_result_list[0].hand_landmarks):
    # Calculate the bounding box of the hand
    x_min = min([landmark.x for landmark in hand_landmarks])
    y_min = min([landmark.y for landmark in hand_landmarks])
    y_max = max([landmark.y for landmark in hand_landmarks])

    # Convert normalized coordinates to pixel values
    frame_height, frame_width = current_frame.shape[:2]
    x_min_px = int(x_min * frame_width)
    y_min_px = int(y_min * frame_height)
    y_max_px = int(y_max * frame_height)

    
    # Get gesture classification results
    if recognition_result_list[0].gestures:
      gesture = recognition_result_list[0].gestures[hand_index]
      category_name = gesture[0].category_name
      handedness = recognition_result_list[0].handedness[hand_index][0].category_name
      # Mirror the handedness
      handedness = "Left" if handedness == "Right" else "Right"
      score = round(gesture[0].score, 2)
      result_text = f'{handedness} {category_name} ({score})'
      # Compute text size
      text_size = \
      cv2.getTextSize(result_text, cv2.FONT_HERSHEY_DUPLEX, label_font_size,
                      label_thickness)[0]
      text_width, text_height = text_size

      # Calculate text position (above the hand)
      text_x = x_min_px
      text_y = y_min_px - 10  # Adjust this value as needed

      # Make sure the text is within the frame boundaries
      if text_y < 0:
        text_y = y_max_px + text_height

      # Draw the text
      cv2.putText(current_frame, result_text, (text_x, text_y),
                  cv2.FONT_HERSHEY_DUPLEX, label_font_size,
                  label_text_color, label_thickness, cv2.LINE_AA)
  
    # Draw hand landmarks on the frame
    mediapipe_utils.draw_landmarks(current_frame, hand_landmarks)

def draw_division_lines(current_frame):
  """
  For now the screen is divided to 6 parts:
    Top-left:     Strum up
    Mid-left:     Neutral
    Bottom-left:  Strump down

    Top-right:     Major
    Mid-right:     Minor
    Bottom-right:  Special
  """

  # Get the size of the frame
  frame_height, frame_width = current_frame.shape[:2]

  # Draw the lines
  cv2.line(current_frame, (frame_width//2, 0), (frame_width//2, frame_height), line_color, line_thickness)
  cv2.line(current_frame, (0, frame_height//3), (frame_width, frame_height//3), line_color, line_thickness)
  cv2.line(current_frame, (0, 2*frame_height//3), (frame_width, 2*frame_height//3), line_color, line_thickness)
