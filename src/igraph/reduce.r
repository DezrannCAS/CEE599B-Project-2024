library(igraph)
library(dplyr)
library(here)
# library(copy)


# ----------- FUNCTIONS -----------

is_pipe_edge <- function(g, v1, v2) {
  edge_id <- get_edge_ids(g, c(v1, v2))
  if (edge_id == 0) return(FALSE)
  
  edge_type <- edge_attr(g, "type", edge_id)
  return(!is.null(edge_type) && edge_type == "pipe")
}

reduce_graph <- function(g, chains) {
  # Create a new graph
  # g_reduced <- deepcopy(g)
  g_reduced <- unserialize(serialize(g, NULL))

  for (i in seq_along(chains)) {
    chain <- chains[[i]]

    # Skip chains with only one node
    if (length(chain) <= 1) next

    # Ensure all nodes in the chain exist in the graph
    valid_chain <- chain[chain %in% V(g_reduced)$name]
    if (length(valid_chain) != length(chain)) {
      warning(paste("Chain", i, "contains unvalid nodes. Skipping."))
      next
    }

    # Create a new node for the chain
    new_node_name <- paste0("AGG-", i)
    g_reduced <- add_vertices(g_reduced, 1, name = new_node_name)

    # Set the demand for the new node
    V(g_reduced)[new_node_name]$demand <- sum(V(g)[chain]$demand, na.rm = TRUE)
    V(g_reduced)[new_node_name]$type <- "aggregated"

    # Find all edges connecting the chain to the rest of the graph
    # chain_edges <- E(g_reduced)[.from(chain) | .to(chain)]
    # all_vertices <- ends(g_reduced, chain_edges)
    # external_vertices <- setdiff(unique(c(all_vertices[,1], all_vertices[,2])), chain)
    # Add edges from the new node to external vertices
    # for (ext_v in external_vertices) {
    #   g_reduced <- add_edges(g_reduced, c(new_node_name, ext_v))
    # }

    # Get first and last nodes of the chain
    first_node <- chain[1]
    last_node <- chain[length(chain)]

    first_neighbors <- neighbors(g_reduced, first_node)
    last_neighbors <- neighbors(g_reduced, last_node)
    
    # Filter external nodes that are not in the current chain
    external_nodes <- c()
    for (neighbor in union(first_neighbors, last_neighbors)) {
      if (!(neighbor %in% chain)) {
        external_nodes <- c(external_nodes, neighbor)
      }
    }
    external_nodes <- unique(external_nodes)

    # Add edges
    for (ext_node in external_nodes) {
      g_reduced <- add_edges(g_reduced, c(new_node_name, ext_node))
    }

    # Remove the original chain nodes
    for (node in chain) {
      print(node)
      g_reduced <- delete_vertices(g_reduced, node)
    }
    # igraph automatically removes edge when using delete_vertices()
  }
  
  # Remove x, y, z, and length attributes
  V(g_reduced)$x <- NULL
  V(g_reduced)$y <- NULL
  V(g_reduced)$z <- NULL
  E(g_reduced)$length <- NULL

  return(g_reduced)
}

reduce_d1_nodes <- function(g) {
  degree_one_nodes <- V(g)[degree(g) == 1]
  
  # Find last AGG-name
  vertex_names <- V(g)$name
  agg_names <- vertex_names[grep("AGG-", vertex_names)]
  agg_numbers <- as.numeric(gsub("AGG-", "", agg_names))
  last_aggid <- max(agg_numbers, na.rm = TRUE)

  for (node in degree_one_nodes) {
    if (V(g)[node]$type %in% c("tank", "special")) next

    # Find the unique neighbor
    neighbor <- neighbors(g, node)[1]
    
    if (V(g)[neighbor]$type %in% c("tank", "special") || !is_pipe_edge(g, node, neighbor)) next

    # Aggregate the node with its neighbor
    neighbor_name <- V(graph)[neighbor]$name
    if (grepl("^AGG-\\d+$", neighbor_name)) {
      new_name <- neighbor_name
    } else {
      new_name <- paste0("AGG-", last_aggid)
      last_aggid <- last_aggid + 1
      V(g)[new_name]$type <- "aggregated"
    }
    V(g)[neighbor]$name <- new_name
    V(g)[neighbor]$demand <- sum(V(g)[c(node, neighbor)]$demand, na.rm = TRUE)

    # Remove the degree-1 node
    g <- delete_vertices(g, node)
  }

  invisible(g)
}

sanity_check <- function(g, chains) {
  # Check if all vertices in chains are present in the graph
  for (chain in chains) {
    if (!all(chain %in% V(g)$name)) {
      stop(paste("Invalid vertex names found in chain:", paste(chain, collapse = ", ")))
    }
  }
  message("Vertices in `chains` are all present in the graph")

  # Combine all vertices from chains
  all_vertices <- unlist(chains)
  
  # Check for duplicates
  duplicates <- all_vertices[duplicated(all_vertices)]
  if (length(duplicates) == 0) {
    message("All vertices are unique across chains.")
  } else {
    stop("Duplicate vertices found:", paste(duplicates, collapse = ", "))
  }

  # Get vertex IDs for the combined vertices
  vertex_ids <- V(g)$name %in% all_vertices
  id_indices <- which(vertex_ids)

  # Calculate degrees using vertex IDs
  degrees <- degree(g, v = id_indices)
  
  # Check if all degrees are equal to 2
  if (all(degrees == 2)) {
    message("All vertices in chains have degree two.")
  } else {
    non_degree_two_vertices <- V(g)$name[which(degrees != 2)]
    message("The following vertices do not have degree two:")
    print(non_degree_two_vertices)
    stop()
  }
}



# ----------- MAIN CODE -----------

output_path <- here("output")
fig_path <- file.path(output_path, "fig")
data_path <- here("data", "csv")

graph_path <- file.path(output_path, "original_graph.rds")
g <- readRDS(graph_path)
message(paste("Graph successfully loaded from:", graph_path))

file_path <- file.path(output_path, "chains.csv")
chains_df <- read.csv(file_path)
message(paste("Chains successfully loaded from:", file_path))

# Convert chains dataframe to list of vectors
chains <- split(chains_df$vertex_name, chains_df$chain_id)
sanity_check(g, chains)

# Reduce the graph
message("Reducing the graph...")
g_reduced <- reduce_graph(g, chains)

message("Squashing degree-1 nodes...")
g_reduced <- reduce_d1_nodes(g_reduced)

# Print some statistics
message("Original graph:")
message(paste("  Nodes:", vcount(g)))
message(paste("  Edges:", ecount(g)))
message("Reduced graph:")
message(paste("  Nodes:", vcount(g_reduced)))
message(paste("  Edges:", ecount(g_reduced)))


# Save the reduced graph
reduced_graph_path <- file.path(output_path, "reduced_graph.rds")
saveRDS(g_reduced, reduced_graph_path)
message(paste("Reduced graph saved to:", reduced_graph_path))