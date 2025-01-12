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

# # The ChordMatrix is currently hard-coded. In the future, it can be read from a file or generated dynamically based on user input.
# """ChordMatrix[Area][Gesture] accesses the chord index to be played."""
# chordMatrix = {
#     "Major": {"Open_Palm": 0, "Closed_Fist": 1},
#     "Minor": {"Open_Palm": 2, "Closed_Fist": 3},
#     "Special": {"Open_Palm": 0, "Closed_Fist": 1},
# }

def generate_chord_matrix():
    # Initial dictionary for gesture-to-chord mappings
    gesture_to_chord = {
        "Closed_Fist": None, 
        "Open_Palm": None,
        "Pointing_Up": None,
        "Thumb_Down": None,
        "Thumb_Up": None,
        "Victory": None,
        "ILoveYou": None
    }

    # Base chord list
    base_chord_list = ["C", "D", "E", "F", "G", "A", "B"]

    # Function to display the current gesture-to-chord mappings
    def display_mappings(gesture_to_chord):
        print("\nCurrent Gesture-to-Chord Mappings:")
        for gesture, chord in gesture_to_chord.items():
            print(f"{gesture}: {chord if chord else 'None'}")

    while True:
        print("Available gestures: ")
        for gesture in gesture_to_chord:
            print(f"{gesture}")

        gesture = input("\nEnter the gesture you'd like to map (e.g., 'Closed_Fist', 'Open_Palm'): ")

        if gesture in gesture_to_chord:
            chord = input(f"Enter the chord you'd like to map to {gesture}: ")
            if chord in base_chord_list:
                gesture_to_chord[gesture] = chord
                print(f"Mapped {chord} to {gesture}.")
            else:
                print(f"Chord '{chord}' not found. Please choose a valid chord note.")
        else:
            print(f"Gesture '{gesture}' not found. Please choose a valid gesture from the list.")
        
        display_mappings(gesture_to_chord)

        continue_mapping = input("\nWould you like to map another gesture? (yes/no): ").lower()
        if continue_mapping != 'yes':
            break

    chord_matrix = {
            "Major": {},
            "Minor": {},
            "Special": {},
    }

    for gesture, chord in gesture_to_chord.items():
        chord_matrix["Major"][gesture] = chord if chord else None
        chord_matrix["Minor"][gesture] = (chord + "m") if chord else None
        chord_matrix["Special"][gesture] = (chord + "7") if chord else None

    print("Final Chord Matrix:")
    for chord_type, mappings in chord_matrix.items():
        print(f"\n{chord_type} Chords:")
        for gesture, chord in mappings.items():
            print(f"  {gesture}: {chord}")
    # print(chord_matrix)
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
        self.midi_chord_list = convert_chord_to_midi_chord(self.chord_list)
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
            chord = chordMatrix[area][gesture]
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
