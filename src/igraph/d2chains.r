library(igraph)
library(ggplot2)
library(here)

# ----------- FUNCTIONS -----------

# Function to traverse a chain starting from a degree-2 vertex
traverse <- function(g, start_vertex) {
  chain <- c(start_vertex)  # Initialize the chain with the starting vertex
  visited <- c()  # To track visited vertices
  
  # Helper function to extend the chain in a given direction
  extend_chain <- function(vertex, direction) {
    repeat {
      neighbors <- neighbors(g, vertex) %>% as_ids()  # Get neighbors as names
      neighbors <- setdiff(neighbors, visited)  # Exclude visited vertices
      
      visited <<- union(visited, vertex)  # Mark current vertex as visited
      
      if (length(neighbors) == 2) {
        # Choose the neighbor based on direction
        next_vertex <- if (direction == "up") neighbors[1] else neighbors[2]
      } else if (length(neighbors) == 1) {
        # If only one neighbor remains, continue extending
        next_vertex <- neighbors[1]
      } else {
        break  # Stop if no valid extension is possible
      }
      
      # Ensure the next vertex is degree 2, else stop
      if (degree(g, next_vertex) != 2) break
      
      chain <<- c(chain, next_vertex)
      vertex <- next_vertex  # Continue extending
    }
  }
  
  # Extend the chain in both directions
  extend_chain(start_vertex, "up")
  chain <- rev(chain)  # Reverse to extend in the other direction
  extend_chain(chain[1], "down")
  
  return(unique(chain))
}

# Function to identify all chains of degree-2 vertices
identify_chains <- function(g) {
  chains <- list()  # To store all identified chains
  visited <- c()  # To track all checked vertices
  
  # Get vertex names of degree-2 nodes
  degree_2_nodes <- V(g)[degree(g) == 2]$name
  
  for (v in degree_2_nodes) {
    if (v %in% visited) {
      next  # Skip if the vertex has already been checked
    }
    
    # Find the chain starting from this vertex
    chain <- traverse(g, v)
    
    # Add the chain to the results and mark vertices as visited
    chains <- append(chains, list(chain))
    visited <- union(visited, chain)
  }
  
  return(chains)
}


# ----------- MAIN CODE -----------

output_path <- here("output")
fig_path <- file.path(output_path, "fig")
data_path <- here("data", "csv")

graph_path <- file.path(output_path, "original_graph.rds")
g <- readRDS(graph_path)
message(paste("Graph successfully loaded from:", graph_path))

# Validate the graph
if (any(is.na(V(g)$name))) {
  stop("The graph contains vertices with NA names.")
}
if (anyDuplicated(V(g)$name)) {
  stop("The graph contains vertices with duplicate names.")
}

# Find degree-2 chains
message("Identifying chains...")
chains <- identify_chains(g)

# Save the chains
chains_df <- data.frame(
  chain_id = rep(seq_along(chains), lengths(chains)),
  vertex_name = unlist(chains)
)
file_path <- file.path(output_path, "chains.csv")
write.csv(chains_df, file_path, row.names = FALSE)
message(paste("Chains successfully saved at:", file_path))

# Plot distribution of chain lengths
chain_lengths <- sapply(chains, length)
chain_length_df <- data.frame(ChainLength = chain_lengths)

message("Plotting distribution...")
plot_path <- file.path(fig_path, "chainlen_distribution.png")
png(plot_path)
ggplot(chain_length_df, aes(x = ChainLength)) +
  geom_histogram(binwidth = 1, fill = "blue", color = "black", alpha = 0.7) +
  labs(
    x = "Chain Length",
    y = "Frequency"
  ) +
  theme_minimal()
dev.off()
