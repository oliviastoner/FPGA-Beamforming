import serial
import numpy as np
import matplotlib.pyplot as plt
import wave

# note: we will need to change our BAUD rate to match the clock we run our UART transmission at.
# we will also need to change SAMPLE_RATE to the correct value.
# however, we will keep it consistent with the BAUD/sampling rate from the audio sampling lab for now.

# Set up serial communication
SERIAL_PORT_NAME = "/dev/ttyUSB1" #"/dev/cu.usbserial-8874292302D41"
BAUD_RATE = 115200
SAMPLE_RATE = 8000 # capturing samples at 8 kHz; will change
AUDIO_LENGTH = 6 # set to record 6 seconds of audio
ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
print("Serial port initialized")

# record AUDIO_LENGTH seconds of audio
print(f"Recording {AUDIO_LENGTH} seconds of audio:")
ypoints = []
for i in range(SAMPLE_RATE*AUDIO_LENGTH):
    val = int.from_bytes(ser.read(2),'little') # read 2 bytes of sample; 16-bit audio data
    if ((i+1)%SAMPLE_RATE==0):
        print(f"{(i+1)/SAMPLE_RATE} seconds complete")
    ypoints.append(val)

# save audio to wavefile
with wave.open('output.wav','wb') as wf:
    wf.setframerate(SAMPLE_RATE)
    wf.setnchannels(1)
    wf.setsampwidth(2) # 16 bits = 2 byte sample width
    samples = bytearray(ypoints)
    wf.writeframes(samples)
    print("Recording saved to output.wav")

# Convert to numpy array for processing
audio_samples = np.array(ypoints, dtype=np.int16)

# Plot the audio samples
plt.plot(audio_samples)
plt.title('Audio Samples')
plt.xlabel('Sample Index')
plt.ylabel('Amplitude')
plt.show()
