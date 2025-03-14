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

from enum import Enum

# Maintain instrument states
class instrumentState(Enum):
    NEUTRAL = 0
    ON = 1

class actions(Enum):
    PlAY = 0
    STOP = 1
    MODULATE = 2


