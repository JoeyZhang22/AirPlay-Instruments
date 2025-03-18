from enum import Enum
from MIDI.chord_player import *


# Maintain instrument states
class percussionInstrumentState(Enum):
    NEUTRAL = 0
    HIT = 1


# Set of actions passed to the actor function for execution
class actions(Enum):
    PLAY = 0
    STOP = 1
    NULL = 2

# Use current instrument state and previous instrument state to determine the corresponding action
"""Corresponding action can be determined via: decisionMatrix[prev_state][cur_state] where prev_state and cur_state are instrumentState enums"""
decisionMatrix = [
    [actions.NULL, actions.PLAY],
    [actions.STOP, actions.STOP # test to see if actions.STOP here should be switched to actions.NULL 
    ] 
]

percussion_note_matrix = {
    # Top Corners
    "Crash Right": 57,
    "Ride Bell": 53,

    # Bottom Corners
    "Hi-Hat Open": 46,
    "Tom Low": 43,

    "Tom Mid High": 47,
    "Tom High": 48,

    "Snare Center": 38,
    "Kick":36,

    "None":0,

}

class percussionDecisionBlock:
    def __init__(self, output_port="Logic Pro Virtual In"): # "Logic Pro Virtual In"
        print("percussionDecisionBlock Initialized!")
        self.output_port = mido.open_output(output_port)
        self.state_l = percussionInstrumentState.NEUTRAL 
        self.state_r = percussionInstrumentState.NEUTRAL
        self.prev_instrument_l = None
        self.prev_instrument_r = None
        self.prev_inst_l = 0
        self.prev_inst_r = 0
        self.left_hand = None
        self.right_hand = None

    def update_state(self, hand): # pass in left_hand or right_hand
        if hand == None:
            return
        elif hand.get("Area") == "None":
            if hand.get("Handedness") == "Left":
                self.state_l = percussionInstrumentState.NEUTRAL
            else:
                self.state_r = percussionInstrumentState.NEUTRAL
        else:
            if hand.get("Handedness") == "Left":
                self.state_l = percussionInstrumentState.HIT
            else:
                self.state_r = percussionInstrumentState.HIT

    def decision_maker(self, recognizer_results):
        prev_state_l = self.state_l
        prev_state_r = self.state_r

        # Update states of both hands
        self.getHands(recognizer_results)
        print("left_hand: ", self.left_hand)
        print("right_hand: ", self.right_hand)
        self.update_state(hand=self.left_hand)
        self.update_state(hand=self.right_hand)
        print("left_hand previous state: ", prev_state_l)
        print("left_hand current state: ", self.state_l)
        print("right_hand previous state: ", prev_state_r)
        print("right_hand current state: ", self.state_r)

        action_l = decisionMatrix[prev_state_l.value][self.state_l.value]
        action_r = decisionMatrix[prev_state_r.value][self.state_r.value]   

        # Perform actions for both hands
        if action_l == actions.STOP:
            self.actor(perform_action=action_l, note=self.prev_inst_l)
        else: 
            if self.left_hand is not None:
                self.actor(perform_action=action_l, note = percussion_note_matrix[self.left_hand.get("Area")])
        if action_r == actions.STOP:
            print("here in right hand actions1")
            self.actor(perform_action=action_r, note = self.prev_inst_r)
        else: 
            if self.right_hand is not None:
                print("here in right hand actions2")
                self.actor(perform_action=action_r, note = percussion_note_matrix[self.right_hand.get("Area")])
        

    # Depending on action to be performed, call the appropriate play or off function
    def actor(self, perform_action, note):
        # Switch statement
        if perform_action == actions.PLAY:
            self.play(note=note)
        elif perform_action == actions.STOP:
            self.off(note=note)
        else:
            return

    def getHands(
        self, recognizer_results
    ):  
        print("recognizer_results in getHands: ", recognizer_results)
        # Only call when recognizer_results length == 2
        for hand in recognizer_results:
            if hand.get("Handedness") == "Left":
                print("left hand only")
                self.left_hand = hand
            else:
                self.right_hand = hand

    # Play function
    def play(self, note):  # Input has to be MIDI chord (all int notes)
        self.output_port.send(note_on(note=note))
        sleep(0.10)
        self.output_port.send(note_off(note=note))

    def off(self, note):
        self.output_port.send(note_off(note=note))
