rm(list = ls())

here::i_am("src/igraph/ireduce.r")

library(igraph)
library(here)
library(sets)

# -------- FUNCTIONS --------

# visited is a vector of vertices from igraph, dir is 0 or 1, v is a vertex from igraph and graph a igraph
traverse <- function(graph, v, dir, visited) {
  chain <- c()
  current <- v
  repeat {
    chain <- c(chain, current)
    visited <- set_union(visited, current)
    neighbors <- neighbors(graph, current)
    next_node <- neighbors[!(neighbors %in% visited)][dir]
    if (length(next_node) == 0 || degree(graph, next_node) != 2 || V(graph)$type[next_node] %in% c("tank", "pump", "special")) {
      break
    }
    current <- next_node
  }
  return(list(chain = chain, visited = visited))
}

stack_vectors <- function(vec1, vec2) {
  common_start <- vec1[1]
  if (vec1[1] != vec2[1]) {
    stop("Error: Vectors do not have a common starting point.")
  }
  result <- c(rev(vec1[-1]), common_start, vec2[-1])
  return(result)
}

find_degree_2_chains <- function(graph) {
  chains <- list()
  visited <- set()
  
  for (v in V(graph)[degree(graph) == 2]) {
    if (!(v %in% visited) && !(V(graph)$type[v] %in% c("tank", "pump", "special")))
      # Traversal to the next (resp. previous) unvisited neighbor
      result1 <- traverse(graph, v, 1, visited)
      result0 <- traverse(graph, v, 0, visited)

      # Update
      chain <- stack_vectors(result0$chain, result1$chain)
      chains <- c(chains, chain)
      visited <- set_union(visited, result1$visited, result0$visited)
    }
  
  return(chains)
}

# also simplify degree 1
simplify_graph <- function(g, chains) {
  new_graph <- graph
  
  for (chain in chains) {
    # Aggregate the chain
    new_id <- paste0("S", length(V(new_graph)) + 1)  # Generate a new ID
    total_demand <- sum(V(new_graph)$demand[chain], na.rm = TRUE)
    
    # Identify edges connecting the chain to the rest of the graph
    incoming_edges <- incident(new_graph, chain[1], mode = "in")
    outgoing_edges <- incident(new_graph, chain[length(chain)], mode = "out")
    
    # Create new node
    new_graph <- add_vertices(new_graph, 1, name = new_id, type = "simplified", demand = total_demand)
    
    # Connect new node to incoming and outgoing edges
    for (e in incoming_edges) {
      new_graph <- add_edges(new_graph, c(ends(new_graph, e)[1], new_id))
    }
    for (e in outgoing_edges) {
      new_graph <- add_edges(new_graph, c(new_id, ends(new_graph, e)[2]))
    }
    
    # Remove chain nodes and edges
    new_graph <- delete_vertices(new_graph, chain)
  }
  
  # Remove x, y, z, and length attributes
  V(new_graph)$x <- NULL
  V(new_graph)$y <- NULL
  V(new_graph)$z <- NULL
  E(new_graph)$length <- NULL
  
  new_graph
}

# -------- MAIN CODE -------- 

# Define paths
output_path <- here("output")
fig_path <- file.path(output_path, "fig")
data_path <- here("data", "csv")

graph_path <- file.path(output_path, "original_graph.rds")
g <- readRDS(graph_path)
message(paste("Graph successfully loaded from:", graph_path))


message("Finding chains...")
chains <- find_degree_2_chains(g)

chain_lengths <- sapply(chains, length)
length_freq <- table(chain_lengths)
png(file.path(fig_path, "chainlen_distributionv2.png"))
barplot(length_freq,
        main = "Distribution of Chain Lengths",
        xlab = "Chain Length",
        ylab = "Frequency",
        col = "lightblue",
        border = "darkblue")
dev.off()


message("Simplifying the graph...")
new_g <- simplify_graph(g, chains)

# Save the simplified graph
saveRDS(new_g, file = file.path(output_path, "simplified_graph.rds"))
message(paste("Simplified graph saved at:", simplified_graph_path))