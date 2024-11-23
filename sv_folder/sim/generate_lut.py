import math

# Define the speed of sound
SPEED_OF_SOUND = 343.0  # meters/second

def generate_lut(distance, frequency):
    """
    Generates and saves the LUT used to store the expected cycle delay (for n = 1 in the (n * d * cos(theta)) / c equation) given the distance between mics and and frequency of sampling at every discrete angle value [0,180].
    This will be used as the LUT in the angle_delay_LUT module.
    The results of this are stored in LUT.txt and can be copied over to the angle_delay_LUT.sv file.
    
    Parameters:
    - distance (float): distance between microphones, in m.
    - frequency (int): audio sampling frequency, in Hz.

    Saves (in LUT.txt):
    - LUT: the LUT to be used in the angle_delay_lut.sv module: 
    """
    file = open("LUT.txt", "w") 

    # to get the answer in seconds, do distance * math.cos(angle * math.pi / 180) / SPEED_OF_SOUND.

    # the frequency gives us number of samples per second.
    # so, to determine the number of cycles delay, if we're given one sample per valid cycle,
    # we must multiply this answer by the frequency.

    # for angle in range(181):
    #     file.write(f"\ndelay_table[{angle}] = {int(float(distance) * math.cos(int(angle) * math.pi / 180) / SPEED_OF_SOUND * int(frequency))};")

    for angle in range(181):
        delay_val = int(float(distance) * math.cos(int(angle) * math.pi / 180) / SPEED_OF_SOUND * int(frequency))
        file.write(f"\n8'd{angle}: delay = 8'd{abs(delay_val)};")

    file.close() 

def generate_display_lut():
    file = open("ang_ascii_lut.txt", "w") 

    for angle in range(181):
        ascii_rep = ((angle // 100) << 8) | (((angle % 100) // 10) << 4) | (angle % 10)
        file.write(f"\n8'd{angle}: ascii_out = 12'b{"{:012b}".format(ascii_rep)};")

if __name__ == "__main__":
    # generate_display_lut()
    generate_lut(float(input("\nEnter the distance between microphones (in m.): ")), int(input("\nEnter the sampling frequency (in Hz): ")))