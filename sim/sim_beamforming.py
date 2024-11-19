import numpy as np
import librosa
import librosa.display
import matplotlib.pyplot as plt
import soundfile as sf

def beamforming_delay(angle, speed_of_sound, microphone_positions):
    """
    Calculates the time delay for each microphone in a beamforming array 
    based on the desired steering angle.

    Args:
        angle (float): The desired steering angle in radians.
        speed_of_sound (float): The speed of sound in the medium (m/s).
        microphone_positions (np.ndarray): A 2D array of microphone positions (x, y) in meters.

    Returns:
        np.ndarray: An array of time delays in seconds for each microphone.
    """

    # Calculate the distance from the reference microphone (first microphone) 
    # to the wavefront for each microphone
    distances = np.dot(microphone_positions, np.array([np.cos(angle), np.sin(angle)]))

    # Calculate the time delay for each microphone
    delays = distances / speed_of_sound

    # Adjust the delays relative to the first microphone (reference)
    delays = delays - delays[0]

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
        delay_samples = int(delay * 1000000)  # Assuming 1MHz sample rate
        signal_len = len(signal)
        # Zero-pad the signal on the left if delay is positive, on the right if negative
        # if delay_samples > 0:
        for i in range (delay_samples, delay_samples + signal_len):
            delayed_outputs[sample_idx][i] = signal[i-delay_samples]
            output_signal[i] += signal[i-delay_samples]
        # delayed_signal = np.pad(output_signalignal, 0, mode='constant')
        # else:
        #     delayed_signal = np.pad(signal, (0, -delay_samples), mode='constant')
        sample_idx += 1
        # Add the delayed signal to the output
        # output_signal += delayed_signal[:max_len]  # Ensure signals are aligned properly

    return output_signal, delayed_outputs


def load_audio(file_paths, sr=1000000):
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

def save_audio(output_signal, output_path, sr=1000000):
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
    file_paths = ['secret_revealed.wav', 'secret_revealed.wav', 'secret_revealed.wav', 'secret_revealed.wav']
    mic_signals = load_audio(file_paths)

    # Specify the delays (in seconds) for each microphone
    # delays = beamforming_delay(0, 343, [(-1, 0), (-0.75, 0), (-0.5, 0), (-0.25, 0), (0, 0), (0.25, 0), (0.5, 0), (0.75, 0)])  # Example delays in seconds
    delays = [0, 0.25, 0.5, 0.75]
    # print(delays)

    # Perform delay-and-sum beamforming
    beamformed_signal, delayed_outputs = delay_and_sum(mic_signals, delays)

    # Save the output beamformed signal
    save_audio(beamformed_signal, 'beamformed_output.wav')

    # Optionally, display the waveforms of the input and output
    # plt.figure(figsize=(10, 6))
    plt.subplots(5, 1, sharey=True)

    plt.subplot(5, 1, 1)
    librosa.display.waveshow(delayed_outputs[0], sr=44100, label='Mic 1', color='#ADD8E6')
    plt.legend()

    plt.subplot(5, 1, 2)
    librosa.display.waveshow(delayed_outputs[1], sr=44100, label='Mic 2', color='#87CEEB')
    plt.legend()

    plt.subplot(5, 1, 3)
    librosa.display.waveshow(delayed_outputs[2], sr=44100, label='Mic 3', color='#6CA6CD')
    plt.legend()

    plt.subplot(5, 1, 4)
    librosa.display.waveshow(delayed_outputs[3], sr=44100, label='Mic 4', color='#4682B4')
    plt.legend()

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

    plt.subplot(5, 1, 5)
    librosa.display.waveshow(beamformed_signal, sr=44100, label='Beamformed Output', color='#00000B')
    plt.legend()

    plt.tight_layout()
    plt.show()
