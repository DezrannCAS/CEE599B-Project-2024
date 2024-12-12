rm(list = ls())

here::i_am("src/igraph/ireduce.r")

library(igraph)
library(here)

# Define paths
output_path <- here("output")
fig_path <- file.path(output_path, "fig")
data_path <- here("data", "csv")

# The simplified graph contains tanks, pumps and special junctions as before
# but aggregates degree-2 chains in a single node with total demand as property
# and ID of the form "S..." with a single integer after the S
# we also get rid of the "x","y","z" and "length" for all

identify_chains <- function(graph) {
  chains <- list()
  visited <- rep(FALSE, vcount(graph))  # Track visited nodes
  
  for (v in V(graph)) {
    # Skip already visited nodes or nodes with degree != 2
    if (visited[v] || degree(graph, v) != 2) next

    chain <- c(v)
    current <- v

    # Traverse forward
    while (TRUE) {
      neighbors <- neighbors(graph, current, mode = "all")$name
      # Exclude already visited nodes and chain members
      next_node <- neighbors[!neighbors %in% c(chain, names(visited[visited]))]
      if (length(next_node) == 0 || degree(graph, next_node) != 2) break
      chain <- c(chain, next_node)
      visited[next_node] <- TRUE
      current <- next_node
    }
    
    # Traverse backward
    current <- v
    while (TRUE) {
      neighbors <- neighbors(graph, current, mode = "all")$name
      prev_node <- neighbors[!neighbors %in% c(chain, names(visited[visited]))]
      if (length(prev_node) == 0 || degree(graph, prev_node) != 2) break
      chain <- c(prev_node, chain)
      visited[prev_node] <- TRUE
      current <- prev_node
    }
    
    # Add chain to the list if it's valid
    if (length(chain) > 2) {
      chains <- append(chains, list(chain))
    }
  }
  
  return(chains)
}

simplify_graph <- function(graph, chains) {
  new_graph <- graph  # Copy the original graph

  # Ensure vertex names are set
  if (is.null(V(new_graph)$name)) {
    V(new_graph)$name <- as.character(V(new_graph))
  }

  for (i in seq_along(chains)) {
    chain <- chains[[i]]
    chain_name <- paste0("C", i)

    cat("Simplifying chain", i, "/", length(chains), "of length", length(chain), ":\n")
    print(chain)

    # Create the aggregated node
    demand_sum <- sum(V(new_graph)$demand[V(new_graph)$name %in% chain], na.rm = TRUE)  # Aggregate demand
    new_graph <- add_vertices(new_graph, 1, name = chain_name, demand = demand_sum)

    # Find endpoints of the chain
    chain_indices <- match(chain, V(new_graph)$name)  # Convert chain to vertex indices
    if (any(is.na(chain_indices))) {
      stop(paste("Invalid chain nodes detected in chain", i, ":", paste(chain[is.na(chain_indices)], collapse = ", ")))
    }
    chain_endpoints <- chain_indices[c(1, length(chain_indices))]  # Get endpoint indices

    # Get neighbors for the endpoints
    endpoint_neighbors <- unique(unlist(neighborhood(new_graph, 1, nodes = chain_endpoints)))
    if (is.null(endpoint_neighbors)) {
      warning(paste("No neighbors found for endpoints of chain", i))
      next
    }

    endpoints <- endpoint_neighbors[!V(new_graph)[endpoint_neighbors]$name %in% chain]  # Exclude chain nodes

    # Add edges from the aggregated node to the endpoints
    for (endpoint in endpoints) {
      if (endpoint %in% V(new_graph)) {  # Ensure the endpoint exists
        endpoint_name <- V(new_graph)[endpoint]$name
        new_graph <- add_edges(new_graph, c(chain_name, endpoint_name))
      } else {
        warning(paste("Endpoint", endpoint, "not found in the graph. Skipping."))
      }
    }

    # Remove chain nodes
    for (node_name in chain) {
      if (node_name %in% V(new_graph)$name) {
        new_graph <- delete_vertices(new_graph, node_name)
      } else if (!node_name %in% V(graph)$name) {
        stop(paste("Node", node_name, "not found in the graph."))
      }
    }
  }

  # Remove unused attributes
  vertex_attr(new_graph)$x <- NULL
  vertex_attr(new_graph)$y <- NULL
  vertex_attr(new_graph)$z <- NULL
  edge_attr(new_graph)$length <- NULL
  
  return(new_graph)
}


graph_path <- file.path(output_path, "original_graph.rds")
g <- readRDS(graph_path)
message(paste("Graph successfully loaded from:", graph_path))

summary(g)
# print(vertex_attr(g, name="attribute_name")[1:10])
print(V(g)[1:10])


# message("Finding degree-2 chains...")
# chains <- identify_chains(g)

# chains_df <- data.frame(
#   chain_id = rep(seq_along(chains), sapply(chains, length)),
#   node = unlist(chains),
#   position = unlist(lapply(chains, seq_along))
# )
chains_path <- file.path(output_path, "d2chains.csv")
# write.csv(chains_df, file = chains_path, row.names = FALSE)

chains_df <- read.csv(chains_path, stringsAsFactors = FALSE)
message(paste("Graph successfully loaded from:", graph_path))

# Convert the dataframe back into a list of chains
chains_list <- split(chains_df$node, chains_df$chain_id)
chains <- lapply(chains_list, as.character)  # ensure node names are characters

message("Plotting distribution...")
chain_lengths <- sapply(chains, length)
length_freq <- table(chain_lengths)
png(file.path(fig_path, "chainlen_distribution.png"))
barplot(length_freq,
        main = "Distribution of Chain Lengths",
        xlab = "Chain Length",
        ylab = "Frequency",
        col = "lightblue",
        border = "darkblue")
dev.off()


message("Simplifying the graph...")
new_g <- simplify_graph(g, chains)

new_graph_path <- file.path(output_path, "simplified_graph.rds")
saveRDS(g, file = new_graph_path)
message(paste("Graph saved successfully at:", new_graph_path))