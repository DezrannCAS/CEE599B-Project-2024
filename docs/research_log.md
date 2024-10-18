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
- Base demand load is given for all junctions, this base demand is then multiplied by the demand pattern to get the actual demand at any given time
- There are no vertices defined: hence we are representing pipes as straight lines between nodes
- Temporal resolution:
	* Time step: 1 hour
	* Simulation duration: 48 hours -- however, each pattern has 80 multipliers, suggesting a simulation period of 80 hours...
	* Starting time: 12am

We also have some labels providing geographic references (towns, roads, infrastructures, etc).

There are 18 different patterns: 14977 junctions are type "1", and 1 junction for every remaining type. All of these special junctions (other than type "1") have negative demand $(-450, -700, -4900, -1000, -1400, -1900, -2100)$. 4 of these patterns only contains $0$ ("28-W15", "25-W38", "27-W20", "31-W21").

### 2. Basic data analysis

**Goal:** Output basic plots (graphs and time series) and statistics; understand curves (for pumps) and patterns (for junctions) -- maybe check also frequency of controls, etc

## Reflections
... 

## Future Work
...
