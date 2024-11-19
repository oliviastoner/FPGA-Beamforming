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






@cocotb.test()
async def test_single_microphone(dut):
    """ Test if data from a single microphone is received correctly. """


    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.sck, 10, units="ns").start())
   


    # Generate 24 bits of random data for a single microphone
    sample_data = [1,0,1,0,  0,0,1,0,  0,0,0,1,   1,0,0,0,   0,1,0,0,   1,1,0,0  ]
    expected_value = 0b101000100001100001001100 #int(''.join(map(str, sample_data)), 2)


    # Send the WS pulse
    dut.ws.value = 1
    await RisingEdge(dut.sck)
    await FallingEdge(dut.sck)
    dut.ws.value = 0


    # Send the sample data bit-by-bit on the rising edge of SCK
    for bit in sample_data:
        dut.sd.value= bit
        await RisingEdge(dut.sck)


    # Check if the received data matches the expected value
    await RisingEdge(dut.sck)  # Allow time for `audio_valid` signal to propagate
    #assert dut.audio_valid_out.value == 1, "audio_valid should be high after receiving 24 bits"
    assert dut.audio_out1.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out1.value}"


    for i in range(9):
        await RisingEdge(dut.sck)
    assert dut.curr_slot.value == 1, "curr slot should now be 1"
   


@cocotb.test()
async def test_four_microphones(dut):
    """ Test if data from four microphones is received correctly. """


   
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.sck, 10, units="ns").start())
   


    # Generate 24 bits of random data for a single microphone
    sample_data = [1,0,1,0,  0,0,1,0,  0,0,0,1,   1,0,0,0,   0,1,0,0,   1,1,0,0  ]
    expected_value = 0b101000100001100001001100 #int(''.join(map(str, sample_data)), 2)


    # Send the WS pulse
    dut.ws.value = 1
    await RisingEdge(dut.sck)
    await FallingEdge(dut.sck)
    dut.ws.value = 0


    for i in range(4):
        #assert dut.curr_slot.value == (i)%4, f"curr slot should now be {(i%4)}, but got {dut.curr_slot.value}"
        # Send the sample data bit-by-bit on the rising edge of SCK
        for bit in sample_data:
            dut.sd.value= bit
            await RisingEdge(dut.sck)

        if i ==3:
            # Check if the received data matches the expected value
            await RisingEdge(dut.sck)  # Allow time for `audio_valid` signal to propagate
            assert dut.audio_valid_out.value == 1, f"audio_valid should be high after receiving all mics, failed on {i} signal"
            assert dut.audio_out1.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out1.value}"
            assert dut.audio_out2.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out2.value}"
            assert dut.audio_out3.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out3.value}"
            assert dut.audio_out4.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out4.value}"
        else:
            await RisingEdge(dut.sck)  # Allow time for `audio_valid` signal to propagate
        


        for j in range(7):
            await RisingEdge(dut.sck)
    



@cocotb.test()
async def test_two_samples_four_microphones(dut):
    """ Test if two consecutive samples from four microphones are received correctly. """


    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.sck, 10, units="ns").start())
   


    # Generate 24 bits of random data for a single microphone
    sample_data = [1,0,1,0,  0,0,1,0,  0,0,0,1,   1,0,0,0,   0,1,0,0,   1,1,0,0  ]
    expected_value = 0b101000100001100001001100 #int(''.join(map(str, sample_data)), 2)


    for _ in range(2):
        # Send the WS pulse
        dut.ws.value = 1
        await RisingEdge(dut.sck)
        await FallingEdge(dut.sck)
        dut.ws.value = 0


        for i in range(4):
            #assert dut.curr_slot.value == (i)%4, f"curr slot should now be {(i%4)}, but got {dut.curr_slot.value}"
            # Send the sample data bit-by-bit on the rising edge of SCK
            for bit in sample_data:
                dut.sd.value= bit
                await RisingEdge(dut.sck)

            if i == 3:
                # Check if the received data matches the expected value
                await RisingEdge(dut.sck)  # Allow time for `audio_valid` signal to propagate
                assert dut.audio_valid_out.value == 1, f"audio_valid should be high after receiving all mics, failed on {i} signal"
                assert dut.audio_out1.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out1.value}"
                assert dut.audio_out2.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out2.value}"
                assert dut.audio_out3.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out3.value}"
                assert dut.audio_out4.value == expected_value, f"Expected {expected_value}, but got {dut.audio_out4.value}"
            else:
                await RisingEdge(dut.sck)  # Allow time for `audio_valid` signal to propagate
            for j in range(7):
                await RisingEdge(dut.sck)
   




def tdm_receive_runner():
    """Simulate the tdm receiver using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "tdm_receive.sv"]
    build_test_args = ["-Wall"]
    parameters = {'BIT_WIDTH': 24, 'SLOTS':4} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="tdm_receive",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="tdm_receive",
        test_module="test_tdm_receive",
        test_args=run_test_args,
        waves=True
    )


if __name__ == "__main__":
    tdm_receive_runner()
