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

NUM_MICS = 4

def create_expected_beamformer(num_mics, num_bits, num_samples, delay_per_mic):
    audio_samples= [[random.randint(-(2**(num_bits - 1)), 2**(num_bits-1)-1) for _ in range(num_samples)] for _ in range(num_mics)]
    
    if delay_per_mic < 0:
        audio_shifted = [([0] * ((num_mics-1-idx) * abs(delay_per_mic)) + audio.copy()) for idx, audio in enumerate(audio_samples)]
    else:
        audio_shifted = [([0] * (idx * delay_per_mic) + audio.copy()) for idx, audio in enumerate(audio_samples)]
    summed_output = [sum(x) for x in zip(*audio_shifted)]
    expected_output = [(summed_audio >> int(log(num_mics, 2))) for summed_audio in summed_output]

    return audio_samples, audio_shifted, summed_output, expected_output

async def delay_and_sum_test_builder(dut, num_mics, num_bits, num_samples, delay_per_mic):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    # Setup initial inputs
    dut.rst_in.value = 0
    dut.valid_in.value = 0
    dut.delay_1.value = (num_mics - 1) * abs(delay_per_mic) if delay_per_mic < 0 else 0
    dut.delay_2.value = (num_mics - 2) * abs(delay_per_mic) if delay_per_mic < 0 else delay_per_mic
    dut.delay_3.value = (num_mics - 3) * abs(delay_per_mic) if delay_per_mic < 0 else delay_per_mic * 2
    dut.delay_4.value = (num_mics - 4) * abs(delay_per_mic) if delay_per_mic < 0 else delay_per_mic * 3
    dut.audio_in_1.value = 0
    dut.audio_in_2.value = 0
    dut.audio_in_3.value = 0
    dut.audio_in_4.value = 0

    # Reset the DUT
    await ClockCycles(dut.clk_in, 1)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 1)

    audio_samples, audio_shifted, summed_output, expected_output = create_expected_beamformer(num_mics, num_bits, num_samples, delay_per_mic)

    # Apply test cases with random values
    for i in range(len(expected_output)):
        # Set random audio signals for each microphone
        dut.audio_in_1.value = audio_samples[0][i]
        dut.audio_in_2.value = audio_samples[1][i] if len(audio_samples) >= 2 else 0
        dut.audio_in_3.value = audio_samples[2][i] if len(audio_samples) >= 3 else 0
        dut.audio_in_4.value = audio_samples[3][i] if len(audio_samples) >= 4 else 0
        # Enable valid input
        dut.valid_in.value = 1
        
        # Check that value propagates delays as expected (3 cycles till bram output)
        # 1 because write before read, 2 for normal bram
        if i > 3:
            assert dut.audio_out_mic1.value == audio_shifted[0][i - 4] & 0x00FFFFFF 
            assert dut.audio_out_mic2.value == audio_shifted[1][i - 4] & 0x00FFFFFF 
            assert dut.audio_out_mic3.value == (audio_shifted[2][i - 4] & 0x00FFFFFF if len(audio_samples) >= 3 else 0)
            assert dut.audio_out_mic4.value == (audio_shifted[3][i - 4] & 0x00FFFFFF if len(audio_samples) >= 4 else 0)
        # Following cycle summed_audio should be correct
        if i > 4:
            assert dut.summed_audio.value == summed_output[i - 5] & 0x03FFFFFF # (25 bits)
        # Check that the output matches expected value
        if i > 5:
            assert dut.audio_out.value == expected_output[i - 6] & 0x00FFFFFF
        # Check that the valid_out goes high after all signals have delayed
        if i > (num_mics-1)*abs(delay_per_mic) + 5:
            assert dut.valid_out.value == 1
        else:
            assert dut.valid_out.value == 0

        await ClockCycles(dut.clk_in,1)

@cocotb.test
async def dss_small_test(dut):
    await delay_and_sum_test_builder(dut, NUM_MICS, 8, 50, 2)

@cocotb.test
async def dss_small_test_2(dut):
    await delay_and_sum_test_builder(dut, NUM_MICS, 8, 50, 4)

@cocotb.test
async def dss_small_test_neg_delay(dut):
    await delay_and_sum_test_builder(dut, NUM_MICS, 8, 50, -2)

@cocotb.test
async def dss_real_test(dut):
    await delay_and_sum_test_builder(dut, NUM_MICS, 24, 200, 6)

def delay_and_sum_runner():
    """Simulate the tdm receiver using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "delay_bram.sv", proj_path / "hdl" / "evt_counter.sv", proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v"]
    build_test_args = ["-Wall"]
    parameters = {'NUM_MICS': NUM_MICS} 
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="delay_bram",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="delay_bram",
        test_module="test_delay_and_sum_2",
        test_args=run_test_args,
        waves=True
    )


if __name__ == "__main__":
    delay_and_sum_runner()