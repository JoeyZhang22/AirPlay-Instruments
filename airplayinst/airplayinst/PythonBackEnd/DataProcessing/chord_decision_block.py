from enum import Enum
from MIDI.chord_player import *
from DataProcessing.gesture_matrix import generate_mappings


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


# Use current instrument state and previous instrument state to 
# determine the corresponding action
"""Corresponding action can be determined via: 
decisionMatrix[prev_state][cur_state] where 
prev_state and cur_state are instrumentState enums"""
decisionMatrix = [
    [actions.NULL, actions.PLAY, actions.PLAY_REVERSE],
    [actions.STOP, actions.NULL, actions.PLAY_REVERSE],
    [actions.STOP, actions.PLAY, actions.NULL],
]

class chordDecisionBlock:
    def __init__(self, output_port="Logic Pro Virtual In", config_file_path = "../MIDI/gesture_mappings.json"):
        print("chordDecisionBlock Initialized!")
        self.output_port = mido.open_output(output_port)
        self.chordMatrix, self.config = generate_mappings(config_path=config_file_path)
        self.get_chords_list(chord_matrix=self.chordMatrix)
        self.midi_chord_list = convert_chord_to_midi_chord(self.chord_list)
        self.state = instrumentState.NEUTRAL
        self.prev_chord_index = -1  # Initialized to -1 to indicate no previous chord
        self.chord_hand = None
        self.strum_hand = None

    def get_chords_list(self,chord_matrix):
        all_chords = set()
        for mappings in chord_matrix.values():
            all_chords.update(chord for chord in mappings.values() if chord is not None)
        
        self.chord_list = list(all_chords)
        print(self.chord_list)

    def update_state(self, recognizer_results):
        if len(recognizer_results) < 2:  # Only one hand detected
            print("update state: NEUTRAL")
            self.state = instrumentState.NEUTRAL
        else:
            self.getHands(recognizer_results)
            if (
                self.chord_hand is not None and
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
            chord = self.midi_chord_list[self.chordMatrix[area][gesture]]
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
                # sleep(0.05)
        else:
            for note in reversed(chord):
                self.output_port.send(note_on(note=note))
                # sleep(0.05)

    def off(self, chord):
        for note in chord:
            self.output_port.send(note_off(note=note))
