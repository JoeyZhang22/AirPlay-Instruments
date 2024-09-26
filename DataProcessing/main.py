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

chord_type_list = ["major", "minor", "dim7", "dom7"]
chord_natural  = ["C", "D", "E", "F", "G", "A", "B"]
chord_sharp = ["C#", "D#", "F#", "G#", "A#"]
chord_flat = ["Db", "Eb", "Gb", "Ab", "Bb"]

#to play chords using Joey's MIDI stuff
chord_list = ["Cmin7", "F7", "Gmaj", "Cmaj"]

# Process the gesture sent by Nick
# Input: Nick's Output dictionary containing Handedness, Area, Gesture Type, Score (confidence)
def process_gestures(Output: input): 
    action = []

    # Map Nick's output object to Gesture object
    action_temp = Gesture(
        location = input.gesture_landmarks,
        gesture_name = input.gesture_type,
        confidence = input.score
    )
    # The rest of this function should store the actions and determine when a strum is made

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

#now given a gesture and given a zone can get chord note and type
class chord:
    def __init__(self, gesture, gesture_dict, velocity, duration,  zone, zone_map):
        self.key = gesture_dict[gesture]
        self.chord_type = zone_map[zone]
        self.velocity = velocity

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

# To use the difference in location to calculate the velocity of the strum
# Get the object where the strum is at either a maxima and minima n a certain divison of the screen
def get_velocity(location):
    velocities = []
    for i in range(1, len(location)):
        # Extracting x and y coordinates for the wrist landmark (index 0)
        current_location = location[i][0]
        previous_location = location[i-1][0]
        
        current_position = (
            current_location.x, 
            current_location.y
        )
        previous_position = (
            previous_location.x, 
            previous_location.y
        )
        
        time_interval = end_time - start_time
        displacement = [
            current_location[j] - previous_location[j] for j in range(2) # displacement in x and y directions
        ]
        
        velocity = [displacement[j] / time_interval for j in range(2)]
        velocities.append(velocity)
        
    return velocities

for chord in chord_list:
    play(chord=, duration=1)#duration currently set as 1. But in the future, it will be calculate via: end_time - start_time
