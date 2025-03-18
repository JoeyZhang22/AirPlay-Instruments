import mido
from mingus.core import chords, notes
from mingus.containers import Note, NoteContainer
from time import sleep

import mido
from time import sleep

# Sent the first time when play state is discovered
def send_chord(output_port, chord, velocity=64):
    """
    Sends a MIDI chord (note_on messages).

    Parameters:
        output_port (mido.ports.IOPort): The MIDI output port.
        chord (list): A list of MIDI note numbers.
        velocity (int): Note velocity (default=64).
    """
    for note in chord:
        output_port.send(mido.Message("note_on", note=note, velocity=velocity))
import mido
import time

def send_continuous_control(output_port, controls=(0.5, 0.5, 1), interval=0.01):
    """
    Sends continuous control changes while the instrument is active.

    Parameters:
        output_port (mido.ports.IOPort): The MIDI output port.
        controls (tuple of float): (pitch_bend, panning, volume) values between 0 and 1.
        interval (float): Time in seconds between updates.
    """
    # Extract values
    pitch_bend, panning, volume = controls

    cc_values = {
        10: int(panning * 127), # Panning (CC 10)
        7: int(volume * 127)     # Volume (CC 7)
    }

    # Scale pitch bend (0 to 1) -> (-8192 to 8191)
    pitch_bend_value = int((pitch_bend * 16383) - 8192)

    for cc_num, value in cc_values.items():
        output_port.send(mido.Message("control_change", control=cc_num, value=value))

    # Send pitch bend separately
    output_port.send(mido.Message("pitchwheel", pitch=pitch_bend_value))

    time.sleep(interval)  # Adjust based on desired control frequency


def turn_off_chord(output_port, chord):
    """
    Turns off a chord (note_off messages).

    Parameters:
        output_port (mido.ports.IOPort): The MIDI output port.
        chord (list): A list of MIDI note numbers.
    """
    for note in chord:
        output_port.send(mido.Message("note_off", note=note, velocity=64))