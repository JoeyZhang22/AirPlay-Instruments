# Main scripts

import threading
import queue
import time

import argument_parser
import graphic
def get_velocity(arr):
    velocity = 5
    return velocity
def get_direction(arr):
    direction = "up"
    return direction
def get_duration(arr):
    duration = 5
    return duration

def create_strum(strum_tracking): 
    velocity = get_velocity(strum_tracking)
    direction = get_direction(strum_tracking)
    duration = get_duration(strum_tracking)
    strum = {}
    strum["velocity"] = velocity
    strum["duration"] = duration
    strum["direction"] = direction
    return strum




def decision_block(result_event, result_queue):
    strum_track_list = []
    while True:
        # Wait for signal from the graphic thread
        print("here in loop")
        result_event.wait()

        # Process data if available
        strum_track_list = []
        try:
            while True:
                results = (
                    result_queue.get()
                )  
                for ele in results:
                    #print("this")
                    #print (ele)
                    print (results)
                    if ele['Handedness'] == 'Right' and ele['Gesture_Type'] == 'Thumb_Up' and ele['Score'] > 0.5:
                        current_time = time.time
                        strum_start = ele['Gesture_Landmarks']
                        coords = strum_start[4]
                        just_y = coords.y
                        #print("got to bottom of if before append")
                        my_tuple = (just_y, current_time)
                        strum_track_list.append(my_tuple)

                    elif ele['Gesture_Type'] != 'Thumb_up':
                        if len(strum_track_list) == 0:
                            continue
                        else:
                            print("creating")
                            strum = create_strum(strum_track_list)
                            strum_track_list.clear()
                            print(strum)
                        #print(ele)  
                # changed to .get instead of no_wait() as no_wait() raises exception if queue is empty
                # Decision block logic processing recognition results

                """decision block code here"""

               # print(results)
        except queue.Empty:
            # No more data to process, reset the event
            result_event.clear()


def main():
    # Get the command line arguments
    args = argument_parser.add_argument()

    # Create a queue to hold data from graphic
    result_queue = queue.Queue()
    result_event = threading.Event()

    # Create a thread to run graphic.run_graphic
    decision_thread = threading.Thread(
        target=decision_block,  # Pass the function reference, not a function call
        kwargs={
            "result_queue": result_queue,
            "result_event": result_event,
        },  # Pass arguments
    )

    # Start the graphic thread
    decision_thread.start()

    graphic.run_graphic(
        args.model,
        int(args.numHands),
        float(args.minHandDetectionConfidence),
        args.minHandPresenceConfidence,
        args.minTrackingConfidence,
        int(args.cameraId),
        int(args.frameWidth),
        int(args.frameHeight),
        False,  # This is assuming the 'False' flag is relevant to your logic
        result_queue,  # Queue object for passing results
        result_event,  # Event object for signaling
    )


if __name__ == "__main__":
    main()
