#!/bin/bash

clang-format -i boot/*.c

clang-format -i boot_rom/*.c
clang-format -i boot_rom/*.h

clang-format -i drivers/**/*.c
clang-format -i drivers/**/*.h

clang-format -i etherboot/**/*.c
clang-format -i etherboot/**/*.h

clang-format -i fs/**/*.c
clang-format -i fs/**/*.h

clang-format -i include/**/*.h

clang-format -i lib/**/*.c
clang-format -i lib/**/*.h

clang-format -i menu/**/*.c
clang-format -i menu/**/*.h

clang-format -i pc_tools/**/*.c
clang-format -i pc_tools/**/*.cpp
clang-format -i pc_tools/**/*.h

clang-format -i xblast/**/*.c
clang-format -i xblast/**/*.h
