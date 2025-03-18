import json
import os
from pathlib import Path

def generate_mappings(config_path="/gesture_mappings.json"):
    script_dir = Path(__file__).parent.resolve()  # Get absolute path of script's directory
    config_path = script_dir / config_path  # Combine paths safely
    print(config_path)

    if not config_path.exists():
        print(f"Error: {config_path} not found.")
        return None
    try:
        print("Try path")
        with open(config_path, "r") as json_file:
            loaded_data = json.load(json_file)
    except FileNotFoundError:
        print("Error: gesture_mappings.json not found.")
        return None
    
    gesture_to_chord = loaded_data.get("gesture_to_chord", {})
    default_sections = loaded_data.get("chord_types", [])

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

    chord_matrix = {section: {} for section in default_sections}
    for section in default_sections:
        for gesture, chord in gesture_to_chord.items():
            suffix = chord_types.get(section, "")
            if chord:
                chord_matrix[section][gesture] = chord + suffix
    return chord_matrix
