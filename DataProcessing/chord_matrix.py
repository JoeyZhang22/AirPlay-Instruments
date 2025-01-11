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

chord_list = ["C", "D", "E", "F", "G", "A", "B"]

# Function to generate the chord matrix
def chord_matrix_generator(dictionary):
    chord_matrix = {
        "Major": {},
        "Minor": {},
        "Special": {},
    }

    for gesture, chord in dictionary.items():
        if chord:  # Ensure chord is not None
            chord_matrix["Major"][gesture] = chord
            chord_matrix["Minor"][gesture] = chord + "m"
            chord_matrix["Special"][gesture] = chord + "7"

    return chord_matrix

# Function to map a chord to a gesture
def map_chord_to_gesture():
    print("Available gestures: ")
    for gesture in gesture_to_chord:
        print(f"{gesture}")

    gesture = input("\nEnter the gesture you'd like to map (e.g., 'Closed_Fist'): ")

    if gesture in gesture_to_chord:
        chord = input(f"Enter the chord you'd like to map to {gesture}: ")
        gesture_to_chord[gesture] = chord
        print(f"Mapped {chord} to {gesture}.")
    else:
        print(f"Gesture '{gesture}' not found. Please choose a valid gesture from the list.")

# Function to display the current gesture-to-chord mappings
def display_mappings():
    print("\nCurrent Gesture-to-Chord Mappings:")
    for gesture, chord in gesture_to_chord.items():
        print(f"{gesture}: {chord if chord else 'None'}")

# Main loop
while True:
    map_chord_to_gesture()
    display_mappings()

    continue_mapping = input("\nWould you like to map another gesture? (yes/no): ").lower()
    if continue_mapping != 'yes':
        break

# Display the final chord matrix
final_chord_matrix = chord_matrix_generator(gesture_to_chord)
print("Final Chord Matrix:")
for chord_type, mappings in final_chord_matrix.items():
    print(f"\n{chord_type} Chords:")
    for gesture, chord in mappings.items():
        print(f"  {gesture}: {chord}")
