# Research Log

## Project Info
- **Statistical Methods for Water Distribution Networks**
- Esteban Nocet-Binois
- en4624@princeton.edu
- *CEE599B*

## Research Objectives
...

## Data Source
- **Type of Data:** [05 NJ 1](https://uknowledge.uky.edu/wdst_us/5/) Water Distribution System
- **Source:** [Kentucky Water Research Institute](https://uknowledge.uky.edu/kwrri/)
- **Collection Method:** ?

## Progress Updates

### 1. Dataset

**Goal:** Explore, restructure and clean data

**Findings:** This dataset contains:

- 14,991 junctions and 8 tanks (14,999 coordinates in total), but no reservoirs
- 16,066 pipes and 12 pumps, but no valves -- 3 pipes and 3 pumps are closed
- Pumps' global efficiency is 85%
- We also have the curves for all pumps
- There are 126 controls, that are time-based rules for the pumps (closing, opening or setting to a certain value)
- The demand (load coefficient) is given for all junctions, this coefficient is then multiplied by the demand pattern to get the actual demand at any given time
- There are no vertices defined: hence we are representing pipes as straight lines between nodes (but we know the actual length of the pipes, as well as the diameter)
- Temporal resolution:
	* Time step: 1 hour
	* Simulation duration: 48 hours -- however, each pattern has 80 multipliers, suggesting a simulation period of 80 hours...
	* Starting time: 12am

We also have some labels providing geographic references (towns, roads, infrastructures, etc).

There are 18 different patterns: 14977 junctions are type "1", and 1 junction for every remaining type. All of these special junctions (other than type "1") have negative demand (-450, -700, -4900, -1000, -1400, -1900, -2100): do they represent inflows other than tanks? Four of these patterns only contains zeros ("28-W15", "25-W38", "27-W20", "31-W21").

The curves for the pumps are three- or four-point curves, with 2D points: head gain (ft) on the $y$-axis and flow rate (gpm) on the $x$-axis. Write the function to fit a continuous function of the form $h_G = A-Bq^C$, where $h_g=$ head gain, $q=$ flow rate, and $A, B, C$ are constants.

### 2. Basic data analysis

**Goal:** Output basic plots (graphs and time series) and statistics (node degree, edge density, centrality); maybe check also frequency of controls, etc

### 3. WDS as Graph

**Goal:** Understand the [network model](https://epanet22.readthedocs.io/en/latest/3_network_model.html), in particular the curves (for pumps) and patterns (for junctions) + flow model. Derive pressure levels over time at the nodes given initial tank levels, pump switching rules, and demand at nodes.

**Model:** 

* Directed graph: Directed flow through pipes.
* Weighted graph: Edges are weighted via flow or water travel time, computed as $$T = \frac{L}{V \times 3600}$$ where $T$ is in hours, $L$ in meters and $V$ in metres per second.
* Temporal graph: The flow is recorded at 1-h intervals.

### 4. Disruptions in WDS

**Goal:** Estimate the effect on water supply of different types of disruptions (at junctions, pumps or tanks), i.e. the fraction of fully served nodes (or supply gap).

## Reflections
... 

## Future Work
...
