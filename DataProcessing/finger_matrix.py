# Implementing the mapping based on fingering  

def generate_mappings():
    chord_types = {
        "Major": "",
        "Minor": "m",
        "Minor7": "m7",
        "Major7": "M7",
        "Dominant7": "7",
        "Diminished7": "dim7"
    }

    scales = {
        "C": ["C", "D", "E", "F", "G", "A", "B"],
        "D": ["D", "E", "F#", "G", "A", "B", "C#"],
        "E": ["E", "F#", "G#", "A", "B", "C#", "D#"],
        "F": ["F", "G", "A", "Bb", "C", "D", "E"],
        "G": ["G", "A", "B", "C", "D", "E", "F#"],
        "A": ["A", "B", "C#", "D", "E", "F#", "G#"],
        "B": ["B", "C#", "D#", "E", "F#", "G#", "A#"]
    }
    
    # Default base chords and chord types for each section
    default_base_chords = {"Top": "C", "Middle": "D", "Bottom": "E"}
    default_chord_types = {"Top": "Major", "Middle": "Minor", "Bottom": "Dominant7"}
    
    use_defaults = input("Would you like to use default mappings? (yes/no): ").strip().lower()
    
    if use_defaults == "yes":
        base_chords = default_base_chords.copy()
        section_chord_types = default_chord_types.copy()
    else:
        print("Available chord types:", ", ".join(chord_types.keys()))
        print("Available scales:", ", ".join(scales.keys()))
        
        base_chords = {}
        section_chord_types = {}
        
        for section in ["Top", "Middle", "Bottom"]:
            base_choice = input(f"Enter base chord note for {section} section (default: {default_base_chords[section]}): ").strip()
            base_chords[section] = base_choice if base_choice else default_base_chords[section]
            
            chord_choice = input(f"Enter chord type for {section} section (default: {default_chord_types[section]}): ").strip()
            section_chord_types[section] = chord_choice if chord_choice in chord_types else default_chord_types[section]
    
    finger_to_note = {}
    
    for section, base_chord in base_chords.items():
        chord_suffix = chord_types[section_chord_types[section]]
        
        finger_to_note[section] = {}
        
        for i, note in enumerate(scales[base_chord], start=1):
            hand_key = f"Hand_{i}"
            finger_to_note[section][hand_key] = note + chord_suffix
    
    print("\nGenerated Mappings:")
    for section, mapping in finger_to_note.items():
        print(f"{section}: {mapping}")
    
    return finger_to_note

generate_mappings()
