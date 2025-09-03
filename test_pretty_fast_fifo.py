# --------------------------------------------------------------------------------------------------
# Copyright (c) Lukas Vik. All rights reserved.
# --------------------------------------------------------------------------------------------------
# Requires a development version of cocotb:
#   python3 -m pip install --upgrade git+https://github.com/cocotb/cocotb.git
# Run test cases with
#   python3 -m pytest -v -n32 test_pretty_fast_fifo.py
# Requires the NVC simulator available in PATH.
# --------------------------------------------------------------------------------------------------

from __future__ import annotations

import os
import random
import sys
from itertools import product
from pathlib import Path
from typing import Iterable

import cocotb
import pytest
from attr import dataclass
from cocotb.triggers import RisingEdge, Timer, with_timeout
from cocotb_tools.runner import get_runner

THIS_DIR = Path(__file__).parent


@dataclass
class RandomStallConfig:
    probability_percent: float = 0.0
    min_stall_cycles: int = 1
    max_stall_cycles: int = 1


async def run_clock(signal, period_ns: int) -> None:
    cocotb.log.info("Starting clock with period %i ns", period_ns)

    while True:
        signal.value = 0
        await Timer(time=period_ns // 2, unit="ns")
        signal.value = 1
        await Timer(time=period_ns // 2, unit="ns")


def will_never_stall(stall_config: RandomStallConfig) -> bool:
    return stall_config.probability_percent == 0 or stall_config.max_stall_cycles == 0


def get_stall_count(stall_config: RandomStallConfig) -> int:
    if will_never_stall(stall_config=stall_config):
        return 0

    if 100 * random.random() >= stall_config.probability_percent:
        return 0

    return random.randint(stall_config.min_stall_cycles, stall_config.max_stall_cycles)


async def push_data(
    dut, clock, stall_config: RandomStallConfig, stimuli_data: list[int]
) -> None:
    port_ready = dut.write_ready
    port_valid = dut.write_valid
    port_data = dut.write_data

    cocotb.log.info("Pushing %i words", len(stimuli_data))

    port_valid.value = 0
    port_data.value = 0

    for value in stimuli_data:
        port_valid.value = 1
        port_data.value = value

        while True:
            await RisingEdge(clock)
            if port_ready.value:
                break

        port_valid.value = 0
        port_data.value = 0

        for _ in range(get_stall_count(stall_config=stall_config)):
            await RisingEdge(clock)


async def check_data(
    dut,
    clock,
    stall_config: RandomStallConfig,
    reference_data: list[int],
) -> None:
    port_ready = dut.read_ready
    port_valid = dut.read_valid
    port_data = dut.read_data

    cocotb.log.info("Checking %i words", len(reference_data))

    cocotb.start_soon(
        toggle_ready(signal=port_ready, clock=clock, stall_config=stall_config)
    )

    for expected_data in reference_data:
        while True:
            await RisingEdge(clock)

            if port_ready.value == 1 and port_valid.value == 1:
                got_data = port_data.value

                assert got_data == expected_data
                cocotb.log.info("Checked %s", hex(got_data))
                break

    cocotb.log.info("Finished checking data")


async def toggle_ready(signal, clock, stall_config: RandomStallConfig) -> None:
    if will_never_stall(stall_config=stall_config):
        signal.value = 1
        return

    while True:
        for _ in range(get_stall_count(stall_config=stall_config)):
            signal.value = 0
            await RisingEdge(clock)

        signal.value = 1
        await RisingEdge(clock)


@cocotb.test
async def test_random_data(dut):
    data_width = dut.data_width.value
    fifo_depth = dut.fifo_depth.value

    cocotb.log.info("data_width = %i", data_width)
    cocotb.log.info("fifo_depth = %i", fifo_depth)

    write_clock = dut.write_clock
    read_clock = dut.read_clock

    cocotb.start_soon(
        run_clock(signal=write_clock, period_ns=2 * random.randint(10, 40))
    )
    cocotb.start_soon(
        run_clock(signal=read_clock, period_ns=2 * random.randint(10, 40))
    )

    num_words = random.randint(2 * fifo_depth, 4 * fifo_depth)
    data = [2**data_width - 1 - data_index for data_index in range(num_words)]

    cocotb.start_soon(
        push_data(
            dut=dut,
            clock=write_clock,
            stall_config=RandomStallConfig(probability_percent=50),
            stimuli_data=data,
        )
    )
    await with_timeout(
        trigger=check_data(
            dut=dut,
            clock=read_clock,
            stall_config=RandomStallConfig(probability_percent=50),
            reference_data=data,
        ),
        timeout_time=20_000,
        timeout_unit="ns",
    )


@pytest.mark.parametrize(
    "seed,data_width,fifo_depth",
    product(
        [
            # Regression.
            1337,
            1753613141,
            1753611814,
            1753621678,
        ]
        # Random seeds.
        + [None for _ in range(10)],
        [8, 16],
        [7, 15, 31],
    ),
)
def test_cocotb_runner(
    seed: int | None, data_width: int, fifo_depth: int, tmp_path: Path
) -> None:
    sim = os.getenv("SIM", "nvc")

    module_path = THIS_DIR / "modules" / "pretty_fast_fifo"
    sources = [
        # Manual compile order :(
        module_path / "src" / "math_pkg.vhd",
        module_path / "src" / "resync_hamming1.vhd",
        module_path / "src" / "pretty_fast_fifo.vhd",
        module_path / "src" / "pretty_fast_fifo_no_ready.vhd",
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="pretty_fast_fifo",
        always=True,
        build_dir=tmp_path / "sim_build",
        # Use the above when running multiple tests in parallel.
        # Use the below when debugging to get a static waveform file location.
        # build_dir="sim_build",
        waves=True,
    )

    runner.test(
        test_module="test_pretty_fast_fifo",
        hdl_toplevel="pretty_fast_fifo",
        seed=seed,
        waves=True,
        gui=False,
        parameters={"DATA_WIDTH": data_width, "FIFO_DEPTH": fifo_depth},
    )
