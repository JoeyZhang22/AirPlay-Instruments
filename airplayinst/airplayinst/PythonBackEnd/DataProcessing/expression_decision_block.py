# PS: this is airplay instrument's answer to AIRWAVE

# states:
# 1. NEUTRAL
# 2. ON (Both hands on screen)

# Track vibrato and loudness
# 1. Vertical displacement = Track current height to send loudness signal
# 2. Horizontal displacement = Track delta of horizontal movement between two frames to send vibrato signal

"""
Additional effects:
1 = Modulation wheel
2 = Breath Control
7 = Volume
10 = Pan
11 = Expression
64 = Sustain Pedal (on/off)
65 = Portamento (on/off)
71 = Resonance (filter)
74 = Frequency Cutoff (filter)

Number corresponds to MIDI Continuos Controller channel number
"""

"""
Loudness control: Vertical value
Modulation (pitch bend): Openess
Panning: Horizontal value
"""

from enum import Enum
from MIDI.continuous_player import *
from MIDI.chord_player import *
from DataProcessing.gesture_matrix import generate_mappings

# Maintain instrument states
class expressiveInstrumentState(Enum):
    NEUTRAL = 0
    ON = 1
    CONTROL = 2


class actions(Enum):
    PLAY = 0
    NULL = 1
    MANIPULATE = 2
    STOP = 3


decisionMatrix = [
    [actions.NULL, actions.PLAY, actions.NULL], 
    [actions.STOP, actions.NULL, actions.MANIPULATE],
    [actions.STOP, actions.NULL, actions.MANIPULATE],
]

MIDI_expressive_control_mapping = {
    "Volume": 1,
    "Balance": 7,  # value of 64 is center
    "Modulation": 1,  # controls vibrato effect
}

class expressiveDecisionBlock:
    def __init__(self, output_port="Logic Pro Virtual In", config_file_path = "/gesture_mappings.json"): # "Logic Pro Virtual In"
        print("expressiveDecisionBlock Initialized!")
        self.output_port = mido.open_output(output_port)
        self.chordMatrix = generate_mappings(config_path=config_file_path)
        self.get_chords_list(chord_matrix=self.chordMatrix)
        self.midi_chord_list = convert_chord_to_midi_chord(self.chord_list)
        self.state = expressiveInstrumentState.NEUTRAL
        self.prev_state = expressiveInstrumentState.NEUTRAL
        self.prev_chord_index = -1  # Initialized to -1 to indicate no previous chord
        self.chord_hand = None
        self.control_hand = None

    def get_chords_list(self,chord_matrix):
        all_chords = set()
        for mappings in chord_matrix.values():
            all_chords.update(chord for chord in mappings.values() if chord is not None)
        
        self.chord_list = list(all_chords)
        print(self.chord_list)

    def getHands(
        self, recognizer_results
    ):  # Only call when recognizer_results length == 2
        assert len(recognizer_results) == 2
        for hand in recognizer_results:
            if hand.get("Handedness") == "Left":
                self.chord_hand = hand
            else:
                self.control_hand = hand

    def update_state(self, recognizer_results):
        self.prev_state = self.state
        if len(recognizer_results) < 2:  # Only one hand detected
            print("update state: NEUTRAL")
            self.state = expressiveInstrumentState.NEUTRAL
        else:
            self.getHands(recognizer_results)
            if (
                self.chord_hand is not None and
                self.chord_hand.get("Gesture_Type") == "None"
                or self.chord_hand.get("Area") == "None"
                or self.control_hand.get("Area") == "None"
            ):
                self.state = expressiveInstrumentState.NEUTRAL
            else:
                if self.control_hand.get("Area") == "Manipulation":
                    if self.prev_state == expressiveInstrumentState.ON:
                        self.state = expressiveInstrumentState.CONTROL
                    else:
                        self.state = expressiveInstrumentState.ON
                else:
                    self.state = expressiveInstrumentState.NEUTRAL

    def decision_maker(self, recognizer_results):
        self.update_state(recognizer_results)

        print("previous state: ", self.prev_state)
        print("current state: ", self.state)

        action = decisionMatrix[self.prev_state.value][self.state.value]

        if action == actions.PLAY:
            print(recognizer_results)
            gesture = self.chord_hand.get("Gesture_Type")
            area = self.chord_hand.get("Area")
            print("left hand gesture: ", gesture)
            print("left hand area: ", area)
            chord = self.midi_chord_list[chordMatrix[area][gesture]]
            self.actor(perform_action=action, chord=chord)
        elif action == actions.MANIPULATE:
            print(recognizer_results)
            openess = self.control_hand.get("Openess")
            xPositionRatio = self.control_hand.get("Local_Position")[0]
            yPositionRatio = self.control_hand.get("Local_Position")[1]
            chord = self.prev_chord_index
            self.actor(perform_action=action, chord=chord, controls = (openess,xPositionRatio,yPositionRatio))
        else:
            # for STOP
            self.actor(perform_action=action, chord=self.prev_chord_index)


    def actor (self, perform_action, chord, controls = (0,0.5,1), interval = 0.01):
        if perform_action== actions.PLAY:
            send_chord(self.output_port, chord, velocity=64)
            self.prev_chord_index= chord
        elif perform_action == actions.MANIPULATE:
            send_continuous_control(self.output_port,controls=controls)
            self.prev_chord_index= chord
        elif perform_action == actions.STOP:
            turn_off_chord(output_port=self.output_port, chord=chord)