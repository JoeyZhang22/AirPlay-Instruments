# Main scripts for processing captured data to MIDI input

# What is being mapped from what Nick gives us
class Gesture:
    __init()
    location
    gesture_name
    start_time
    end_time
    duration
    confidence
    gesture_id

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
