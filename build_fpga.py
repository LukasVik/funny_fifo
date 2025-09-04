# --------------------------------------------------------------------------------------------------
# Copyright (c) Lukas Vik. All rights reserved.
# --------------------------------------------------------------------------------------------------
# Requires a development version of cocotb:
#   python3 -m pip install --upgrade git+https://github.com/cocotb/cocotb.git
# Run test cases with
#   python3 -m pytest -v -n32 test_funny_fifo.py
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

from tsfpga.build_project_list import BuildProjectList
from tsfpga.examples.build_fpga_utils import arguments, collect_artifacts, setup_and_run
from tsfpga.module import get_modules as get_modules_tsfpga

if TYPE_CHECKING:
    from tsfpga.module_list import ModuleList


def get_modules() -> ModuleList:
    return get_modules_tsfpga(modules_folder=REPO_ROOT / "modules")


def main() -> None:
    """
    Copied from tsfpga/examples/build_fpga.py.
    """
    args = arguments(default_temp_dir=REPO_ROOT / "generated")

    modules = get_modules()
    projects = BuildProjectList(
        modules=modules,
        project_filters=args.project_filters,
        include_netlist_not_top_builds=args.netlist_builds,
        no_color=args.no_color,
    )

    sys.exit(
        setup_and_run(
            modules=modules,
            projects=projects,
            args=args,
            collect_artifacts_function=collect_artifacts,
        )
    )


if __name__ == "__main__":
    main()
