from ../MIDI/usage/midi_mingus.py import *

# Main scripts for processing captured data to MIDI input

# What is being mapped from what Nick gives us
class Gesture:
    def __init__(self, location, gesture_name, start_time, end_time, confidence, gesture_id):
        self.location = location  
        self.start_time = start_time # Start time of strum
        self.end_time = end_time # End time of strum
        self.gesture_name = gesture_name  # Name of the gesture
        self.confidence = confidence  # Confidence level in gesture recognition
        self.gesture_id = gesture_id  # Unique identifier for the gesture

# Object to be sent to Joey
class Chord:
    def __init__(self, gesture_dict, gesture, chord_type, duration):
        self.key = gesture_dict[gesture]
        self.chord_type = chord_type
        self.duration = duration

gesture_dict = {
    "open_hand": 'C',
    "fist": 'D',          
    "pointing": 'E',      
    "peace_sign": 'F',    
    "thumbs_up": 'G',     
    "thumbs_down": 'A',  
    "rock_on": 'B',       
    "ok_sign": 'C'        
}

test_list = []

# Process the gesture sent by Nick
# Input: Nick's output dictionary containing Handedness, Area, Gesture Type, Score
# Returns: Chord object containing Key, Chord Type (Major, Minor, Special), Duration
def process_gestures(Gesture: Gesture): 
    prev_gesture = []

    if Gesture.Handedness is "Right" and Gesture.confidence > 70:
        gesture = Gesture.gesture_type
        Chord.key = gesture_dict.get(gesture)
        start_time = Gesture.Time

        if Gesture.location is "Major":
            Chord.chord_type = "major"
        elif Gesture.location is "Minor":
            Chord.chord_type = "minor"
        else:
            Chord.chord_type = "dom7"

        # If it is a different gesture or in a different part of the screen, take the current time and calculate the duration of the gesture
        if (gesture != prev_gesture.gesture and prev_gesture != None) or (gesture.location != prev_gesture.location and prev_gesture.location != None):
            end_time = Gesture.Time
            Chord.duration = end_time - start_time
            return Chord 
        prev_gesture = Chord
    return

#map each defined gesture to a note
def create_gesture_dict(gesture_list, chord_list): 
    #for each note assign a gesture. given gesture can retrieve note
    gesture_dict = {gesture_list[i]: chord[i] for i in range(len(chord))}
    return gesture_dict

#match each zone to a chord type
def create_zone_map(chord_type_list):
    zone_map = []
    for chord_type in chord_type_list:
        zone_map.append(chord_type) 
    return zone_map 

gestures = ["thumbs_up", "thumbs_down", "peace", "love", "spock", "guh", "meep"]

zone_map = create_zone_map(chord_type_list)
gesture_dict = create_gesture_dict(gestures, chord)

my_first_chord = chord("thumbs_up", gesture_dict, 17, 3, 2, zone_map)

print("the zone map")
print(zone_map)
print("the gesture dict")
print(gesture_dict)
print("the chord propertires:")
print(vars(my_first_chord))

for chord in chord_list:
    play(chord=, duration=1)#duration currently set as 1. But in the future, it will be calculate via: end_time - start_time
