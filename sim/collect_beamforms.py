import serial
import numpy as np
import matplotlib.pyplot as plt
import wave
import librosa
import librosa.display
import soundfile as sf

# note: we will need to change our BAUD rate to match the clock we run our UART transmission at.
# we will also need to change SAMPLE_RATE to the correct value.
# however, we will keep it consistent with the BAUD/sampling rate from the audio sampling lab for now.

# Set up serial communication
SERIAL_PORT_NAME = "/dev/cu.usbserial-88742923021D1"
BAUD_RATE = 921600
SAMPLE_RATE = 31250 # capturing samples at 8 kHz; will change
AUDIO_LENGTH = 4 # set to record 6 seconds of audio
BYTES = 2

ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
print("Serial port initialized")

def save_bytes_as_wave(filename, samples):
    with wave.open(f'{filename}.wav', 'wb') as wf:
        wf.setframerate(SAMPLE_RATE)
        wf.setnchannels(1)
        wf.setsampwidth(BYTES)
        for sample in samples:
            wf.writeframes(sample)
        print(f"Recording saved to {filename}.wav")

def collect_audio(mic_name):
    """
    Collects audio data for specified length and stores in arrays for mic_0 and mic_1
    """
    print(f"Recording {AUDIO_LENGTH} seconds of audio:")
    mic_data = []
    for i in range(int(SAMPLE_RATE*AUDIO_LENGTH)):
        val = ser.read(BYTES) # read 2 bytes of sample; 16-bit audio data

        if ((i+1)%SAMPLE_RATE==0):
            print(f"{(i+1)/SAMPLE_RATE} seconds complete")
        
        mic_data.append(val)

    save_bytes_as_wave(mic_name, mic_data)

    return mic_data


def collect_sweep(inputs):
    all_sweeps = {}
    for _ in range(inputs):
        angle = int(input("Enter the angle the beamformer is set to: "))
        sweep_data = collect_audio(f"beam_ang_{angle}")

        all_sweeps[angle] = sweep_data

    plt.subplots(inputs, 1, sharey=True)
    count = 1
    for angle, sweep_data in all_sweeps.items():
        plt.subplot(inputs, 1, count)
        int_sweep_data = [int.from_bytes(sample, 'little', signed=True) for sample in sweep_data]
        normalized_sweep = np.array(int_sweep_data, dtype=np.int16).astype(np.float32) / 32768.0
        librosa.display.waveshow(normalized_sweep, sr=SAMPLE_RATE, label=f'{angle} deg', color='#00000B')
        plt.legend()
        count+=1

    plt.tight_layout()
    plt.show()

# Example usage
if __name__ == "__main__":
    while True:
        sweeps = int(input("Enter the number of sweeps to collect: "))
        collect_sweep(sweeps)
    # wav_96 = sf.read("beam_ang_96.wav")
    # wav_64 = sf.read("beam_ang_64.wav")
    # wav_32 = sf.read("beam_ang_32.wav")

    # librosa.display.waveshow(wav_96[0], sr=wav_96[1], color='red')
    # librosa.display.waveshow(wav_64[0], sr=wav_64[1], color='blue')
    # librosa.display.waveshow(wav_32[0], sr=wav_32[1], color='green')
    # plt.show()
    # # print(f"Ang 96 avg val -- {sum(map(abs, wav_96[0])) / len(wav_96[0])}")
    # # print(f"Ang 64 avg val -- {sum(map(abs, wav_64[0])) / len(wav_64[0])}")
    # # print(f"Ang 32 avg val -- {sum(map(abs, wav_32[0])) / len(wav_32[0])}")