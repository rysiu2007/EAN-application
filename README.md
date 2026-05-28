# SimplifiedNewton — Nonlinear System Solver Desktop Application (x64 ASM / C++)

## 1. Application Overview
This repository contains a high-performance Windows desktop software driven by a native **Graphical User Interface (GUI)** designed to solve complex systems of $n$ nonlinear equations:

$$f_k(x_1, x_2, \dots, x_n) = 0, \quad k=1,2,\dots,n$$

The architecture follows a hybrid design pattern to maximize hardware efficiency. The visual layer, text string parsers, and dynamic resource management are built in **C++ (WinAPI)**, whereas the numerical calculation solver and multi-precision internal types are written completely in **low-level x64 Assembly (MASM)** utilizing 80-bit **Intel x87 FPU hardware registers**.

---

## 2. Dynamic GUI & The 3 Operational Modes
The desktop interface acts as a control deck, utilizing a unified messaging queue (`DialogProc`) to process data inputs and configuration states. Users can select between **three distinct operational modes** backed by custom low-level mathematical engines:

1. **Point Mode (`float80`):** Classical floating-point arithmetic. Equations and their partial derivatives ($\frac{\partial f_i}{\partial x_i}$) are evaluated directly at exact coordinate positions inputted through the GUI text fields using native 80-bit precision variables. The right boundary interface (`IDC_EDIT3`) is automatically disabled.
2. **Pure Interval Mode (`pure_interval`):** Rigorous interval arithmetic. The interface accepts custom interval brackets (`[inf; sup]`) defining input uncertainties. The assembly core applies stable interval division and contractive intersections to preserve inclusion.
3. **Interval Extension Mode (`interval_float_data`):** A verification scheme where users pass point scalars through the GUI. The backend automatically transforms them into an optimal interval enclosure by determining the *previous* and *next machine numbers* around the input scalar, enabling visual verification of solver stability against floating-point underflow or anomalies near machine zero ($0.0$).

All runtime updates, loaded values, and hardware diagnostic logs are piped via an `extern "C"` callback routine (`OutputLog`) into an interactive scrolling text box.

---

## 3. Dynamic Plug-in Loading (DLL Integration)
The application avoids hardcoding equations by integrating a dynamic runtime plug-in architecture:
* Users load an external equation library (`.dll`) through a system file dialog wrapper (`GetOpenFileNameA`).
* The application invokes `GetNum` to query the total equation dimension, dynamically allocating memory arrays (`func` and `dfunc`) on the heap.
* Symbols are automatically linked using standard name binding conventions (`"f1"`, `"df1"`, ..., `"fN"`, `"dfN"`), completely separating the solver algorithm from equation definitions.

---

## 4. Register Management & ABI Compliance
The core assembly implementation (`.asm`) strictly conforms to the **Microsoft x64 Calling Convention (ABI)** to guarantee flawless interoperability with the C++ WinAPI event loops:
* Non-volatile preservation of registers (`rbx`, `rbp`, `r12` - `r15`, `rsi`, `rdi`).
* Explicit local allocation of compiler stack alignments and protection of the mandatory 32-byte **Shadow Space**.
* Implementation of custom memory packaging via `#pragma pack(push, 1)` to enforce byte-perfect 20-byte unions mapping single points to dual-bound intervals.

---

## 5. Compilation & Build Guide (CMake)
The build pipeline utilizes **CMake** to handle multi-language dependency compilation, invoking MSVC compiler setups alongside the Microsoft Macro Assembler (`ml64.exe`) targeting native 64-bit binaries.

### Prerequisites:
* **OS:** Windows 10 / 11 (x64 Native architecture)
* **Compiler:** Microsoft Visual Studio (MSVC Toolset v140 or higher) with x64 components
* **Build System:** CMake (Version 3.15 or newer)

### Build Instructions:
```bash
# 1. Open your x64 Native Tools Command Prompt for VS
cd "EAN app"

# 2. Create and enter a build directory
mkdir build
cd build

# 3. Generate target compilation build configurations
cmake -A x64 ..

# 4. Compile the desktop application and dependencies
cmake --build . --config Release
```
Upon a successful build, the system generates the executable graphical package (CMakeTarget.exe) linked against the internal static library (MathCore.lib) and dynamic extensions.  
## 6. Real-time Sanitization & Hardware Exceptions
* **Strict Lexical Validation:** The program invokes rigorous pattern checkers (`IsFormatXX_Strict`) during input focus shifts (`EN_KILLFOCUS`), discarding malformed or non-numeric inputs prior to execution.
* **Convergence Bounds:** Parameter constraints are strictly enforced at runtime; if a relaxation parameter falls out of bounds ($\omega \le 0$ or $\omega \ge 2$), execution is locked out to prevent numerical divergence.
* **FPU Exception Shielding:** In case of non-convergence, division-by-zero, or undefined instructions, the assembly layer safely traps the failure state on the x87 status word. The system captures the state without crashing, displaying the diagnostic error code (e.g., `0x26`) while automatically resetting FPU flags using `ClearX87Errors` (`fnclex`) for subsequent computations.