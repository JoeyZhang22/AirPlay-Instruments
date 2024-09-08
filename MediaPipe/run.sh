NUM_HANDS=2
MIN_HAND_DETECT_CONFIDENCE=0.5
WIDTH=1280
HEIGHT=720

python3 recognize.py    --model gesture_recognizer.task   --numHands $NUM_HANDS   --minHandDetectionConfidence $MIN_HAND_DETECT_CONFIDENCE\
                        --frameWidth $WIDTH --frameHeight $HEIGHT