# UART RTL to GDS

Full custom ASIC implementation of a UART core, taken from RTL all the way to a manufacturable GDSII file using the OpenLane open-source flow on the SkyWater 130nm PDK.

---

## Project Overview

The design implements a standard 8N1 UART with a dedicated transmitter and receiver. The transmitter uses a shift register approach with a busy flag to prevent data overwrite, and the receiver implements a 4-state FSM (IDLE, START, DATA, STOP) with half-baud center sampling to correctly handle incoming serial data.

The entire digital backend — synthesis, floorplan, placement, clock tree synthesis, routing, and DRC/LVS signoff — was run through OpenLane without any manual intervention.

---

## UART Specifications

| Parameter     | Value                  |
|---------------|------------------------|
| Baud Rate     | 9600 (BAUD_DIV = 5208) |
| Clock         | 50 MHz                 |
| Data Bits     | 8                      |
| Parity        | None                   |
| Stop Bits     | 1                      |
| Format        | 8N1                    |
| PDK           | SkyWater Sky130        |
| Process Node  | 130nm                  |

---

## Port Description

| Port       | Direction | Width | Description           |
|------------|-----------|-------|-----------------------|
| `clk`      | Input     | 1     | System clock (50 MHz) |
| `rst_n`    | Input     | 1     | Active low reset      |
| `start`    | Input     | 1     | Start transmission    |
| `tx_data`  | Input     | 8     | Data to transmit      |
| `rx`       | Input     | 1     | Serial RX input       |
| `tx`       | Output    | 1     | Serial TX output      |
| `rx_data`  | Output    | 8     | Received data         |
| `rx_valid` | Output    | 1     | RX data valid flag    |
| `busy`     | Output    | 1     | TX busy flag          |

---

## Design Architecture

### Transmitter (uart_tx.v)
Loads the 10-bit frame `{stop, data[7:0], start}` into a shift register on assertion of `start`. The frame is clocked out LSB-first at the baud rate. A `busy` flag prevents new data from being loaded mid-transmission.

### Receiver (uart_rx.v)
Monitors the RX line in IDLE state. On detecting a falling edge (start bit), it waits half a baud period to align sampling to the center of each bit. Eight data bits are shifted in sequentially, and on a valid stop bit, `data_out` is updated and `valid` is pulsed for one clock cycle.

### Note on Metastability
The `rx` input crosses from an external clock domain into the internal `clk` domain. A 2-stage synchronizer was not added in this version, which is a known limitation. For a production design, adding a 2-FF synchronizer on the `rx` input before the IDLE state detection would be the correct approach to prevent metastability.

---

## Post-Implementation Results

| Metric              | Value                        |
|---------------------|------------------------------|
| Flow Status         | Successful                   |
| Standard Cell Count | 298                          |
| Chip Area           | 3659.76 um² (~60.5 x 60.5 um)|
| Fmax (STA)          | ~181 MHz                     |
| Operating Frequency | 50 MHz                       |
| Setup Slack         | 14.48 ns                     |
| Hold Slack          | 0.32 ns                      |
| TNS                 | 0.00 ns                      |
| WNS                 | 0.00 ns                      |
| Total Power         | 0.584 mW                     |
| Sequential Power    | 0.226 mW (38.6%)             |
| Combinational Power | 0.358 mW (61.4%)             |
| DRC Violations      | 0                            |
| LVS Status          | Clean                        |

---

## RTL to GDS Flow

```
RTL (.v)
   |
   v
Synthesis       -- Yosys
   |
   v
Floorplan       -- OpenROAD
   |
   v
Placement       -- OpenROAD
   |
   v
CTS             -- OpenROAD (Clock Tree Synthesis)
   |
   v
Routing         -- OpenROAD
   |
   v
DRC/LVS         -- Magic
   |
   v
GDSII
```

---

## Project Structure

```
uart_rtl_to_gds/
├── rtl/
│   ├── uart_top.v              top level module
│   ├── uart_tx.v               transmitter (shift register based)
│   └── uart_rx.v               receiver (4-state FSM)
├── tb/
│   ├── uart_tx_tb.v            TX testbench
│   └── uart_loopback_tb.v      loopback testbench
├── synth/
│   └── uart_netlist.v          synthesized netlist (Yosys output)
├── openlane/
│   └── uart_top/
│       └── config.json         OpenLane configuration
├── screenshots/
│   ├── gds_layout.png          final GDS in KLayout
│   └── simulation.png          GTKWave waveform
└── README.md
```

---

## Tools Used

| Tool              | Purpose                          |
|-------------------|----------------------------------|
| OpenLane          | RTL to GDS flow automation       |
| Yosys             | RTL synthesis                    |
| OpenROAD          | Floorplan, placement, CTS, route |
| Magic             | DRC and LVS signoff              |
| SkyWater Sky130   | 130nm open-source PDK            |
| KLayout           | GDS layout viewer                |
| Icarus Verilog    | RTL simulation                   |
| GTKWave           | Waveform viewer                  |

---

## How to Run

### 1. Set up OpenLane
```bash
git clone https://github.com/The-OpenROAD-Project/OpenLane.git
cd OpenLane
make
```

### 2. Clone this repo
```bash
git clone https://github.com/Mridul-Mor/uart_rtl_to_gds.git
cp -r uart_rtl_to_gds/openlane/uart_top OpenLane/designs/
cp uart_rtl_to_gds/rtl/* OpenLane/designs/uart_top/
```

### 3. Run the flow
```bash
cd OpenLane
make mount
./flow.tcl -design uart_top
```

### 4. View GDS
```bash
klayout designs/uart_top/runs/RUN_*/results/final/gds/uart_top.gds
```

---
