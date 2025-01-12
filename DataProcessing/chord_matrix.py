# Everything in this file has been moved to chord_decision_block.py

def generate_chord_matrix():
    # Initial dictionary for gesture-to-chord mappings
    gesture_to_chord = {
        "Closed_Fist": None, 
        "Open_Palm": None,
        "Pointing_Up": None,
        "Thumb_Down": None,
        "Thumb_Up": None,
        "Victory": None,
        "ILoveYou": None
    }

    # Base chord list
    chord_list = ["C", "D", "E", "F", "G", "A", "B"]

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

    chord_matrix = {
            "Major": {},
            "Minor": {},
            "Special": {},
    }

    for gesture, chord in gesture_to_chord.items():
        chord_matrix["Major"][gesture] = chord if chord else None
        chord_matrix["Minor"][gesture] = (chord + "m") if chord else None
        chord_matrix["Special"][gesture] = (chord + "7") if chord else None

    print("Final Chord Matrix:")
    for chord_type, mappings in chord_matrix.items():
        print(f"\n{chord_type} Chords:")
        for gesture, chord in mappings.items():
            print(f"  {gesture}: {chord}")
    # print(chord_matrix)
    
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
