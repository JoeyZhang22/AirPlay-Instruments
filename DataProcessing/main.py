# Main scripts for processing captured data to MIDI input

# What is being mapped from what Nick gives us
class Gesture:
    def __init__(self, location, gesture_name, start_time, end_time, confidence, gesture_id):
        self.location = location  
        self.gesture_name = gesture_name  # Name of the gesture
        self.start_time = start_time  # Start time of the gesture
        self.end_time = end_time  # End time of the gesture
        self.confidence = confidence  # Confidence level in gesture recognition
        self.gesture_id = gesture_id  # Unique identifier for the gesture

# Object to give to Joey 
class Chord:
    Key # C, D, E, F, ... etc.
    chord_type # major, minor, diminished 
    velocity 
    duration

# To use the difference in location to calculate the velocity of the strum
def get_velocity(location) -> float:

# Map the zone of the frame and the gesture to the key, chord type, and strum
def gesture_map() -> None:
