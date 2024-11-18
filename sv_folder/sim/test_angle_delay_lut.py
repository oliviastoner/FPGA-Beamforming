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


# Define the expected speed of sound
SPEED_OF_SOUND = 343.0  # millimeters/millisecond

def compute_expected_delay(distance, angle):
    """Compute the expected delay value based on the given angle, distance, and speed of sound."""

    assert(angle >= 0 and angle <= 180), "invalid angle"

    delay_value_mic1 = 0 * math.cos(angle * math.pi / 180) * distance / SPEED_OF_SOUND * 1000
    delay_value_mic2 = 1 * math.cos(angle * math.pi / 180) * distance / SPEED_OF_SOUND * 1000
    delay_value_mic3 = 2 * math.cos(angle * math.pi / 180) * distance / SPEED_OF_SOUND * 1000
    delay_value_mic4 = 3 * math.cos(angle * math.pi / 180) * distance / SPEED_OF_SOUND * 1000

    # must shift to account for nagative values in angles over 90 degrees
    if (delay_value_mic4 < 0):
        return [-(delay_value_mic4), -(delay_value_mic3), -(delay_value_mic2), -(delay_value_mic1)]
    
    else:
        return [delay_value_mic1, delay_value_mic2, delay_value_mic3, delay_value_mic4]

def signed_binary_to_integer(bin_val):
    """Compute the signed integer representation from the signed 32-bit binary format."""

    # Convert the binary outputs to signed integers (assuming the output is 32-bit signed)
    computed_int = int(bin_val, 2)

    # Adjust for two's complement signed interpretation for 32-bit values
    max_val = 2**31  # for 32-bit signed integer
    if computed_int >= max_val:
        computed_int -= 2**32

    return computed_int
    
@cocotb.test()
async def test_angle_delay_lut(dut):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    # Reset the DUT
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 3) # wait three clock cycles
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 3) # wait three clock cycles
    
    # Define test cases: (angle, distance)
    test_cases = [
        (random.randint(0, 180), random.randint(0, 400)),
        (random.randint(0, 180), random.randint(0, 400)),
        (random.randint(0, 180), random.randint(0, 400))
    ]
    
    # Apply test cases
    for angle, distance in test_cases:
        
        dut.angle = angle
        dut.distance = distance
        print(f"\noutput for angle: {angle} and distance: {distance}")
        
        await ClockCycles(dut.clk_in, 3)
        
        # Convert the binary outputs to signed integers (assuming the output is 32-bit signed)
        computed_value_mic1 = signed_binary_to_integer(dut.delay_1.value.binstr)
        computed_value_mic2 = signed_binary_to_integer(dut.delay_2.value.binstr)
        computed_value_mic3 = signed_binary_to_integer(dut.delay_3.value.binstr)
        computed_value_mic4 = signed_binary_to_integer(dut.delay_4.value.binstr)
        print(f"\ncomputed mic 1: {computed_value_mic1}, mic 2: {computed_value_mic2}, mic 3: {computed_value_mic3}, mic 4: {computed_value_mic4}")

        expected_value_mic1, expected_value_mic2, expected_value_mic3, expected_value_mic4 = compute_expected_delay(distance, angle)
        print(f"\nexpected mic 1: {expected_value_mic1}, mic 2: {expected_value_mic2}, mic 3: {expected_value_mic3}, mic 4: {expected_value_mic4}")
        
        # Compare the computed value with the expected value
        if not math.isclose(computed_value_mic1, expected_value_mic1, abs_tol=1e3):
            raise AssertionError(f"Test failed for angle={angle}, distance={distance}: "
                                f"Expected {expected_value_mic1}, got {computed_value_mic1}")
        
        if not math.isclose(computed_value_mic2, expected_value_mic2, abs_tol=1e3):
            raise AssertionError(f"Test failed for angle={angle}, distance={distance}: "
                                f"Expected {expected_value_mic2}, got {computed_value_mic2}")
        
        if not math.isclose(computed_value_mic3, expected_value_mic3, abs_tol=1e3):
            raise AssertionError(f"Test failed for angle={angle}, distance={distance}: "
                                f"Expected {expected_value_mic3}, got {computed_value_mic3}")
        
        if not math.isclose(computed_value_mic4, expected_value_mic4, abs_tol=1e3):
            raise AssertionError(f"Test failed for angle={angle}, distance={distance}: "
                                f"Expected {expected_value_mic4}, got {computed_value_mic4}")
        
        await ClockCycles(dut.clk_in, 1) # wait a clock cycle


def angle_delay_lut_runner():
    """Simulate the tdm receiver using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "angle_delay_lut.sv"]
    build_test_args = ["-Wall"]
    # parameters = {'BIT_WIDTH': 24, 'SLOTS':4} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="angle_delay_lut",
        always=True,
        build_args=build_test_args,
        # parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="angle_delay_lut",
        test_module="test_angle_delay_lut",
        test_args=run_test_args,
        waves=True
    )


if __name__ == "__main__":
    angle_delay_lut_runner()
