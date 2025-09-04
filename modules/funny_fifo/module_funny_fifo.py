# --------------------------------------------------------------------------------------------------
# Copyright (c) Lukas Vik. All rights reserved.
# --------------------------------------------------------------------------------------------------

from tsfpga.constraint import Constraint
from tsfpga.module import BaseModule
from tsfpga.vivado.project import VivadoNetlistProject, VivadoProject

from build_fpga import get_modules


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
                name="fifo_fpga_no_handshake",
                modules=modules,
                part=part,
                top="fpga_top",
                generics={"data_width": 32, "fifo_depth": 7},
                constraints=constraints,
            )
        )

        projects.append(
            VivadoProject(
                name="fifo_fpga_with_handshake",
                modules=modules,
                part=part,
                top="fpga_top",
                generics={"data_width": 16, "fifo_depth": 7, "use_handshake": True},
                constraints=constraints,
            )
        )

        projects.append(
            VivadoProject(
                name="fifo_fpga_vendor",
                modules=modules,
                part=part,
                top="fpga_top",
                generics={"data_width": 32, "fifo_depth": 7, "use_ip_core": True},
            )
        )

        projects.append(
            VivadoNetlistProject(
                name="funny_fifo_with_handshake",
                modules=modules,
                part=part,
                top="funny_fifo_with_handshake",
                generics={"data_width": 32, "fifo_depth": 7},
                constraints=constraints,
            )
        )

        projects.append(
            VivadoNetlistProject(
                name="funny_fifo_no_handshake",
                modules=modules,
                part=part,
                top="funny_fifo_with_handshake",
                generics={"data_width": 32, "fifo_depth": 7},
                constraints=constraints,
            )
        )

        return projects
