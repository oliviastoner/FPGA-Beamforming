import cocotb
import os
import random
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner






# @cocotb.test()
# async def test_single_microphone(dut):
#     """ Test if data from a single microphone is received correctly. """


#     dut._log.info("Starting...")
#     cocotb.start_soon(Clock(dut.sck_in, 10, units="ns").start())
   


#     # Generate 24 bits of random data for a single microphone
#     sample_data = [1,0,1,0,  0,0,1,0,  0,0,0,1,   1,0,0,0,   0,1,0,0,   1,1,0,0  ]
#     expected_value = 0b101000100001100001001100 #int(''.join(map(str, sample_data)), 2)


#     # Send the ws_in pulse
#     dut.ws_in.value = 1
#     await RisingEdge(dut.sck_in)
#     await FallingEdge(dut.sck_in)
#     dut.ws_in.value = 0


#     # Send the sample data bit-by-bit on the rising edge of sck_in
#     for bit in sample_data:
#         dut.sd_in.value= bit
#         await RisingEdge(dut.sck_in)


#     # Check if the received data matches the expected value
#     await RisingEdge(dut.sck_in)  # Allow time for `audio_valid` signal to propagate
#     #assert dut.audio_valid_out.value == 1, "audio_valid should be high after receiving 24 bits"
#     assert dut.audio_out.value[0] == expected_value, f"Expected {expected_value}, but got {dut.audio_out1.value}"


#     for i in range(9):
#         await RisingEdge(dut.sck_in)
#     assert dut.curr_slot.value == 1, "curr slot should now be 1"

async def load_sample(dut,sample):
    # Load the audio sample
    await FallingEdge(dut.sck)
    dut.audio_sample.value = sample
    dut.sample_valid.value = 1
    await RisingEdge(dut.sck)  # Wait for a clock edge to load the sample
    await FallingEdge(dut.sck)
    dut.sample_valid.value= 0  # De-assert valid after one cycle

async def verify_output(dut,exp):
    BIT_WIDTH = dut.BIT_WIDTH.value
    for i in range(BIT_WIDTH):
        await RisingEdge(dut.sck)  # Wait for the SCK rising edge
        expected_bit = (exp >> (BIT_WIDTH - 1 - i)) & 1
        assert dut.sd.value == expected_bit, f"Bit {i} mismatch: expected {expected_bit}, got {int(dut.sd.value)}"

@cocotb.test()
async def test_i2s_one_input(dut):
    """
    Test the I2S single-channel module for proper data serialization.
    """
    BIT_WIDTH = dut.BIT_WIDTH.value

    # Generate the external SCK clock
    cocotb.start_soon(Clock(dut.sck, 25000, units="ns").start())  # 40 kHz SCK

    # Reset the DUT
    await FallingEdge(dut.sck)
    dut.rst.value = 1
    await RisingEdge(dut.sck)
    await FallingEdge(dut.sck)
    dut.rst.value = 0

    # Define a test audio sample
    test_audio_sample = 0b101011001110000101100111  # Example 24-bit sample

    # Load the audio sample
    await load_sample(dut,test_audio_sample)

    # Verify serialized output
    await verify_output(dut,test_audio_sample)

    # Check that `sd` returns to 0 after transmission
    await RisingEdge(dut.sck)
    assert dut.sd.value == 0, "SD did not return to 0 after transmission."

@cocotb.test()
async def test_i2s_multi_input(dut):
    """
    Test the I2S single-channel module for proper data serialization.
    """
    BIT_WIDTH = 24

    # Generate the external SCK clock
    cocotb.start_soon(Clock(dut.sck, 25000, units="ns").start())  # 40 kHz SCK

    # Reset the DUT
    await FallingEdge(dut.sck)
    dut.rst.value = 1
    await RisingEdge(dut.sck)
    await FallingEdge(dut.sck)
    dut.rst.value = 0

    # Define a test audio sample
    test_audio_sample = 0b101011001110000101100111  # Example 24-bit sample
    test_audio_sample2 = 0b000000000000111111111000

    # Load the audio sample
    await load_sample(dut,test_audio_sample)

    # Verify serialized output
    await verify_output(dut,test_audio_sample)
    
    # Load the audio sample
    await load_sample(dut,test_audio_sample2)

    # Verify serialized output
    await verify_output(dut,test_audio_sample2)

    # Check that `sd` returns to 0 after transmission
    await RisingEdge(dut.sck)
    assert dut.sd.value == 0, "SD did not return to 0 after transmission."


def i2s_audio_out_runner():
    """Simulate i2s_audio_out using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "i2s_audio_out.sv"]
    build_test_args = ["-Wall"]
    parameters = {'BIT_WIDTH': 24,} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="i2s_audio_out",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="i2s_audio_out",
        test_module="test_i2s_audio_out",
        test_args=run_test_args,
        waves=True
    )


if __name__ == "__main__":
    i2s_audio_out_runner()
