# Main scripts

import threading
import queue
import time

import argument_parser
import graphic


def main():
  # Get the command line arguments
  args = argument_parser.add_argument()

  # Create a queue to hold data from graphic
  result_queue = queue.Queue()
  result_event = threading.Event()

  # Start the graphic thread at the background
  graphic_thread = threading.Thread(
    target = graphic.run_graphic,
    args = (
      args.model, int(args.numHands), 
      float(args.minHandDetectionConfidence),
      args.minHandPresenceConfidence, args.minTrackingConfidence,
      int(args.cameraId), int(args.frameWidth), int(args.frameHeight), 
      False, result_queue, result_event)
  )
  graphic_thread.start()

  while True:
    # Wait for signal from the graphic thread
    result_event.wait() 

    # Process data if available
    try:
      while True:
        results = result_queue.get_nowait()
        # Decision block logic processing recognition results
        print(results)
    except queue.Empty:
      # No more data to process, reset the event
      result_event.clear()

  print("Exit .......")

if __name__ == '__main__':
  main()