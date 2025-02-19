# This File explores the basic usage of sending chord information in real time to Logic Pro Virtual Instrument Port via mido message port

""" 
Setting up Mido Library
Source: https://natespilman.com/blog/playing-chords-with-mido-and-python
"""

import mido
from time import sleep


def note(note, velocity=64, time=2):
    return mido.Message("note_on", note=note, velocity=velocity, time=time)


def note_off(note, velocity=63, time=2):
    return mido.Message("note_off", note=note, velocity=velocity, time=time)


# print all available ports:
print(mido.get_output_names())
outport = mido.open_output(
    "Logic Pro Virtual In"
)  # IAC: Inter-Application Communication

"""
IAC is used to create a BUS connection to allow transfer of information from MIDI Keyboard app to MIDI synthesizer app
source : https://support.apple.com/en-ca/guide/audio-midi-setup/ams1013/mac
"""


def majorChord(root, duration):
    outport.send(note(root))
    outport.send(note(root + 4))
    outport.send(note(root + 7))
    sleep(duration)
    outport.send(note_off(root))
    outport.send(note_off(root + 4))
    outport.send(note_off(root + 7))


def minorChord(root, duration):
    outport.send(note(root))
    outport.send(note(root + 3))
    outport.send(note(root + 7))
    sleep(duration)
    outport.send(note_off(root))
    outport.send(note_off(root + 3))
    outport.send(note_off(root + 7))


def dominantSeventhChords(root, duration):
    outport.send(note(root))
    outport.send(note(root + 3))
    outport.send(note(root + 7))
    outport.send(note(root + 10))
    sleep(duration)
    outport.send(note_off(root))
    outport.send(note_off(root + 3))
    outport.send(note_off(root + 7))
    outport.send(note_off(root + 10))


def diminishedSeventhChords(root, duration):
    outport.send(note(root))
    outport.send(note(root + 3))
    outport.send(note(root + 6))
    outport.send(note(root + 9))
    sleep(duration)
    outport.send(note_off(root))
    outport.send(note_off(root + 3))
    outport.send(note_off(root + 6))
    outport.send(note_off(root + 9))


# Chord Progression Example
C = 60
G = 55
A = 57
F = 53

while True:
    majorChord(C, 1)
    majorChord(G, 1)
    minorChord(A, 1)
    majorChord(F, 1)
    minorChord(F, 1)
    dominantSeventhChords(G, 1)
    diminishedSeventhChords(C, 1)
