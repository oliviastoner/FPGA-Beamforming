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

async def send_transmission(dut, msg):
    """Helper function to send a msg over uart"""
    dut.data_in.value = msg
    dut.trigger_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.trigger_in.value = 0
    # msg_bits = (1 << 9) | (msg << 1)
    # for bit_i in range(10):
    #     # if (int and bit_i == 4):
        #     dut.data_byte_in.value = msg
        #     dut.trigger_in.value = 1
        # if (int and bit_i == 5):
        #     dut.trigger_in.value = 0

        # assert dut.busy_out.value == 1
        # assert dut.tx_wire_out.value == (msg_bits >> bit_i)&1
        # await ClockCycles(dut.clk_in, 2)
        

# does correct transmission occur lsb first 
@cocotb.test()
async def test_transmission(dut):
    """Test that the data line remains high when not transmitting data"""
    dut._log.info("Starting test_transmission")
    # Start a 100 Mhz Clk
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start()) 

    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.rst_in.value = 0

    await send_transmission(dut, 0xdeadbe)

    await ClockCycles(dut.clk_in, 100)
   

def uart_byte_transmit_runner():
    """Simulate the uart transmit module using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_byte_transmit.sv"]
    sources += [proj_path / "hdl" / "uart_transmit.sv"]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ': 100_000_000, 'BAUD_RATE': 50_000_000, 'NUM_BYTES': 3} # Baud rate corresponds to 2 clk cycles per bit
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_byte_transmit",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_byte_transmit",
        test_module="test_uart_byte_transmit",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    uart_byte_transmit_runner()
