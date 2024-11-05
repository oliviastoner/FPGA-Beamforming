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
async def test_a(dut):
    """cocotb test for uart_receive"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # cocotb.start_soon(test_spi_device(dut))
    dut._log.info("Holding reset...")
    dut.rst_in.value = 1
    dut.rx_wire_in.value = 1
    await ClockCycles(dut.clk_in, 3) #wait three clock cycles
    #assert dut.chip_sel_out.value.integer==1, "cs is not 1 on reset!"
    await  FallingEdge(dut.clk_in)
    dut.rst_in.value = 0 #un reset device
    await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
    await  FallingEdge(dut.clk_in)


    dut._log.info("Setting Trigger")
    dut.rx_wire_in.value = 0
    await ClockCycles(dut.clk_in, 1,rising=False)
    #dut.data_byte_in.value = 0b11111111 # once trigger in is off, don't expect data_in to stay the same!!
    #dut.trigger_in.value = 0
    await ClockCycles(dut.clk_in,9)
    dut.rx_wire_in.value = 1
    #await with_timeout(RisingEdge(dut.new_data_out),5000,'ns')
    await ReadOnly()
    
    await ClockCycles(dut.clk_in, 300)

   

# @cocotb.test()
# async def test_b(dut):
#     """
#     Look at multiple waveforms
#     """
#     dut._log.info("Starting...")
#     cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
#     cocotb.start_soon(test_spi_device(dut))
#     dut._log.info("Holding reset...")
#     dut.rst_in.value = 1
#     dut.trigger_in.value = 0
#     dut.data_in.value = 0xBEEF&0xFFFF #set in 16 bit input value
#     await ClockCycles(dut.clk_in, 3) #wait three clock cycles
#     assert dut.chip_sel_out.value.integer==1, "cs is not 1 on reset!"
#     await  FallingEdge(dut.clk_in)
#     dut.rst_in.value = 0 #un reset device
#     await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
#     await  FallingEdge(dut.clk_in)
#     dut._log.info("Setting Trigger")
#     dut.trigger_in.value = 1
#     await ClockCycles(dut.clk_in, 1,rising=False)
#     dut.data_in.value = 0xAAAA # once trigger in is off, don't expect data_in to stay the same!!
#     dut.trigger_in.value = 0
#     await with_timeout(RisingEdge(dut.data_valid_out),10000,'ns')
#     await ReadOnly()
#     data_out = dut.data_out.value
#     dut._log.info(f"Receiver Data: {data_out}")
#     await ClockCycles(dut.clk_in, 300)

#     dut.trigger_in.value=1
#     await ClockCycles(dut.clk_in, 1)
#     dut.trigger_in.value=0
#     await ClockCycles(dut.clk_in, 10000)
#     dut.trigger_in.value=1
#     await ClockCycles(dut.clk_in, 1)
#     dut.trigger_in.value=0
#     await ClockCycles(dut.clk_in, 10000)




    


def uart_receive_runner():
    """Simulate the uart receiver using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_receive.sv"]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ': 10, 'BAUD_RATE':1} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_receive",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_receive",
        test_module="test_uart_receive",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    uart_receive_runner()