library(igraph)
library(dplyr)

# ------------- FUNCTIONS -------------

compute_centralities <- function(g) {
  data.frame(
    name = V(g)$name,
    demand = V(g)$demand,
    degree = degree(g),
    strength = strength(g, weights = E(g)$distance),
    closeness = closeness(g, weights = E(g)$distance),
    betweenness = betweenness(g, weights = E(g)$distance),
    eccentricity = eccentricity(g),
    tank_distance = all_min_distances_to_tanks(g, weights = E(g)$distance)
  )
}

all_min_distances_to_tanks <- function(graph, mode = "all", weights = NULL) {
  tank_nodes <- V(graph)[V(graph)$type == "tank"]
  if (length(tank_nodes) == 0) {
    warning("No tanks found in the graph.")
    return(rep(Inf, vcount(graph)))
  }

  dist_matrix <- distances(graph, v = V(graph), to = tank_nodes, mode = mode, 
                           algorithm = "dijkstra", weights = weights)

  apply(dist_matrix, 1, min, na.rm = TRUE)
}


# ------------- MAIN CODE -------------

# Compute centralities
centrality_df <- compute_centralities(g)
