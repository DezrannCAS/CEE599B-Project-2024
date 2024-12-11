# Once we get actual weights and Laplacian
g <- readRDS("original_graph.rds")
W <- compute_weights(g)
L <- compute_Laplacian(g)

# Graph diameter
graph_diameter <- diameter(g, directed = FALSE, weights = W)
cat("Graph diameter:", graph_diameter, "\n")

# Coherence
compute_coherence <- function(graph, laplacian) {
  eigvals <- eigen(laplacian)$values
  non_zero_eigenvalues <- eigvals[eigvals > 1e-5]
  coherence <- 1 / mean(non_zero_eigenvalues)
  return(coherence)
}
coherence <- compute_coherence(g, L)
cat("Coherence (C):", coherence, "\n")

# Average shortest path length
avg_shortest_path <- mean_distance(g, directed = FALSE, weights = W)
cat("Average shortest path length (d):", avg_shortest_path, "\n")

# Natural Connectivity
compute_natural_connectivity <- function(laplacian) {
  eigenvalues <- eigen(laplacian)$values
  natural_connectivity <- log(mean(exp(eigenvalues)))
  return(natural_connectivity)
}
natural_connectivity <- compute_natural_connectivity(L)
cat("Natural connectivity (robustness, \\bar{λ}):", natural_connectivity, "\n")

# Betweenness (Demand Edge Betweenness Centrality)
demand_edge_betweenness <- edge_betweenness(g, weights = W)
E(g)$betweenness <- demand_edge_betweenness
cat("Demand edge betweenness (example):\n")
print(head(E(g)$betweenness))