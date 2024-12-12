Plan:

1. Construct the complete graph
2. Extract principal information
3. Reduce the graph by aggregating chains of degree-2 nodes
4. Find the best Laplacian
5. Try to find the best fit (scale free, random, geometric, etc)
6. Look at the demand data patterns
7. Correlate demand data with network properties such as node centrality, pipe length, etc. to identify critical factors influencing demand.
8. Cluster nodes based on similar demand patterns and topological features (e.g., using modularity optimization, Louvain method)

Focus on vulnerability analysis (probably from Laplacian):

* Assess edge and node criticality using probabilistic measures such as Jensen-Shannon divergence or Wasserstein distance to evaluate the impact of failures on overall network performance. See https://doi.org/10.1007/s41109-021-00427-x
* Identify bottlenecks or weak points in the network topology.
* Nodes with high centrality may be more sensitive to demand variations: assess sensitivity to demand changes


        # igraph automatically removes edge when using delete_vertices()