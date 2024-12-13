Steps:

1. Construct the complete graph (DONE)
2. Extract principal information (DONE)
3. Reduce the graph by aggregating chains of degree-2 nodes (~DONE, some issue with handling tanks)
4. Find the best Laplacian
5. Try to find the best fit (scale free, random, geometric, etc)
6. Look at the demand data patterns

## Vulnerability Analysis

The main focus of this project is on vulnerability analysis. The goal is therefore to find bottlenecks or weak points in the network topology through different measures. For example, we might look at the betweenness centrality, since nodes with high betweenness centrality are often bottlenecks.
Finding the minimum cut in a graph can also reveal weak points: the minimum cut is the smallest set of edges whose removal would disconnect the graph, hence edges in the minimum cut are rather critical.
This paper (https://doi.org/10.1007/s41109-021-00427-x) also points out that we can find critical edge and node criticality using probabilistic measures such as Jensen-Shannon divergence or Wasserstein distance to evaluate the impact of failures on overall network performance. 

Critical nodes (e.g with high centrality) may be more sensitive to demand variations: we will therefore assess sensitivity by correlating demand data with different network properties and measures of criticality to identify critical factors influencing demand.

Note: just because all demand nodes (with positive demand coefficients) are associated with a single pattern, it made any temporal analysis of the network impossible. Indeed the nodes would just be degrees of the same patterns, since the way demand evolution is transcribed is via the mulitiplicifaction of a load coefficient with a data pattern (in our case one only for all demand nodes).
Anyway the temporal depth would have been low since we only have data over 48 hours. This study will therefore specifically focus on the relation between demand data and node centrality, with a reflection on graph transformations.

### Measures Used

1. Node degree based on connectivity 
2. Node degree taking lengths of adjacent edges
3. Shortest path to a tank
4. Closeness centrality measures how close a node is to all other nodes in the network
5. Betweenness centrality measures how often a node lies on the shortest path between other pairs of nodes
6. Eccentricity of a node is the maximum distance between that node and any other node in the graph

### Results


## Graph Transformations

I was not able to get a proper graph transformation on time, such that I would be able to perform the elements I mention in the section on Graph Fitting (see Future Work). The only graph transformation I have available is aggregating all chains of degree-2 nodes into a single node, with aggregated demand as the total demand across the previous chain. However I had for this to discard the presence of tanks and pumps.
We can still employ most of the measures (except the measures 2. and 3.) and test whether this transformation preserves correlation between centrality measures and demand patters, it it reveals new patters, or neither.

### Analysis

## Future Work

### Graph Fitting

A step I was originally interested (but I moved away from it to concentrate on a criticality analysis of the nodes) is trying to fit the input network with random models such as scale-free, geometric or Erdős–Rényi graphs. 
It is highly unlikely that any of these graphs would be able to fit the actual network (because the water distribution network is constrained by physical constraints which leads to a very low average degree, assortativity and entropy) however, some of these models would probably be able to capture some facets of the original graphs, and seing the gap between the 
theoretical model and the real-world network can help capture the elements that are, precisely, due to physical constraints that random models cannot capture. 
Another element is the fact that there are certainly certain graph transformations (mainly graph reduction) that would lead to a model that is much better explainable with theoretical models, once we have discounted the redundancy that arises purely from the geographical requirement to deploy a network over a given area. However the reason that made me shift my focus was also the purely implementation-related difficulties involved in carrying out such transformations correctly. a last point is of course the model assumptions that come with each type of transformation (e.g. based on aggregating chaines of degree-2 nodes, or clustes, depending on the selected clustering algorithm, etc.)

### Flow Estimation

A future step would be to find a better representation of the network flow (since now we only consider structural properties or a first approximation of the weights, using distance). There are two possible orientations:

1. Simulating a hydraulic model to recreate the flow between all nodes and the tank levels, and use this physical estimation of the flow as weights
2. Try to find the optimal Laplacian: trying to fit a Laplacian to minimize smoothness over input signals

### Graph Comparison

Higher level estimation of the criticality of a graph: the Laplacian matrix is closely related to the Cheeger constant, which measures the "bottleneckedness" of a graph (a small Cheeger constant indicates the presence of bottlenecks). 
Hence, we can use this as a measure of the criticallity of a graph, and then be able to compare different water distribution systems. This would be another possible orientation, especially usefull to compare scenarios and help guiding decision-making.
For this task, it is however crucial to have a Laplacian matrix that would correctly represent the network.