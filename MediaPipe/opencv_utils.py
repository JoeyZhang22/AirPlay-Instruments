import cv2
import mediapipe_utils

# Window parameters
top_margin = 25  # pixels
left_margin = 25  # pixels

# Visualization default parameters
default_text_color = (0, 0, 0)  # black
default_font_size = 0.5
default_font_thickness = 1

# Label parameters
label_text_color = (255, 255, 255)  # white
label_font_size = 0.5
label_font_thickness = 1

# Division lines parameters
line_color = (255, 0, 0)  # blue
line_thickness = 1

def open_camera(camera_id, width, height):
  # Start capturing video input from the camera
  cap = cv2.VideoCapture(camera_id)
  cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
  cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
  return cap

def draw_fps(current_frame, FPS):
  fps_text = 'FPS = {:.1f}'.format(FPS)
  text_location = (left_margin, top_margin)
  draw_text(current_frame, text_location, fps_text)

def draw_text(current_frame, text_location, text, color=default_text_color, font_size=default_font_size):
  # Compute text size
  text_size = \
  cv2.getTextSize(text, cv2.FONT_HERSHEY_DUPLEX, default_font_size,
                  default_font_thickness)[0]
  text_width, text_height = text_size

  # Boudary protection

  # Draw the text
  cv2.putText(current_frame, text, text_location,
              cv2.FONT_HERSHEY_DUPLEX, font_size,
              color, default_font_thickness, cv2.LINE_AA)

def draw_gesture_labels(recognition_result, current_frame):
  # Draw landmarks and write the text for each hand.
  for hand_result in recognition_result:
    hand_landmarks = hand_result["Gesture_Landmarks"]

    # Calculate the bounding box of the hand
    x_min = min([landmark.x for landmark in hand_landmarks])
    y_min = min([landmark.y for landmark in hand_landmarks])
    y_max = max([landmark.y for landmark in hand_landmarks])

    # Convert normalized coordinates to pixel values
    frame_height, frame_width = current_frame.shape[:2]
    x_min_px = int(x_min * frame_width)
    y_min_px = int(y_min * frame_height)

    # Get gesture classification results
    handedness = hand_result["Handedness"]
    gesture = hand_result["Gesture_Type"]
    score = hand_result["Score"]
    result_text = f'{handedness} {gesture} ({score})'

    draw_text(current_frame, (x_min_px, y_min_px - 10), result_text, label_text_color, label_font_size)

    # Draw Area Name
    area_text = f'{hand_result["Area"]}'
    area_text_color = (0, 0, 255) # red
    draw_text(current_frame, (x_min_px, y_min_px - 25), area_text, area_text_color, label_font_size)


    # Draw hand landmarks on the frame
    mediapipe_utils.draw_landmarks(current_frame, hand_landmarks)

def draw_division_lines(current_frame, areas):
  """
  For now, the screen is divided to 6 parts:
    Top-left:     Strum up
    Mid-left:     Neutral
    Bottom-left:  Strump down

    Top-right:     Major
    Mid-right:     Minor
    Bottom-right:  Special
  """

  # Get the size of the frame
  frame_height, frame_width = current_frame.shape[:2]

  # Draw the mid line
  cv2.line(current_frame, (frame_width//2, 0), (frame_width//2, frame_height), line_color, line_thickness)

  # Draw Labels for each area
  area_label_color = (0, 255, 0) # blue
  for area in areas:
    x_min = int(area.x_min * frame_width)
    x_max = int(area.x_max * frame_width)
    y_min = int(area.y_min * frame_height)
    y_max = int(area.y_max * frame_height)

    cv2.line(current_frame, (x_min, y_max), (x_max, y_max), line_color, line_thickness)
    draw_text(current_frame, (x_min, y_max - 5), area.name, area_label_color, 0.5)