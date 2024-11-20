import numpy as np
import librosa
import librosa.display
import matplotlib.pyplot as plt
import soundfile as sf

def beamforming_delay(angle, distance_between_microphones, num_microphones):
    """
    Calculates the time delay for each microphone in a beamforming array 
    based on the desired steering angle and the number of microphones in the array.

    Args:
        angle: the desired steering angle in degrees.
        distance_between_microphones: the distance between microphones.
        num_microphones: the number of microphones.

    Returns:
        np.ndarray: An array of time delays in seconds for each microphone.
    """

    # Calculate the delay for each microphone
    delays = np.array([(i * distance_between_microphones * np.cos(angle * np.pi / 180) / 343) for i in range(num_microphones)])

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
    max_len = max((delays[i] * 44100) + len(mic_signals[i]) for i in range(len(mic_signals)))

    # Apply delays (in samples) and sum
    output_signal = np.zeros(int(max_len))
    delayed_outputs = [np.zeros(int(max_len)) for i in range(len(mic_signals))]
    sample_idx = 0

    for signal, delay in zip(mic_signals, delays):

        # Calculate the number of samples to delay
        delay_samples = int(delay * 44100)  # Assuming 44.1 KHz sample rate
        signal_len = len(signal)

        for i in range (delay_samples, delay_samples + signal_len):
            delayed_outputs[sample_idx][i] = signal[i-delay_samples]
            output_signal[i] += signal[i-delay_samples]

        sample_idx += 1

    return output_signal, delayed_outputs


def load_audio(file_paths, sr=44100):
    """
    Load multiple audio files into numpy arrays.

    Parameters:
    - file_paths (list of str): List of paths to the audio files.
    - sr (int): Sample rate to use when loading the audio files (default is 44100 Hz).

    Returns:
    - List of numpy arrays containing the audio data.
    """
    mic_signals = []
    for path in file_paths:
        signal, _ = librosa.load(path, sr=sr)  # Load with specified sample rate
        mic_signals.append(signal)
    return mic_signals

def save_audio(output_signal, output_path, sr=44100):
    """
    Save the output audio signal to a file.

    Parameters:
    - output_signal (numpy array): The audio signal to save.
    - output_path (str): The path where to save the output.
    - sr (int): The sample rate of the audio.
    """
    # Use soundfile to save the audio file
    sf.write(output_path, output_signal, sr)

# Example usage
if __name__ == "__main__":
    # Load the audio signals from different microphones
    file_paths = ['secret_revealed.wav', 'secret_revealed.wav']
    mic_signals = load_audio(file_paths)

    delays = beamforming_delay(45, 1000, 2)
    print(delays)

    # Perform delay-and-sum beamforming
    beamformed_signal, delayed_outputs = delay_and_sum(mic_signals, delays)
    print(f"\nbeamformed_signal: {beamformed_signal}")

    # Save the output beamformed signal
    save_audio(beamformed_signal, 'beamformed_output.wav')

    # Optionally, display the waveforms of the input and output
    # plt.figure(figsize=(10, 6))
    plt.subplots(3, 1, sharey=True)

    plt.subplot(3, 1, 1)
    librosa.display.waveshow(delayed_outputs[0], sr=44100, label='Mic 1', color='#ADD8E6')
    plt.legend()

    plt.subplot(3, 1, 2)
    librosa.display.waveshow(delayed_outputs[1], sr=44100, label='Mic 2', color='#87CEEB')
    plt.legend()

    # plt.subplot(3, 1, 3)
    # librosa.display.waveshow(delayed_outputs[2], sr=44100, label='Mic 3', color='#6CA6CD')
    # plt.legend()

    # plt.subplot(5, 1, 4)
    # librosa.display.waveshow(delayed_outputs[3], sr=44100, label='Mic 4', color='#4682B4')
    # plt.legend()

    # plt.subplot(9, 1, 5)
    # librosa.display.waveshow(delayed_outputs[4], sr=44100, label='Mic 5', color='#5F9EA0')
    # plt.legend()

    # plt.subplot(9, 1, 6)
    # librosa.display.waveshow(delayed_outputs[5], sr=44100, label='Mic 6', color='#4169E1')
    # plt.legend()

    # plt.subplot(9, 1, 7)
    # librosa.display.waveshow(delayed_outputs[6], sr=44100, label='Mic 7', color='#1E3A8A')
    # plt.legend()

    # plt.subplot(9, 1, 8)
    # librosa.display.waveshow(delayed_outputs[7], sr=44100, label='Mic 8', color='#00008B')
    # plt.legend()

    plt.subplot(3, 1, 3)
    librosa.display.waveshow(beamformed_signal, sr=44100, label='Beamformed Output', color='#00000B')
    plt.legend()

    plt.tight_layout()
    plt.show()
