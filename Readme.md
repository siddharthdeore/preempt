# Real Time Threads with PREEMPT_RT 
Example implementaion of real time threads with wrapper for POSIX thread.
# Prerequisite
<b>NOTE:</b> Make sure you have already patched PREEMPT_RT kernel, follow [instruction.md](instruction.md) to patch and install.

# Building real time periodic thread
Download the source code and compile
```console
git clone https://github.com/siddharthdeore/preempt.git
cd preempt
mkdir build
cmake ..
make
```

Execute example program with PREEMPT_RT
```console
cd ../bin
sudo ./rt_thread
```


# Troubleshoot

Issue: Unexpected freeze issue on COM Express Type 6

## Description:
COM Express running Ubuntu 20.04 LTS freezes unexpectedly, this recurrent behavior has been noticed when processor usage goes close to 100%
similar issue arise on when program/threads uses all processor cores, and when real time thread is affine to specific core.

## Solution:
This behaviour obsereved with Ubuntu 18.04 LTS and 22.04 LTS and expected cause of such freezes is related to "CPU Power Management".
Disabling all CPU power managements seems to have solved problem.
Steps to Disable

Press "F2" or "DEL" key to enter Aptio Bios Setup utility.
Select Advanced Tab
```console
> Advanced
  > Power & Performance
    > CPU - Power Management Control
        Set Boot mode                   [Turbo Performance]
        Intel(R) SpeedStep(tm)          [Disable]
        Race To Halt (RTH)              [Disable]
        Intel(R) Speed Shift Technology [Disable]
        HDC Control                     [Disable]
```


# TODO
- ~~Simple Realtime Periodic Thread Program~~
- ~~minimal realtime example~~
- realtime jitter test example

- Some of the tools listed below to be tested and integrated
    - Linux Trace Toolkit
    - Dynamic Probes
    - kGDB (kernel debugger)
    - Linux Kernel Crash Dump
    - Linux Test Project
    - LMBench
    - Ballista
    - strace
    - System Call Tracker

# Maintainers
This repository is maintained by:

| <img src="https://avatars.githubusercontent.com/u/12745747" width="32">  | [Siddharth Deore](https://github.com/siddharthdeore) |
|--|--|
