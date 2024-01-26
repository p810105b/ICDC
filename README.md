# IC Design Contest

This repository contains my submissions for the IC Design Contest. 
You can find more information about the contest [here](https://moeisoc.web2.ncku.edu.tw/p/406-1166-211155,r11.php?Lang=zh-tw). 
Each folder corresponds to the respective year's competition and includes problem statements, RTL code, testbench, synthesis reports, and other relevant files.


| Year | Level | Project Name | Clock Period | A Grade Standards                       | Specifications                           | Grade |
|------|-------|--------------|--------------|-----------------------------------------|------------------------------------------|-------|
| 2023 | Grad  | LASER        | 8 ns         | Area < 37000um²                         | Area: 28246.4um² <br> Cycle: 56574       |  A    |
| 2022 | Grad  | JAM          | 10 ns        | Area < 10000um²<br>Cycle < 430000       | Area: 8337.6um²  <br> Cycle: 362877      |  A    |
| 2021 | Univ  | Geofence     | 30 ns        | Area < 22000um²                         | Area: 16731.3um² <br> Cycle: 2505        |  A    |


## 2023 : LASER
The key objective for 2023 was to use iterative methods to find two circles that could cover the maximum number of target points.

- **Circuit Design:**
  - **4-Processor Version:**
    - Area: 23614.2 um²
    - Cycle Count: 112894
    - All patterns passed successfully.
  - **8-Processor Version:**
    - Area: 28246.4 um²
    - Cycle Count: 56574
    - All patterns passed successfully.

#### Grade A Standards for 2023:
- [x] Gate-Level and RTL simulation must be completely accurate under a clock cycle of 8 ns.
- [x] Area < 37,000 um²

## 2022 : JAM (Jan Assignment Machine)
The focus for 2022 was on implementing the lexicographical permutation algorithm in a circuit.

- **Circuit Design:**
  - Area: 8337.6 um²
  - Cycle Count: 362877
  - All patterns passed successfully.

#### Grade A Standards for 2022:
- [x] Gate-Level and RTL simulation must be completely accurate under a clock cycle of 10 ns.
- [x] Total simulation cycle count < 430,000 cycles.
- [x] Area < 10,000 um²

## 2021 : Geofence
The challenge for 2021 was to sort six coordinate points in a clockwise (or counterclockwise) order using the cross product of vectors, and then to use the cross product again to determine if an object is within the geofence formed by these points.

- **Circuit Design:**
  - Area: 16731.3 um²
  - Cycle Count: 2505
  - All patterns passed successfully.

#### Grade A Standards for 2021:
- [x] Gate-Level and RTL simulation must be completely accurate under a clock cycle of 30 ns.
- [x] Area < 22,000 um²

---
