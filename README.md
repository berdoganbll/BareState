# BareState: Asynchronous Logic Controller 🚀

![Assembly](https://img.shields.io/badge/Language-Assembly-blue)
![Platform](https://img.shields.io/badge/Platform-Tiva%20C%20TM4C123G-red)
![Arch](https://img.shields.io/badge/Arch-ARM%20Cortex--M4-brightgreen)

## 📖 Overview
**BareState** is a low-level embedded project developed in ARM Assembly for the Cortex-M4 architecture. It implements a **Finite State Machine (FSM)** designed to track asynchronous input events (press and release cycles) from multiple hardware switches. 

The system operates at the register level with no middleware or HAL, providing deterministic control and real-time visual feedback through a custom external LED array.

## 🛠 Features
- **Bare-Metal Implementation:** Direct manipulation of GPIO Port F and Port B registers.
- **Asynchronous Event Tracking:** Processes interleaved input signals independently of their arrival order.
- **Dynamic LED Feedback:** Blinking states for active inputs and steady states for historical verification.
- **NMI Unlocking:** Low-level configuration to repurpose special-function pins (PF0).

## 🔌 Hardware Setup
This project is designed for the **TI Tiva C Series (TM4C123G) LaunchPad**. 

### 📥 Inputs (On-board Switches)
- **Switch 1 (PF4):** Primary input (Negative Logic).
- **Switch 2 (PF0):** Secondary input (Unlocked via hardware commit).

### 📤 Outputs (External Breadboard Circuit)
*Connect these via 330Ω resistors to avoid damaging the MCU:*
- **LED 1 (PB0):** Status for Switch 2. Toggles while held; stays ON after release.
- **LED 2 (PB1):** Status for Switch 1. Toggles while held; stays ON after release.
- **LED 3 (PB2):** Completion indicator. Illuminates only when the full sequence is finished.
- **GND:** Connect the external circuit ground to any **GND** pin on the LaunchPad.

## 🧠 Logical Flow
1. **Init:** Port clocks are enabled; PF0 is unlocked; internal Pull-ups are engaged for inputs.
2. **Poll:** The system monitors the switches. Upon a "Falling Edge" (Press), a flag is stored in a non-volatile register.
3. **Feedback:** An Exclusive-OR (EOR) operation creates a blinking effect while a button is active.
4. **Terminate:** The "Done" state is reached only when both input flags are high AND both physical switches are released (Logic 1).

## 📂 File Structure
- `Source/start.s`: Startup code and vector table definition.
- `Source/main.s`: Core FSM logic, GPIO drivers, and delay subroutines.
- `Project_Report.pdf`: Comprehensive documentation including the Discrete Event System (DES) state diagram and technical analysis.

## 🚀 How to Build
1. Install **Keil uVision 5**.
2. Create a project for the **TM4C123GH6PM** microcontroller.
3. Add `start.s` and `main.s` to the source folder.
4. Build the target and flash the `.bin` file to the LaunchPad using the ICDI debugger.

---
*Developed as a deep-dive into Bare-Metal ARM Development.*
