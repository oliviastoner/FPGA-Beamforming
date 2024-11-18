import numpy as np
import librosa
import librosa.display
import matplotlib.pyplot as plt
import soundfile as sf
import cocotb
import os
import sys
from math import log
import math
import random
from pathlib import Path
import cocotb
from cocotb.triggers import Timer
import os
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

@cocotb.test()
async def test_delay_and_sum(dut):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    # Reset the DUT
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 3) # wait three clock cycles
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 3) # wait three clock cycles

    # Parameters
    num_samples = 100  # Number of samples to test per microphone
    max_delay = 25    # Maximum delay in microseconds
    over_90 = random.randint(0, 1)

    # Test input signal setup (simulating audio values for 4 microphones)
    mic_signals = [
        [random.randint(0, 0xFFFF) for _ in range(num_samples)],  # Random values for mic 1
        [random.randint(0, 0xFFFF) for _ in range(num_samples)],  # Random values for mic 2
        [random.randint(0, 0xFFFF) for _ in range(num_samples)],  # Random values for mic 3
        [random.randint(0, 0xFFFF) for _ in range(num_samples)]   # Random values for mic 4
    ]
    print(f"\nmic signals: {mic_signals}")
    
    # Randomly generate delays for each microphone (between 0 and max_delay)
    starting_delay = random.randint(0, max_delay)
    delays = [starting_delay * _ for _ in range(4)]
    if over_90 == 1: # reverse delays if over 90 degree input angle
        delays.reverse()
    print(f"\ndelays: {delays}")

    dut.delay_1.value = delays[0]
    dut.delay_2.value = delays[1]
    dut.delay_3.value = delays[2]
    dut.delay_4.value = delays[3]
    
    # Apply test cases with random values
    for i in range(num_samples):

        # Set random audio signals for each microphone
        dut.audio_in_1.value = mic_signals[0][i]
        dut.audio_in_2.value = mic_signals[1][i]
        dut.audio_in_3.value = mic_signals[2][i]
        dut.audio_in_4.value = mic_signals[3][i]

        # Enable valid input
        dut.valid_in.value = 1
        await ClockCycles(dut.clk_in,1)
        dut.valid_in.value = 0

        # Wait for values to propagate
        await ClockCycles(dut.clk_in,5)

        # Compute the expected output:
        # The output should be the sum of the audio signals from all 4 microphones, 
        # delayed accordingly.
        if (delays[0] == 0 and delays[1] == 0 and delays[2] == 0 and delays[3] == 0):
            expected_output = sum(mic_signals[j][i] for j in range(4))/4
        elif (delays[0] == 0):
            if (i >= (delays[3])):
                expected_output = sum(mic_signals[j][i-delays[j]] for j in range(4))/4
            elif (i >= (delays[2])):
                expected_output = sum(mic_signals[j][i-delays[j]] for j in range(3))/4
            elif (i >= (delays[1])):
                expected_output = sum(mic_signals[j][i-delays[j]] for j in range(2))/4
            else:
                expected_output = mic_signals[0][i]/4
        else:
            if (i >= (delays[0])):
                expected_output = sum(mic_signals[j][i-delays[j]] for j in range(3, -1, -1))/4
            elif (i >= (delays[1])):
                expected_output = sum(mic_signals[j][i-delays[j]] for j in range(3, 0, -1))/4
            elif (i >= (delays[2])):
                expected_output = sum(mic_signals[j][i-delays[j]] for j in range(3, 1, -1))/4
            else:
                expected_output = mic_signals[3][i]/4

        # Assert that the computed output matches the expected result
        computed_output = int(dut.audio_out.value)
        print(f"\nCycle {i}: Computed Audio Output = {computed_output}, Expected = {expected_output}")

        # Validate that the output matches the expected summation of input signals
        assert math.isclose(computed_output, expected_output, abs_tol=1e2), (
            f"Test failed at cycle {i}: expected {expected_output}, got {computed_output}"
        )

        # Ensure valid out is only high for a single cycle
        assert dut.valid_out.value == 1, "1-cycle valid out high value"
        await ClockCycles(dut.clk_in,1)
        assert dut.valid_out.value == 0, "Valid out value should go back low"


def delay_and_sum_runner():
    """Simulate the tdm receiver using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "delay_bram.sv", proj_path / "hdl" / "evt_counter.sv", proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v"]
    build_test_args = ["-Wall"]
    # parameters = {'BIT_WIDTH': 24, 'SLOTS':4} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="delay_bram",
        always=True,
        build_args=build_test_args,
        # parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="delay_bram",
        test_module="test_delay_and_sum",
        test_args=run_test_args,
        waves=True
    )


if __name__ == "__main__":
    delay_and_sum_runner()