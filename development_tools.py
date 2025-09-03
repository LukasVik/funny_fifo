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

import sys
from pathlib import Path
from typing import TYPE_CHECKING

REPO_ROOT = Path(__file__).parent.resolve()
EXTERNAL_PATH = REPO_ROOT / "external"

sys.path.insert(0, str(EXTERNAL_PATH / "hdl-registers" / "hdl-registers"))
sys.path.insert(0, str(EXTERNAL_PATH / "tsfpga" / "tsfpga"))
sys.path.insert(0, str(EXTERNAL_PATH / "vunit" / "vunit"))

from tsfpga.module import get_module as get_module_tsfpga

if TYPE_CHECKING:
    from tsfpga.module import BaseModule


def get_module() -> BaseModule:
    return get_module_tsfpga(
        name="pretty_fast_fifo", modules_folder=REPO_ROOT / "modules"
    )
