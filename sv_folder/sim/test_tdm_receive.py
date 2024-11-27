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


@cocotb.coroutine
async def clock_divider(clock, divider, trigger_signal):
    """
    Clock divider coroutine.
    """
    count = 0
    while True:
        await RisingEdge(clock)  # Wait for a rising edge of the input clock
        if count == divider-1:
            count = 0
            trigger_signal.value = 1 if trigger_signal.value == 0 else 0  # Toggle the tri
        else:
            #trigger_signal.value =  0
            count+=1

@cocotb.coroutine
async def clock_divider_neg(clock, divider, trigger_signal):
    """
    Clock divider coroutine.
    """
    count = 0
    while True:
        await FallingEdge(clock)  # Wait for a rising edge of the input clock
        if count == divider-1:
            count = 0
            trigger_signal.value =  1 #if trigger_signal.value == 0 else 0  # Toggle the tri
        else:
            trigger_signal.value = 0
            count+=1



@cocotb.test()
async def test_single_microphone(dut):
    """ Test if data from a single microphone is received correctly. """


    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    await FallingEdge(dut.clk_in)
    dut.sck_in.value = 0
    dut.ws_in.value = 0
    dut.active.value=0
    await RisingEdge(dut.clk_in)

    # Start the clock divider coroutine
    cocotb.start_soon(clock_divider(dut.clk_in, 50, dut.sck_in))

    cocotb.start_soon(clock_divider_neg(dut.sck_in, 128, dut.ws_in))

    

    # Generate 24 bits of random data for a single microphone
    sample_data = [1,0,1,0,  0,0,1,0,  0,0,0,1,   1,0,0,0,   0,1,0,0,   1,1,0,0  ]
    expected_value = 0b101000100001100001001100 #int(''.join(map(str, sample_data)), 2)


    # Send the ws_in pulse
    await RisingEdge(dut.ws_in)
    
    
    # Send the sample data bit-by-bit on the rising edge of sck_in
    for bit in sample_data:
        await FallingEdge(dut.sck_in)
        dut.sd_in.value= bit
        await RisingEdge(dut.sck_in)
    


    # Check if the received data matches the expected value
    await RisingEdge(dut.sck_in)  # Allow time for `audio_valid` signal to propagate
    #assert dut.audio_valid_out.value == 1, "audio_valid should be high after receiving 24 bits"
    print(dut.audio_out.value[0].integer)
    assert dut.audio_out.value[0].integer == expected_value, f"Expected {expected_value}, but got {dut.audio_out.value[0]}"


    for i in range(9):
        await RisingEdge(dut.sck_in)
    assert dut.curr_slot.value == 1, "curr slot should now be 1"
   


@cocotb.test()
async def test_four_microphones(dut):
    """ Test if data from four microphones is received correctly. """


   
    
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    await FallingEdge(dut.clk_in)
    dut.sck_in.value = 0
    dut.ws_in.value = 0
    dut.active.value=0
    await RisingEdge(dut.clk_in)

    # Start the clock divider coroutine
    cocotb.start_soon(clock_divider(dut.clk_in, 50, dut.sck_in))

    cocotb.start_soon(clock_divider_neg(dut.sck_in, 128, dut.ws_in))

    

    # Generate 24 bits of random data for a single microphone
    sample_data = [1,0,1,0,  0,0,1,0,  0,0,0,1,   1,0,0,0,   0,1,0,0,   1,1,0,0  ]
    expected_value = 0b101000100001100001001100 #int(''.join(map(str, sample_data)), 2)


    # Send the ws_in pulse
    await RisingEdge(dut.ws_in)


    for i in range(4):
        #assert dut.curr_slot.value == (i)%4, f"curr slot should now be {(i%4)}, but got {dut.curr_slot.value}"
        # Send the sample data bit-by-bit on the rising edge of sck_in
        for bit in sample_data:
            await FallingEdge(dut.sck_in)
            dut.sd_in.value= bit
            await RisingEdge(dut.sck_in)

        if i ==3:
            # Check if the received data matches the expected value
            await RisingEdge(dut.sck_in)  # Allow time for `audio_valid` signal to propagate
            assert dut.audio_valid_out.value == 1, f"audio_valid should be high after receiving all mics, failed on {i} signal"

            audio_out_list = dut.audio_out.value
           
            # Unpack the array (24 bits per element)
            for k in range(4):
                audio_sample = audio_out_list[k]
                assert audio_sample == expected_value, f"Expected {expected_value}, but got {audio_sample}"
        else:
            await RisingEdge(dut.sck_in)  # Allow time for `audio_valid` signal to propagate
        


        for j in range(7):
            await RisingEdge(dut.sck_in)
    



@cocotb.test()
async def test_two_samples_four_microphones(dut):
    """ Test if two consecutive samples from four microphones are received correctly. """


    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    await FallingEdge(dut.clk_in)
    dut.sck_in.value = 0
    dut.ws_in.value = 0
    dut.active.value=0
    await RisingEdge(dut.clk_in)

    # Start the clock divider coroutine
    cocotb.start_soon(clock_divider(dut.clk_in, 50, dut.sck_in))

    cocotb.start_soon(clock_divider_neg(dut.sck_in, 128, dut.ws_in))

    

    # Generate 24 bits of random data for a single microphone
    sample_data = [1,0,1,0,  0,0,1,0,  0,0,0,1,   1,0,0,0,   0,1,0,0,   1,1,0,0  ]
    expected_value = 0b101000100001100001001100 #int(''.join(map(str, sample_data)), 2)


    


    for _ in range(2):
        # Send the ws_in pulse
        await RisingEdge(dut.ws_in)
        


        for i in range(4):
            #assert dut.curr_slot.value == (i)%4, f"curr slot should now be {(i%4)}, but got {dut.curr_slot.value}"
            # Send the sample data bit-by-bit on the rising edge of sck_in
            for bit in sample_data:
                await FallingEdge(dut.sck_in)
                dut.sd_in.value= bit
                await RisingEdge(dut.sck_in)

            if i == 3:
                # Check if the received data matches the expected value
                await RisingEdge(dut.sck_in)  # Allow time for `audio_valid` signal to propagate
                assert dut.audio_valid_out.value == 1, f"audio_valid should be high after receiving all mics, failed on {i} signal"
                audio_out_list = dut.audio_out.value
           
                # Unpack the array (24 bits per element)
                for k in range(4):
                    audio_sample = audio_out_list[k]
                    assert audio_sample == expected_value, f"Expected {expected_value}, but got {audio_sample}"
            else:
                await RisingEdge(dut.sck_in)  # Allow time for `audio_valid` signal to propagate
            for j in range(7):
                await RisingEdge(dut.sck_in)
   




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
