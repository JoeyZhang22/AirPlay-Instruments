import cv2
import MediaPipe.mediapipe_utils as mediapipe_utils
import numpy as np

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
line_color = (230, 216, 173)  # light blue
line_thickness = 1


def open_camera(camera_id, width, height):
    # Start capturing video input from the camera
    cap = cv2.VideoCapture(camera_id)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
    return cap


def draw_fps(current_frame, FPS):
    fps_text = "FPS = {:.1f}".format(FPS)
    text_location = (left_margin, top_margin)
    draw_text(current_frame, text_location, fps_text)


def draw_text(
    current_frame,
    text_location,
    text,
    color=default_text_color,
    font_size=default_font_size,
):
    # Compute text size
    text_size = cv2.getTextSize(
        text, cv2.FONT_HERSHEY_DUPLEX, default_font_size, default_font_thickness
    )[0]
    text_width, text_height = text_size

    # Draw the text
    cv2.putText(
        current_frame,
        text,
        text_location,
        cv2.FONT_HERSHEY_DUPLEX,
        font_size,
        color,
        default_font_thickness,
        cv2.LINE_AA,
    )


def draw_gesture_labels(recognition_result, current_frame):
    # Draw landmarks and write the text for each hand.
    for hand_result in recognition_result:
        hand_landmarks = hand_result["Gesture_Landmarks"]

        # Calculate the bounding box of the hand
        x_min = min([landmark.x for landmark in hand_landmarks])
        y_min = min([landmark.y for landmark in hand_landmarks])
        y_max = max([landmark.y for landmark in hand_landmarks])

        # Avoid drawing outside of boundary
        text_x = x_min
        text_y = y_max if y_min < 0.5 else y_min

        offset_y = 1 if y_min < 0.5 else -1
        offset_x = 0 if x_min < 0.5 else -1

        # Convert normalized coordinates to pixel values
        frame_height, frame_width = current_frame.shape[:2]
        text_x_px = int(text_x * frame_width)
        text_y_px = int(text_y * frame_height)

        # Get gesture classification results
        handedness = hand_result["Handedness"]
        gesture = hand_result["Gesture_Type"]
        score = hand_result["Score"]
        result_text = f"{handedness} {gesture}"

        # Compute result_text size
        text_size = cv2.getTextSize(
            result_text, cv2.FONT_HERSHEY_DUPLEX, default_font_size, default_font_thickness
        )[0]
        text_width, text_height = text_size

        draw_text(
            current_frame,
            (text_x_px + offset_x * text_width, text_y_px + offset_y * text_height),
            result_text,
            label_text_color,
            label_font_size,
        )

        # Draw Area Name
        area_text = f'{hand_result["Area"]}'
        area_text_color = (0, 0, 255)  # red

        # Compute result_text size
        text_size = cv2.getTextSize(
            area_text, cv2.FONT_HERSHEY_DUPLEX, default_font_size, default_font_thickness
        )[0]
        text_width, text_height = text_size

        draw_text(
            current_frame,
            (text_x_px + offset_x * text_width, text_y_px + offset_y * text_height * 2),
            area_text,
            area_text_color,
            label_font_size,
        )

        # Draw hand landmarks on the frame
        mediapipe_utils.draw_landmarks(current_frame, hand_landmarks)

        # Test Finger up
        finger_status = mediapipe_utils.is_finger_up(hand_landmarks)
        hand_result["Finger_Status"] = finger_status


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
    if areas[0].type == "None":
        draw_dashed_line(
            current_frame,
            (frame_width // 2, 0),
            (frame_width // 2, frame_height),
            line_color,
            line_thickness,
        )

    # Draw Labels for each area
    area_label_color = (88, 233, 88)  # light green
    for area in areas:
        if area.type == "Rectangle":
            x_min = int(area.x_min * frame_width)
            x_max = int(area.x_max * frame_width)
            y_min = int(area.y_min * frame_height)
            y_max = int(area.y_max * frame_height)

            draw_dashed_line(current_frame, (x_min, y_min), (x_max, y_min), line_color, line_thickness)
            draw_dashed_line(current_frame, (x_min, y_max), (x_max, y_max), line_color, line_thickness)
            draw_dashed_line(current_frame, (x_max, y_min), (x_max, y_max), line_color, line_thickness)

            draw_text(current_frame, (x_min + 2, y_max - 5), area.name, area_label_color, 0.5)
        elif area.type == "Circle" or area.type == "Corner":
            normalized_x, normalized_y = area.center
            center_x = int(normalized_x * frame_width)
            center_y = int(normalized_y * frame_height)

            radius_x = int(area.radius * frame_width)
            radius_y = int(area.radius * frame_height)
            
            cv2.ellipse(current_frame, (center_x, center_y), (radius_x, radius_y), 0, 0, 360, line_color, line_thickness)

            # adust area text based on position
            text_offset_x = 1 if normalized_x < 0.5 else -1
            text_offset_y = 1 if normalized_y < 0.5 else -1

            # Compute text size
            text_size = cv2.getTextSize(
                area.name, cv2.FONT_HERSHEY_DUPLEX, default_font_size, default_font_thickness
            )[0]
            text_width, text_height = text_size

            if area.type == "Circle":
                draw_text(current_frame, (center_x, center_y + text_offset_y*(radius_y + text_height)), area.name, area_label_color, 0.5)
            else:
                draw_text(current_frame, (center_x + text_offset_x*(text_width), center_y + text_offset_y*(radius_y + text_height)), area.name, area_label_color, 0.5)

def draw_dashed_line(image, start_point, end_point, color, thickness, dash_length=5, gap_length=5):
    x1, y1 = start_point
    x2, y2 = end_point
    length = np.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
    num_dashes = int(length // (dash_length + gap_length))
    
    for i in range(num_dashes + 1):
        start_x = int(x1 + (x2 - x1) * (i * (dash_length + gap_length)) / length)
        start_y = int(y1 + (y2 - y1) * (i * (dash_length + gap_length)) / length)
        end_x = int(x1 + (x2 - x1) * ((i * (dash_length + gap_length)) + dash_length) / length)
        end_y = int(y1 + (y2 - y1) * ((i * (dash_length + gap_length)) + dash_length) / length)
        
        # Ensure the end of the dash doesn't exceed the endpoint
        if i == num_dashes:
            end_x, end_y = x2, y2
        
        cv2.line(image, (start_x, start_y), (end_x, end_y), color, thickness)