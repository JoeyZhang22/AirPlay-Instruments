import mido
from mingus.core import chords, notes
from mingus.containers import NoteContainer, Note
from time import sleep

# Example Chord list
chord_list = ["Cmin7", "F7", "Gmaj7", "Dmin"]


# Convert [Note Letters -> Int]
def convert_chord_to_midi_chord(chord_list):
    midi_chords = []  # integers
    for chord in chord_list:

        # collect chord_notes(ie. C-1,E-4,A-4,etc.)
        chord_notes = NoteContainer(chords.from_shorthand(chord))

        # convert notes to MIDI integer
        chord_ints = [
            int(note) + 12 for note in chord_notes
        ]  # add int 12 to ensure proper C-4 key

        # Append chord_ints to midi_chordds
        midi_chords.append(chord_ints)

    return midi_chords


def note_on(note, velocity=64, time=2):
    return mido.Message("note_on", note=note, velocity=velocity, time=time)


def note_off(note, velocity=63, time=2):
    return mido.Message("note_off", note=note, velocity=velocity, time=time)


# play function
def play(chord, duration):  # input has to be midi chord (all int notes)
    for note in chord:
        outport.send(note_on(note=note))

    sleep(duration)

    for note in chord:
        outport.send(note_off(note=note))


# print all available ports:
print(mido.get_output_names())
outport = mido.open_output(
    "Logic Pro Virtual In"
)  # IAC: Inter-Application Communication

while True:
    for chord in midi_chords:
        play(chord=chord, duration=1)
