import serial
import numpy as np
import matplotlib.pyplot as plt
import wave
import librosa
import librosa.display
import soundfile as sf
import time

# note: we will need to change our BAUD rate to match the clock we run our UART transmission at.
# we will also need to change SAMPLE_RATE to the correct value.
# however, we will keep it consistent with the BAUD/sampling rate from the audio sampling lab for now.

# Set up serial communication
SERIAL_PORT_NAME = "/dev/ttyUSB1"#"/dev/cu.usbserial-88742923021D1"
BAUD_RATE = 921600
SAMPLE_RATE = 39062.5 # capturing samples at 8 kHz; will change
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

def collect_uart_audio():
    """
    Collects uart audio data for specified length and stores in arrays for mic_0 and mic_1
    """
    print(f"Recording {AUDIO_LENGTH} seconds of audio:")
    uart_data = []
    time_start = time.time()
    for i in range(int(SAMPLE_RATE*AUDIO_LENGTH)):
        for _ in range(BYTES):
            val = ser.read(1) # read 2 bytes of sample; 16-bit audio data
            uart_data.append(val)

        if ((i+1)%int(SAMPLE_RATE)==0):
            print(f"{round((i+1)/SAMPLE_RATE)} seconds complete")

    time_end = time.time()
    print(f"Time elapsed: {time_end - time_start}")
    return uart_data

def convert_uart_to_audio(uart_data_in: list[bytes]):
    audio_data = []
    uart_data: list[bytes] = uart_data_in[::-1]
    while uart_data:
        audio_sample = 0
        audio_valid = False
        # Iterate over the number of bytes
        for i in range(2):
            data = None
            alignment_bit = None
            
            # Check the alignment bit of the byte
            while alignment_bit != i and uart_data:
                if alignment_bit is not None:
                    print("Alignment missed")

                uart_byte = uart_data.pop()
                data = 0b1111111 & ord(uart_byte)
                alignment_bit = ord(uart_byte) >> 7
            
            if data is None:
                print("No data")
                audio_valid = False
                break
            elif i == 0:
                audio_sample += data
            elif i == 1:
                audio_sample += data << 7
                audio_valid = True
        
        if audio_valid:
            if audio_sample & (1 << 13):
                audio_sample -= 1 << 14

            audio_data.append(audio_sample << 2) # shift data to 16 bit
        else:
            continue
              
    return audio_data


def plot_frequencies(audio_signal):
    n = len(audio_signal)
    frequencies = np.fft.rfftfreq(n, d=1/SAMPLE_RATE)  # Frequency range
    fft_magnitude = np.abs(np.fft.rfft(audio_signal)) 


def collect_sweep(inputs, save_audio = True):
    all_sweeps = {}
    for _ in range(inputs):
        angle = int(input("Enter the angle the beamformer is set to: "))
        sweep_data = collect_uart_audio()

        all_sweeps[angle] = sweep_data

    plt.subplots(inputs, 1, sharey=True)
    count = 1
    for angle, sweep_data in all_sweeps.items():
        plt.subplot(inputs, 1, count)
        audio_data = convert_uart_to_audio(sweep_data)

        if save_audio:
            save_bytes_as_wave(f"beam_ang_{angle}", [sample.to_bytes(2, 'little', signed=True) for sample in audio_data])

        normalized_sweep = np.array(audio_data, dtype=np.int16).astype(np.float32) / 32768.0
        librosa.display.waveshow(normalized_sweep, sr=SAMPLE_RATE, label=f'{angle} deg', color='#00000B')
        plt.legend()
        count+=1

    plt.tight_layout()
    plt.show()

    plt.subplots(inputs, 1, sharey=True, sharex=True)
    count = 1
    for angle, sweep_data in all_sweeps.items():
        plt.subplot(inputs, 1, count)
        audio_data = convert_uart_to_audio(sweep_data)

        n = len(audio_data)
        frequencies = np.fft.rfftfreq(n, d=1/SAMPLE_RATE)  # Frequency range
        fft_magnitude = np.abs(np.fft.rfft(audio_data)) 

        plt.subplot(inputs, 1, count)
        plt.plot(frequencies, fft_magnitude)
        plt.title(f"Frequency Spectrum {angle}")
        plt.xlabel("Frequency (Hz)")
        plt.ylabel("Amplitude")
        plt.grid()
        plt.legend()
        count+=1

    plt.tight_layout()
    plt.show()

# Example usage
if __name__ == "__main__":
    while True:
        sweeps = int(input("Enter the number of sweeps to collect: "))
        collect_sweep(sweeps)
        # collect_audio(None)
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