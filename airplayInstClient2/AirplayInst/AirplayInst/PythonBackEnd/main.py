import threading
import queue
import time

# Import Graphic Modules
import MediaPipe.argument_parser as argument_parser
import MediaPipe.graphic as graphic

# Import Decision Blocks
from DataProcessing.chord_decision_block import chordDecisionBlock
from DataProcessing.percussion_decision_block import percussionDecisionBlock


def decision_block(result_event, result_queue, decision_block_object):
    while True:
        # Wait for signal from the graphic thread
        result_event.wait()

        # Process data if available
        try:
            while True:
                results = (
                    result_queue.get()
                )  # changed to .get instead of no_wait() as no_wait() raises exception if queue is empty
                # Decision block logic processing recognition results

                """decision block code here"""
                decision_block_object.decision_maker(results)
                break
        except queue.Empty:
            # No more data to process, reset the event
            result_event.clear()


def main():
    # Get the command line arguments
    args = argument_parser.add_argument()

    # Create a queue to hold data from graphic
    result_queue = queue.Queue()
    result_event = threading.Event()

    # Initialize Decision Block
    decision_block_object = percussionDecisionBlock()

    # Create a thread to run graphic.run_graphic
    decision_thread = threading.Thread(
        target=decision_block,  # Pass the function reference, not a function call
        kwargs={
            "result_queue": result_queue,
            "result_event": result_event,
            "decision_block_object": decision_block_object,
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
        args.handedness,
        "Percussion",   # Insturment Mode, "Percussion" or "Expressive"
    )


if __name__ == "__main__":
    main()
