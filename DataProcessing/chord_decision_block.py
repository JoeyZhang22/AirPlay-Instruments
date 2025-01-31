from enum import Enum
from MIDI.chord_player import *


# Maintain instrument states
class instrumentState(Enum):
    NEUTRAL = 0
    STRUM_DOWN = 1
    STRUM_UP = 2


# Set of actions passed to the actor function for execution
class actions(Enum):
    PLAY = 0
    PLAY_REVERSE = 1
    STOP = 2
    NULL = 3


# Use current instrument state and previous instrument state to determine the corresponding action
"""Corresponding action can be determined via: decisionMatrix[prev_state][cur_state] where prev_state and cur_state are instrumentState enums"""
decisionMatrix = [
    [actions.NULL, actions.PLAY, actions.PLAY_REVERSE],
    [actions.STOP, actions.NULL, actions.PLAY_REVERSE],
    [actions.STOP, actions.PLAY, actions.NULL],
]

####LEGACY CODE####
# # The ChordMatrix is currently hard-coded. In the future, it can be read from a file or generated dynamically based on user input.
# """ChordMatrix[Area][Gesture] accesses the chord index to be played."""
# chordMatrix = {
#     "Major": {"Open_Palm": 0, "Closed_Fist": 1},
#     "Minor": {"Open_Palm": 2, "Closed_Fist": 3},
#     "Special": {"Open_Palm": 0, "Closed_Fist": 1},
# }

def generate_chord_matrix():
    # Base chord list
    chord_list = ["Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#"]

    # Initial empty dictionary for gesture-to-chord mappings
    gesture_to_chord = {
        "Closed_Fist": None, 
        "Open_Palm": None,
        "Pointing_Up": None,
        "Thumb_Down": None,
        "Thumb_Up": None,
        "Victory": None,
        "ILoveYou": None,
        "None": None
    }

    # Chords with associated MIDI suffixes
    chord_types = {
        "Major": "",
        "Minor": "m",
        "Minor7": "m7",
        "Major7": "M7",
        "Dominant7": "7",
        "Diminished7": "dim7",
        "Hitchcock": "mM7",
        "Augmented": "+",
        "Augmented7#5": "7#5",
        "AugmentedM7#": "M7+",
        "Augmentedm7+": "m7+",
        "Augmented7+": "7+",
        "Suspended4": "sus4",
        "Suspended2": "sus2",
        "Suspended47": "sus47",
        "Suspended11": "11",
        "Suspended4b9": "sus4b9",
        "Suspendedb9": "susb9",
        "Six": "6",
        "Minor6": "m6",
        "Major6": "M6",
        "SevenSix": "67",
        "SixNine": "69",
        "Nine": "9",
        "Major9": "M9",
        "Dominant7b9": "7b9",
        "Dominant7#9": "7#9",
        "Eleven": "11",
        "Dominant7#11": "7#11",
        "Minor11": "m11", 
        "Thirteen": "13",
        "Major13": "M13",
        "Minor13": "m13",
        "Dominant7b5": "7b5",
        "NC": "NC",
        "Hendrix": "hendrix",
        "Power": "5"
    }

    # Default gesture-to-chord mapping
    default_gesture_to_chord = {
        "Closed_Fist": "C", 
        "Open_Palm": "D",
        "Pointing_Up": "E",
        "Thumb_Down": "F",
        "Thumb_Up": "G",
        "Victory": "A",
        "ILoveYou": "B",
        "None": None
    }

    # Default chord types for Top, Middle, and Bottom sections
    default_chord_types = ["Major", "Minor", "Dominant7"]

    # Function to get user selected chord types
    def get_chord_types():
        print("\nWould you like to use the default chord types? (yes/no)")
        choice = input().strip().lower()

        if choice == "yes":
            return default_chord_types

        print("\nAvailable chord types:", ", ".join(chord_types.keys()))
        
        selected_chord_types = []

        for i, section in enumerate(["Top", "Middle", "Bottom"]):
            while True:
                choice = input(f"Choose a chord type for the {section} section: ").strip()
                if choice in chord_types:
                    selected_chord_types.append(choice)
                    break
                else:
                    print("Invalid choice. Please type the name of a chord from the list.")
        return selected_chord_types
    
    def get_gesture_mapping():
        available_gestures = list(gesture_to_chord.keys()) 

        print("\nWould you like to use the default gesture-to-chord mapping? (yes/no)")
        choice = input().strip().lower()

        if choice == "yes":
            return default_gesture_to_chord
        
        custom_mapping = {}

        while True:
            print("\nAvailable gestures:", ", ".join(available_gestures))
            gesture = input("Enter a gesture name (or type 'done' to finish): ").strip()
            
            if gesture.lower() == "done":
                break
            if gesture not in available_gestures:
                print("Invalid gesture. Please choose from the available gestures.")
                continue

            chord = input(f"Enter the chord for {gesture}: ").strip()
            custom_mapping[gesture] = chord

            print("\nCurrent Mapping:")
            for g, c in custom_mapping.items():
                print(f"  {g}: {c}")

        return custom_mapping if custom_mapping else default_gesture_to_chord

    gesture_to_chord = get_gesture_mapping()
    selected_chord_types = get_chord_types()

    chord_matrix = {chord_type: {} for chord_type in selected_chord_types}

    for gesture, chord in gesture_to_chord.items():
        for chord_type in selected_chord_types:
            suffix = chord_types[chord_type]
            chord_matrix[chord_type][gesture] = (chord + suffix) if chord else None

    print("\nFinal Chord Matrix:")
    for section, mapping in chord_matrix.items():
        filtered_mapping = {gesture: chord for gesture, chord in mapping.items() if chord is not None}
        print(f"{section}: {filtered_mapping}")

    return chord_matrix

chordMatrix = generate_chord_matrix()

# Takes in chord matrix and lists all chords
def chords_list(chord_matrix):
    all_chords = set()
    for mappings in chord_matrix.values():
        all_chords.update(chord for chord in mappings.values() if chord is not None)
    return list(all_chords)

chord_list = chords_list(chordMatrix)
print(chord_list)

class chordDecisionBlock:
    def __init__(self, output_port="loopMIDI Port 1"):
        # Initialize MIDI output port, default is Logic Pro Virtual In
        self.output_port = mido.open_output(output_port)
        self.chord_list = chord_list # Changed from previous hardcoded list
        self.midi_chord_dict = convert_chord_to_midi_chord(self.chord_list)
        self.state = instrumentState.NEUTRAL
        self.prev_chord_index = -1  # Initialized to -1 to indicate no previous chord
        self.chord_hand = None
        self.strum_hand = None

    def update_state(self, recognizer_results):
        if len(recognizer_results) < 2:  # Only one hand detected
            print("update state: NEUTRAL")
            self.state = instrumentState.NEUTRAL
        else:
            self.getHands(recognizer_results)
            if (
                self.chord_hand.get("Gesture_Type") == "None"
                or self.chord_hand.get("Area") == "None"
                or self.strum_hand.get("Area") == "None"
                # or self.strum_hand.get("Gesture_Type") == "None"
            ):
                self.state = instrumentState.NEUTRAL
            else:
                if self.strum_hand.get("Area") == "Strum down":
                    print("update state: STRUM_DOWN")
                    self.state = instrumentState.STRUM_DOWN
                elif self.strum_hand.get("Area") == "Strum up":
                    print("update state: STRUM_UP")
                    self.state = instrumentState.STRUM_UP
                else:
                    self.state = instrumentState.NEUTRAL

    def decision_maker(self, recognizer_results):
        prev_state = self.state
        self.update_state(recognizer_results)

        print("previous state: ", prev_state)
        print("current state: ", self.state)

        action = decisionMatrix[prev_state.value][self.state.value]

        print("current action: ", action)

        if action == actions.STOP:
            self.actor(perform_action=action, chord=self.prev_chord_index)
        elif action == actions.PLAY or action == actions.PLAY_REVERSE:
            print(recognizer_results)
            gesture = self.chord_hand.get("Gesture_Type")
            area = self.chord_hand.get("Area")
            print("left hand gesture: ", gesture)
            print("left hand area: ", area)
            print("right hand gesture: ", self.strum_hand.get("Gesture_Type"))
            print("right hand area: ", self.strum_hand.get("Area"))
            chord = self.midi_chord_dict.get(chordMatrix[area][gesture])
            self.actor(perform_action=action, chord=chord)
        else:
            None  # Do nothing

    # Depending on action to be performed, call the appropriate play or off function
    def actor(self, perform_action, chord):
        # Switch statement
        if perform_action == actions.PLAY:
            self.play(chord=chord, reverse=False)
            self.prev_chord_index = chord  # Update to current chord
        elif perform_action == actions.PLAY_REVERSE:
            self.play(chord=chord, reverse=True)
            self.prev_chord_index = chord
        elif perform_action == actions.STOP:
            self.off(chord=self.prev_chord_index)
        else:
            return

    def getHands(
        self, recognizer_results
    ):  # Only call when recognizer_results length == 2
        assert len(recognizer_results) == 2
        for hand in recognizer_results:
            if hand.get("Handedness") == "Left":
                self.chord_hand = hand
            else:
                self.strum_hand = hand

    # Play function
    def play(self, chord, reverse=False):  # Input has to be MIDI chord (all int notes)
        if not reverse:
            for note in chord:
                self.output_port.send(note_on(note=note))
                sleep(0.05)
        else:
            for note in reversed(chord):
                self.output_port.send(note_on(note=note))
                sleep(0.05)

    def off(self, chord):
        for note in chord:
            self.output_port.send(note_off(note=note))
