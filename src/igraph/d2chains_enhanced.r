library(igraph)
library(ggplot2)
library(here)
library(jsonlite)

# ----------- FUNCTIONS -----------


is_pipe_edge <- function(g, v1, v2) {
  edge_id <- get_edge_ids(g, c(v1, v2))
  if (edge_id == 0) return(FALSE)

  edge_type <- edge_attr(g, "type", edge_id)
  return(!is.null(edge_type) && edge_type == "pipe")
}

# Function to traverse a chain starting from a degree-2 vertex
traverse <- function(g, start_vertex) {
  chain <- c(start_vertex)
  visited <- c()
  external_vertices <- c()

  # Helper function to extend the chain in a given direction
  extend_chain <- function(vertex, direction) {
    repeat {
      neighbors <- neighbors(g, vertex) %>% as_ids()  # get neighbors as names
      neighbors <- setdiff(neighbors, visited)  # exclude visited vertices

      visited <<- union(visited, vertex)  # mark current vertex as visited

      if (length(neighbors) == 2) {
        next_vertex <- if (direction == "up") neighbors[1] else neighbors[2] # choose based on direction
      } else if (length(neighbors) == 1) {
        next_vertex <- neighbors[1]
      } else {
        # Record the external vertex if no valid continuation
        external_vertices <<- union(external_vertices, neighbors)
        break
      }

      # Ensure the next vertex is degree 2 (and normal junction), else stop
      if (degree(g, next_vertex) != 2) {
        external_vertices <<- union(external_vertices, next_vertex)
        break
      }
      # Also stop if next vertex is special (and mark it with "**")
      if (V(g)[next_vertex]$type != "junction") {
        message(paste("We have a special node or edge as external:", next_vertex))
        external_vertices <<- union(external_vertices, paste0(next_vertex, "**"))
        break
      }
      if (!is_pipe_edge(g, vertex, next_vertex)) {
        message(paste("We have an external node linked by pump:", next_vertex))
        external_vertices <<- union(external_vertices, paste0(next_vertex, "++"))
        break
      }

      chain <<- c(chain, next_vertex)
      vertex <- next_vertex  # continue extending
    }
  }

  # Extend the chain in both directions
  extend_chain(start_vertex, direction = "up")
  chain <- rev(chain)  # reverse to extend in the other direction
  extend_chain(start_vertex, direction = "down")
  
  return(list(chain = unique(chain), external_vertices = unique(external_vertices))) # a small possiblity of looping chain
}

identify_chains <- function(g) {
  chain_details <- list()
  visited <- c()

  # Get vertex names of degree-2 nodes
  degree_2_nodes <- V(g)[degree(g) == 2]$name

  for (v in degree_2_nodes) {
    if (v %in% visited) next  # skip if already checked
    if (V(g)[v]$type != "junction") next  # skip if not a normal junction

    # Find the chain and external vertices starting from this vertex
    result <- traverse(g, v)
    chain <- result$chain
    external_vertices <- result$external_vertices

    # Add the chain details to the results
    chain_details <- append(chain_details, list(list(
      chain_index = length(chain_details) + 1,
      chain = chain,
      external_vertices = external_vertices
    )))

    # Mark vertices as visited
    visited <- union(visited, chain)
  }

  return(chain_details)
}

save_chains_to_json <- function(chains, output_path) {
  json_data <- toJSON(chains, pretty = TRUE)
  write(json_data, file = output_path)
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
chain_details <- identify_chains(g)

file_path <- file.path(output_path, "chains_extra.json")
save_chains_to_json(chain_details, file_path)
message(paste("Chains successfully saved at:", file_path))
