# AirPlay-Instruments

**AirPlay Instruments** is a capstone project dedicated to enhancing the accessibility, ease of use, and expressiveness of musical instruments for musicians of all levels. By leveraging computer vision, radar technology, and MIDI interfaces, we aim to develop an all-in-one HCI tool that allows users to input musical information with ease, whether they are traveling musicians, producers, or beginners exploring music without the need for expensive production tools (e.g., MIDI controller keyboards, pads, actual instruments, microphones, etc.).

Welcome to AirPlay Instruments!

## Project Goals
The project proves three main ways to provide unique ways for users to input musical information. 
1. Chord based instrument
    - Provide an intuitive way to play harmonic instruments like guitar or piano.
    - Allow users to map gestures that trigger different chords
2. Percussive instrument
    - Enable users to trigger percussion sounds
    - Allow for mapping of gestures and movements to trigger different percussive instruments
3. Expressive instrument
    - Allow users to control expressive musical qualities like pitch bending and vibrato.
    - Ensure seamless MIDI CC (Control Change) messages for expressive parameters.

___

## Project Demo

[![AirPlay Instruments Demo](https://i9.ytimg.com/vi_webp/exurCb0tvK4/mq2.webp?sqp=CMS4wbsG-oaymwEmCMACELQB8quKqQMa8AEB-AHeCIAC0AWKAgwIABABGGUgYShQMA8=&rs=AOn4CLD5aI6gSZ01VDShcNZcgUTeSVDFzA)](https://youtu.be/exurCb0tvK4)

## Run AirPlay Instruments

Follow these steps to get started with AirPlay Instruments:

```bash
#Clone Repo
git clone https://github.com/JoeyZhang22/AirPlay-Instruments.git
cd AirPlay-Instruments

# Create a virtual environment
python -m venv venv

# Activate the virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

#Run
python main.py
```

# Resources Used
## MIDI

- [MIDO Documentation](https://mido.readthedocs.io/en/stable/index.html)
- [Mingus](https://bspaans.github.io/python-mingus/)
- [chords2midi](https://github.com/Miserlou/chords2midi)

## Computer Vision

- [Open CV Python](https://docs.opencv.org/4.x/index.html)
- [Mediapipe](https://ai.google.dev/edge/mediapipe/solutions/vision/gesture_recognizer/python?_gl=1*qys266*_up*MQ..*_ga*MTQwMjEzNTAwNy4xNzI1NTUyNzc3*_ga_P1DBVKWT6V*MTcyNTU1Mjc3Ni4xLjAuMTcyNTU1Mjc3Ni4wLjAuMTM5MjQ4OTI5MA..)
