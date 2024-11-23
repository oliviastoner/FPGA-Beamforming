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
AUDIO_LENGTH = 6 # set to record 6 seconds of audio
BYTES = 2

MODE = 1       # Mode 0 (normal sample rate and byte length)
               # Mode 1 (1/2 sample rate and collects from 2 mics)

EFF_SAMPLE_RATE = SAMPLE_RATE if MODE == 0 else SAMPLE_RATE / 2

ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
print("Serial port initialized")

def save_bytes_as_wave(filename, samples):
    with wave.open(f'{filename}.wav', 'wb') as wf:
        wf.setframerate(EFF_SAMPLE_RATE)
        wf.setnchannels(1)
        wf.setsampwidth(BYTES)
        for sample in samples:
            wf.writeframes(sample)
        print(f"Recording saved to {filename}.wav")

def collect_audio(mic_0_data, mic_1_data):
    """
    Collects audio data for specified length and stores in arrays for mic_0 and mic_1
    """
    print(f"Recording {AUDIO_LENGTH} seconds of audio:")
    for i in range(int(EFF_SAMPLE_RATE*AUDIO_LENGTH)):
        val_mic_0 = ser.read(BYTES) # read 2 bytes of sample; 16-bit audio data
        val_mic_1 = 0

        if MODE == 1:
            val_mic_1 = ser.read(BYTES)
        
        if ((i+1)%EFF_SAMPLE_RATE==0):
            print(f"{(i+1)/EFF_SAMPLE_RATE} seconds complete")
        
        mic_0_data.append(val_mic_0)
        mic_1_data.append(val_mic_1)

    save_bytes_as_wave('mic_0', mic_0_data)
    if MODE == 1:
        save_bytes_as_wave('mic_1', mic_1_data)

def beamforming_delay(angle, distance_between_microphones, num_microphones):
    """
    Calculates the time delay for each microphone in a beamforming array 
    based on the desired steering angle and the number of microphones in the array.

    Args:
        angle: the desired steering angle in degrees.
        distance_between_microphones: the distance between microphones. (in breadboard pins)
        num_microphones: the number of microphones.

    Returns:
        np.ndarray: An array of time delays in seconds for each microphone.
    """
    
    # There are 2.54 mm between breadboard pins
    distance_mm = distance_between_microphones * 2.54
    distance_m = distance_mm / 1000

    # Calculate the delay for each microphone
    delays = np.array([(i * distance_m * np.cos(angle * np.pi / 180) / 343) for i in range(num_microphones)])

    return delays

def delay_and_sum(mic_signals, delays):
    """
    Perform delay-and-sum beamforming on multiple microphone signals.
    
    Parameters:
    - mic_signals (list of numpy arrays): List of audio signals from different microphones.
    - delays (list of float): Time delays (in seconds) to apply to each signal.

    Returns:
    - numpy array: The beamformed output signal.
    """

    # Find the maximum length of the input signals
    max_len = max((delays[i] * EFF_SAMPLE_RATE) + len(mic_signals[i]) for i in range(len(mic_signals)))

    # Apply delays (in samples) and sum
    output_signal = np.zeros(int(max_len))
    delayed_outputs = [np.zeros(int(max_len)) for i in range(len(mic_signals))]
    sample_idx = 0

    for signal, delay in zip(mic_signals, delays):

        # Calculate the number of samples to delay
        delay_samples = int(delay * EFF_SAMPLE_RATE)  # Assuming 44.1 KHz sample rate
        print(f"Number of delay samples: {delay_samples} for delay, {delay}, at {EFF_SAMPLE_RATE}")
        signal_len = len(signal)

        for i in range (delay_samples, delay_samples + signal_len):
            delayed_outputs[sample_idx][i] = signal[i-delay_samples]
            output_signal[i] += signal[i-delay_samples]

        sample_idx += 1

    return output_signal / len(mic_signals), delayed_outputs

# Example usage
if __name__ == "__main__":
    # Load the audio signals from different microphones

    # Load audio signals from files or capture recording from the microphone array

    mic_0_data = []
    mic_1_data = []
    collect_audio(mic_0_data, mic_1_data)

    mic_0_int = [int.from_bytes(sample, 'little', signed=True) for sample in mic_0_data]

    if MODE == 1:
        mic_1_int = [int.from_bytes(sample, 'little', signed=True) for sample in mic_1_data]
    else:
        mic_1_int = [0]

    # Calculate beamforming delays
    delays = beamforming_delay(90, 27, 2)

    # Perform delay-and-sum beamforming
    normalized_mic_0 = np.array(mic_0_int, dtype=np.int16).astype(np.float32) / 32768.0
    if MODE == 1:
        normalized_mic_1 = np.array(mic_1_int, dtype=np.int16).astype(np.float32) / 32768.0
        beamformed_signal, delayed_outputs = delay_and_sum([normalized_mic_0, normalized_mic_1], delays)

        # Save the output beamformed signal
        sf.write('beamformed_output.wav', beamformed_signal, int(EFF_SAMPLE_RATE))

    # Optionally, display the waveforms of the input and output
    # plt.figure(figsize=(10, 6))
    plt.subplots(3, 1, sharey=True)

    plt.subplot(3, 1, 1)
    librosa.display.waveshow(normalized_mic_0, sr=EFF_SAMPLE_RATE, label='Mic 1', color='#ADD8E6')
    plt.legend()

    if MODE == 1:
        plt.subplot(3, 1, 2)
        librosa.display.waveshow(normalized_mic_1, sr=EFF_SAMPLE_RATE, label='Mic 2', color='#87CEEB')
        plt.legend()

        plt.subplot(3, 1, 3)
        librosa.display.waveshow(beamformed_signal, sr=EFF_SAMPLE_RATE, label='Beamformed Output', color='#00000B')
        plt.legend()

    plt.tight_layout()
    plt.show()
