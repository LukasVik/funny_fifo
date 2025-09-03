# --------------------------------------------------------------------------------------------------
# Copyright (c) Lukas Vik. All rights reserved.
# --------------------------------------------------------------------------------------------------

from pathlib import Path

from tsfpga.constraint import Constraint
from tsfpga.module import BaseModule
from tsfpga.vivado.project import VivadoNetlistProject, VivadoProject

from development_tools import get_modules

THIS_FILE = Path(__file__)


class Module(BaseModule):
    def get_build_projects(self) -> list["VivadoProject"]:
        projects = []

        modules = get_modules()
        part = "xcku5p-sfvb784-3-e"

        constraints = [
            Constraint(constraint_path)
            for constraint_path in (self.path / "tcl").glob("*.tcl")
        ]

        projects.append(
            VivadoProject(
                name="fifo_fpga",
                modules=modules,
                part=part,
                top="fpga_top",
                generics={"data_width": 32, "fifo_depth": 7, "use_ready": True},
                constraints=constraints,
                defined_at=THIS_FILE,
            )
        )

        projects.append(
            VivadoProject(
                name="fifo_fpga_no_ready",
                modules=modules,
                part=part,
                top="fpga_top",
                generics={"data_width": 32, "fifo_depth": 7, "use_ready": False},
                constraints=constraints,
                defined_at=THIS_FILE,
            )
        )

        projects.append(
            VivadoNetlistProject(
                name="pretty_fast_fifo",
                modules=modules,
                part=part,
                top="pretty_fast_fifo",
                generics={"data_width": 32, "fifo_depth": 7},
                constraints=constraints,
                defined_at=THIS_FILE,
            )
        )

        projects.append(
            VivadoNetlistProject(
                name="pretty_fast_fifo_no_ready",
                modules=modules,
                part=part,
                top="pretty_fast_fifo_no_ready",
                generics={"data_width": 32, "fifo_depth": 7},
                constraints=constraints,
                defined_at=THIS_FILE,
            )
        )

        return projects
