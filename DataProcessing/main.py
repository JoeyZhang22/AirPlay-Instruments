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
chord_type_list = ["major", "minor", "dim7", "dom7"]
notes  = ["a", "b", "c", "d", "e", "f", "g"]
#start with natrual chords to start
#map each defined gesture to a note
def create_gesture_dict(gesture_list, notes_list): 
    #for each note assign a gesture. given gesture can retrieve note
    gesture_dict = {gesture_list[i]: notes[i] for i in range(len(notes))}
    return gesture_dict
#start with major, minor, dim and dom 7ths
#match each zone to a chord type
def create_zone_map(chord_type_list):
    zone_map = []
    for chord_type in chord_type_list:
        zone_map.append(chord_type) 
    return zone_map 

####now given a gesture and given a zone can get chord note and type
#
class chord:
    def __init__(self, gesture, gesture_dict, velocity, duration,  zone, zone_map):
        self.key = gesture_dict[gesture]
        self.chord_type = zone_map[zone]
        self.velocity = velocity
        self.duration = duration


gestures = ["thumbs_up", "thumbs_down", "peace", "love", "spock", "guh", "meep"]

zone_map = create_zone_map(chord_type_list)
gesture_dict = create_gesture_dict(gestures, notes)

my_first_chord = chord("thumbs_up", gesture_dict, 17, 3, 2, zone_map)

print("the zone map")
print(zone_map)
print("the gesture dict")
print(gesture_dict)
print("the chord propertires:")
print(vars(my_first_chord))



# To use the difference in location to calculate the velocity of the strum
def get_velocity(location) -> float:
