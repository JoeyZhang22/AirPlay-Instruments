# Everything in this file has been moved to chord_decision_block.py

def generate_chord_matrix():
    # Base chord list
    chord_list = ["Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#"]

    # Initial dictionary for gesture-to-chord mappings
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

    def input_chord_types(section_name, options):
        print(f"Available chord types: {', '.join(options)}")
        
        while True:
            choice = input(f"Enter your choice for the {section_name} section: ").strip()
            if choice in options:
                print(f"You selected '{choice}' for the {section_name} section.")
                return choice
            else:
                print("Invalid choice. Please type the name of a chord from the list.")

    selected_chord_types = [] # Section selections

    sections = ["Top", "Middle", "Bottom"]
    for section in sections:
        chord_type = input_chord_types(section, chord_types.keys())
        selected_chord_types.append(chord_type)

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
            if chord in chord_list:
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

    chord_matrix = {chord_type: {} for chord_type in selected_chord_types}

    for gesture, chord in gesture_to_chord.items():
        for chord_type in selected_chord_types:
            suffix = chord_types[chord_type]
            chord_matrix[chord_type][gesture] = (chord + suffix) if chord else None

    print("Final Chord Matrix:")
    for section, mapping in chord_matrix.items():
        print(f"{section}: {mapping}")
    
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
