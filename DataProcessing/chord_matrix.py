# Everything in this file has been moved to chord_decision_block.py

def generate_chord_matrix():
    # Base chord list
    chord_list = ["Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#"]

    # Initial empty dictionary for gesture-to-chord mappings
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

    # Chords with associated MIDI suffixes
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

    # Default gesture-to-chord mapping
    default_gesture_to_chord = {
        "Closed_Fist": "C", 
        "Open_Palm": "D",
        "Pointing_Up": "E",
        "Thumb_Down": "F",
        "Thumb_Up": "G",
        "Victory": "A",
        "ILoveYou": "B",
        "None": None
    }

    # Default chord types for Top, Middle, and Bottom sections
    default_chord_types = ["Major", "Minor", "Dominant7"]

    # Function to get user selected chord types
    def get_chord_types():
        print("\nWould you like to use the default chord types? (yes/no)")
        choice = input().strip().lower()

        if choice == "yes":
            return default_chord_types

        print("\nAvailable chord types:", ", ".join(chord_types.keys()))
        
        selected_chord_types = []

        for i, section in enumerate(["Top", "Middle", "Bottom"]):
            while True:
                choice = input(f"Choose a chord type for the {section} section: ").strip()
                if choice in chord_types:
                    selected_chord_types.append(choice)
                    break
                else:
                    print("Invalid choice. Please type the name of a chord from the list.")
        return selected_chord_types
    
    def get_gesture_mapping():
        available_gestures = list(gesture_to_chord.keys()) 

        print("\nWould you like to use the default gesture-to-chord mapping? (yes/no)")
        choice = input().strip().lower()

        if choice == "yes":
            return default_gesture_to_chord
        
        custom_mapping = {}

        while True:
            print("\nAvailable gestures:", ", ".join(available_gestures))
            gesture = input("Enter a gesture name (or type 'done' to finish): ").strip()
            
            if gesture.lower() == "done":
                break
            if gesture not in available_gestures:
                print("Invalid gesture. Please choose from the available gestures.")
                continue

            chord = input(f"Enter the chord for {gesture}: ").strip()
            custom_mapping[gesture] = chord

            print("\nCurrent Mapping:")
            for g, c in custom_mapping.items():
                print(f"  {g}: {c}")

        return custom_mapping if custom_mapping else default_gesture_to_chord

    gesture_to_chord = get_gesture_mapping()
    selected_chord_types = get_chord_types()

    chord_matrix = {chord_type: {} for chord_type in selected_chord_types}

    for gesture, chord in gesture_to_chord.items():
        for chord_type in selected_chord_types:
            suffix = chord_types[chord_type]
            chord_matrix[chord_type][gesture] = (chord + suffix) if chord else None

    print("\nFinal Chord Matrix:")
    for section, mapping in chord_matrix.items():
        filtered_mapping = {gesture: chord for gesture, chord in mapping.items() if chord is not None}
        print(f"{section}: {filtered_mapping}")

    return chord_matrix

chordMatrix = generate_chord_matrix()
