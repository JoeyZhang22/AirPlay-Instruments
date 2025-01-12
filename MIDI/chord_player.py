import mido
from mingus.core import chords, notes
from mingus.containers import Note, NoteContainer
from time import sleep


# Convert [Note Letters -> Int]
"""Need to expand on the this function to essentially parse a string array of various chords and map gestures to corresponding MIDI chords"""


# def convert_chord_to_midi_chord(chord_list):
#     midi_chords = []  # integers
#     add_octave = 0
#     for chord in chord_list:
#         # collect chord_notes(ie. C-1,E-4,A-4,etc.)
#         chord_notes = NoteContainer(chords.from_shorthand(chord))

#         # convert notes to MIDI integer
#         chord_ints = [
#             int(note) + add_octave for note in chord_notes
#         ]  # add int 12 to ensure proper C-4 key

#         # Append chord_ints to midi_chordds
#         midi_chords.append(chord_ints)

#     return midi_chords

def convert_chord_to_midi_chord(chord_list):
    midi_chord_dict = {}  # Dictionary to store chord name -> MIDI mapping
    add_octave = 0  # Optional adjustment for octaves

    for chord in chord_list:
        chord_notes = NoteContainer(chords.from_shorthand(chord))

        chord_ints = [int(note) + add_octave for note in chord_notes]

        midi_chord_dict[chord] = chord_ints

    return midi_chord_dict

def note_on(note, velocity=64, time=2):
    return mido.Message("note_on", note=note, velocity=velocity, time=time)


def note_off(note, velocity=63, time=2):
    return mido.Message("note_off", note=note, velocity=velocity, time=time)
