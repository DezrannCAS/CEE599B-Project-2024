# Statistical Methods for Water Distribution Networks
**Esteban Nocet-Binois**

*Github page:* [CEE599B-Project-2024](https://github.com/DezrannCAS/CEE599B-Project-2024.git) 
* See [docs](https://github.com/DezrannCAS/CEE599B-Project-2024/tree/main/docs) for proposal and current progress.
* See [src](https://github.com/DezrannCAS/CEE599B-Project-2024/tree/main/src) for source code (containing graph in R, methods, and eventually analysis).
* See [data](https://github.com/DezrannCAS/CEE599B-Project-2024/tree/main/data) for original 'NJ1.inp' file, as well as my data pipeline and the resulting '.csv' files.

## Research Purpose

The goal is to explore statistical methods on graphs such as model selection and graph parameter estimation, uncertainty propagation, correlation and clustering in graphs, going beyond simple measures of graph topology (number of edges, degree of nodes, average path length, centrality, etc), in order to tackle:

- Hydraulic modeling and simulation
- Network design and expansion

Most advances in this type of work focus on biological and brain networks, for tasks such as identification and correlation of functional sub-networks, or network classification (eg, sound or diseased).

One other topic of interest is that of subgraphs and boundary effects: 

## Datasets
We need a data that contains, ideally:

- Geometry -- *static*
	* Three types of nodes: demand nodes (hydrants), source nodes (reservoirs and tanks) and junctions (pipe connections)
	* Two types of edges: distribution pipes (mains and branches) and pumps (where pressure and flow can be controlled)
- Flow-volume through pipes -- *temporal*
- Pressure at junctions -- *temporal*
- Demand data -- *temporal*
- Topography (elevation and spatial coordinates) is optional
- No data on water quality is needed (hydrolic analysis only)

For this purpose the following water distribution systems (WDS, see [here](https://www.uky.edu/WDST/PDFs/) and [here](https://uknowledge.uky.edu/wdsrd/)) can be used: Anytown, Balerma (447 nodes), FossPoly 1, Hanoi from LeakDB (32 nodes), Modena, ZJ (115 nodes), [C-Town](https://github.com/DiTEC-project/gnn-pressure-estimation/blob/main/inputs/ctown.inp) (396 nodes), D-Town (406 nodes) and [L-Town](https://github.com/KIOS-Research/BattLeDIM/tree/master/Dataset%20Generator) (782 nodes), and the [Kentucky dataset](https://uknowledge.uky.edu/wdst/) (in particular Ky1, Ky6, Ky8, and Ky10).

For our study, we will be considering the [05 NJ 1 system](https://uknowledge.uky.edu/wdst_us/5/) that has been used in three other articles, by  [Maslia et al. (2000)](https://doi.org/10.1061/(ASCE)0733-9496(2000)126:4(180)), [Hoagland et al. (2015)](https://doi.org/10.1061/9780784479162.064) and [Hwang & Lansey (2017)](https://doi.org/10.1061/(ASCE)WR.1943-5452.0000850). It contains eight tanks, 12 pumps, and 483 miles of pipe.

![NJ1 network based on the Dover Township, NJ Distribution system](plot_nj1.pdf)

**Reference:**

* [Tello et al. (2024)](https://doi.org/10.3390/engproc2024069050): "Large-Scale Multipurpose Benchmark Datasets for Assessing Data-Driven Deep Learning Approaches for Water Distribution Networks"
* [Jolly et al. (2014)](http://dx.doi.org/10.1061/(ASCE)WR.1943-5452.0000352): "Research Database of Water Distribution System Models"
* [Adraoui et al. (2024)](https://doi.org/10.3390/w16050646): "Towards an Understanding of Hydraulic Sensitivity: Graph
Theory Contributions to Water Distribution Analysis" -- see Section 5.1

## Methodology

### 1. Model Estimation
**Motivation:** The estimated model can be used for scenario generation, deviation estimation, and help gain insights into the network's structural properties. The advantage of this approach is (i) the modelization of large-scale interdependencies as realizations of (partially) random processes on graphs and (ii) the integration of real-world data for network reconstruction, graph estimation, model evaluation, error and bias estimation.


See work from André Fujita and Daniel Yasumasa Takahashi, in particular article 4. [(2020)](https://doi.org/10.1093/comnet/cnz028) that provides the algorithms.

Analyze the graph structure variability: given an adjacency matrix $A$, we derive

- the spectrum of $G$, that is, the set of eigenvalues $(\lambda_1 \geq \lambda_2 \geq \dots \geq \lambda_n)$
- the spectral distribution of $G$
- the graph spectral entropy

Use Kullback-Leibler divergence to compare the performance between various graph models, such as the Erdos-Renyi random graph, Geometric random graph, K-regular random graph, Watts-Strogatz model, Barabási-Albert model, etc. 

Note: for our model, the spatial component is important (it can be also in brain networks but usually overlooked), this is why using spatial random models would be interesting. The idea of a distribution topology, where nodes have higher probability of connection based on topological distance is very interesting because we can derive actual mathematical insights from the topological space. It is also linked to the topics of limit graphs, interpolation and kriging.

Also, the larger the network the most interesting/applicable this approach is.


**References:**

#. [Fujita et al. (2017)](https://doi.org/10.3389/fnins.2017.00066): "A Statistical Method to Distinguish Functional Brain Networks" -- focus on autism and Asperger
#. [Fujita et al. (2017)](https://doi.org/10.1016/j.csda.2016.11.016): "Correlation between graphs with an application to brain network analysis" -- focus on autism spectrum disorder
#. [Takahashi et al. (2012)](https://doi.org/10.1371/journal.pone.0049949): "Discriminating Different Classes of Biological Networks by Analyzing the Graphs Spectra Distribution" -- foci on protein-protein interactions and ADHD
#. [Fujita et al. (2020)](https://doi.org/10.1093/comnet/cnz028): "A semi-parametric statistical test to compare complex networks" -- focus on PPI networks of enteric pathogens

### 2. Spectral Clustering
**Motivation:** Spectral clustering can help forming zones in the WDS for efficient management and control.

**References:**

#. [Nascimento & de Carvalho (2011)](https://doi.org/10.1016/j.ejor.2010.08.012): "Spectral methods for graph clustering -- A survey"
#. [von Luxburg (2007)](https://doi.org/10.1007/s11222-007-9033-z): "A tutorial on spectral clustering"
#. [Spielman (2007)](https://doi.org/10.1109/FOCS.2007.56): "Spectral Graph Theory and its Applications"
#. [Sarkar & Jalan (2006)](https://doi.org/10.1063/1.5040897): "Spectral properties of complex networks"

See also these [papers with code](https://paperswithcode.com/task/spectral-graph-clustering).

### 3. Graph Fourier Transform
**Motivation:** GFT can help reduce noise in sensor measurements and monitor the WDS with minimal data.

**References:**

#. [Schultz et al. (2020)](https://doi.org/10.1109/RWS50334.2020.9241286): "Graph Signal Processing for Infrastructure Resilience: Suitability and Future Directions"
#. [Wei et al. (2020)](https://doi.org/10.1109/TNSE.2019.2941834): "Optimal Sampling of Water Distribution Network Dynamics Using Graph Fourier Transform"
#. [Wei et al. (2019)](https://doi.org/10.1109/ISC246665.2019.9071735): "Monitoring Networked Infrastructure with Minimum Data via Sequential Graph Fourier Transforms"
#. [Pagani et al. (2021)](https://doi.org/10.1145/3461838): "Neural Network Approximation of Graph Fourier Transform for Sparse Sampling of Networked Dynamics"

### 4. Uncertainty Propagation

**References:**

#. [Rebrova & Salanevich (2024)](https://doi.org/10.48550/arXiv.2306.15810): “On Graph Uncertainty Principle and Eigenvector Delocalization”, with [code available](https://github.com/erebrova/uncertainty-delocalization)
#. [Arola-Fernandez et al. (2020)](https://doi.org/10.1063/1.5129630): "Uncertainty propagation in complex networks: from noisy links to critical properties"
#. [Ji et al (2023)](https://doi.org/10.1016/j.physrep.2023.03.005): "Signal propagation in complex networks"

### 5. GNN for State Estimation

**References:**

#. [Pagani et al. (2021)](https://doi.org/10.1145/3461838): "Neural Network Approximation of Graph Fourier Transform for Sparse Sampling of Networked Dynamics"
#. [Li et al. (2024)](https://doi.org/10.1016/j.watres.2023.121018): "Real-time water quality prediction in water distribution networks using graph neural networks with sparse monitoring data"
#. [Truong et al. (2024)](https://doi.org/10.1029/2023WR036741): "Graph Neural Networks for State Estimation in Water Distribution Systems"


## Bibliography

### General books
- [van Mieghem (2011)](https://doi.org/10.1017/CBO9780511921681): *Graph Spectra for Complex Networks*
- [Kolaczyk (2017)](https://doi.org/10.1017/9781108290159): *Topics at the Frontier of Statistics and Network Analysis*
- [Kolaczyk (2009)](https://doi.org/10.1007/978-0-387-88146-1): *Statistical Analysis of Network Data: Methods and Models*
- [Crane (2018)](https://www.harrycrane.com/networks): *Probabilistic Foundations of Statistical Network Analysis*
- [Bagrow & Ahn (2024)](https://doi.org/10.1017/9781009212601): *Working with Network Data: A Data Science Perspective*
- [Avrachenkov & Dreveton (2022)](https://doi.org/10.1561/9781638280514): *Statistical Analysis of Networks*
- [Kalyagin et al. (2020)](https://doi.org/10.1007/978-3-030-60293-2): *Statistical Analysis of Graph Structures in Random Variable Networks*
- See also Chapter 3 of "Network Science: An Aerial View"

### Other articles on graphs and WDS

#. [Adraoui et al. (2023)](https://doi.org/10.3390/w16050646): "Towards an Understanding of Hydraulic Sensitivity: Graph Theory Contributions to Water Distribution Analysis"
#. [Yu et al. (2024)](https://doi.org/10.1016/j.watres.2024.121238): "A review of graph and complex network theory in water distribution networks: Mathematical foundation, application and prospects"
#. [Herrera et al. (2016)](https://doi.org/10.1007/s11269-016-1245-6): "A Graph-Theoretic Framework for Assessing the Resilience of Sectorised Water Distribution Networks"
#. [Zingali et al. (2024)](https://doi.org/10.3390/engproc2024069181): "Application of Primary Network Analysis in Real Water Distribution Systems"
#. [Price & Ostfeld (2014)](https://doi.org/10.1016/j.proeng.2014.11.245): "Optimal Water System Operation Using Graph Theory Algorithms"


## Network Analysis in R
Checkout:

- <https://ladal.edu.au/net.html>
- <https://bookdown.org/jdholster1/idsr/network-analysis.html>
- <https://cran.r-project.org/web/packages/statGraph/>
