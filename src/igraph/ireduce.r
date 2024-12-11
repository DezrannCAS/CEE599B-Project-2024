library(igraph)

# The simplified graph contains tanks, pumps and special junctions as before
# but aggregates degree-2 chains in a single node with total demand as property
# and ID of the form "S..." with a single integer after the S
# we also get rid of the "x","y","z" and "length" for all

identify_chains <- function(graph) {
  chains <- list()
  visited <- rep(FALSE, vcount(graph)) # keep track of visited nodes

  for (v in V(graph)) {
    if (!visited[v] && degree(graph, v) == 2) {
      chain <- c(v)
      current <- v

      # Traverse forward
      while (degree(graph, current) == 2) {
        neighbors <- neighbors(graph, current, mode = "all")
        next_node <- neighbors[!neighbors %in% chain]
        if (length(next_node) == 0) break
        chain <- c(chain, next_node)
        visited[current] <- TRUE
        current <- next_node
      }

      # Traverse backward (in case the chain can grow in the other direction)
      current <- v
      while (degree(graph, current) == 2) {
        neighbors <- neighbors(graph, current, mode = "all")
        prev_node <- neighbors[!neighbors %in% chain]
        if (length(prev_node) == 0) break
        chain <- c(prev_node, chain)
        visited[current] <- TRUE
        current <- prev_node
      }

      # Add the chain to the list if it contains more than one node
      if (length(chain) > 2) {
        chains <- append(chains, list(chain))
      }
    }
  }

  return(chains)
}

simplify_graph <- function(graph, chains) {
  new_graph <- graph

  for (chain in chains) {
    # Aggregate chain into a single node
    chain_name <- paste0("S", sample(1:1e5, 1)) # Unique node name
    demand_sum <- sum(V(graph)$demand[chain])   # Sum up the demands in the chain

    # Add the new node
    new_graph <- add_vertices(new_graph, 1, id = chain_name, demand = demand_sum)

    # Connect the new node to the endpoints of the chain
    endpoints <- neighbors(graph, chain[c(1, length(chain))], mode = "all")
    endpoints <- unique(endpoints[!endpoints %in% chain])
    for (endpoint in endpoints) {
      new_graph <- add_edges(new_graph, c(chain_name, endpoint))
    }

    # Remove the old chain
    new_graph <- delete_vertices(new_graph, chain)
  }

  # Remove unnecessary attributes
  vertex_attr(new_graph)$x <- NULL
  vertex_attr(new_graph)$y <- NULL
  vertex_attr(new_graph)$z <- NULL
  edge_attr(new_graph)$length <- NULL

  return(new_graph)
}
