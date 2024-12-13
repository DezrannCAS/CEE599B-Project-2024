rm(list = ls())

here::i_am("src/igraph/reduce.r")

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

compute_aggregated_nodes <- function(chains, g) {
  aggregated_nodes <- lapply(seq_along(chains), function(i) {
    chain <- chains[[i]]
    list(
      name = paste0("AGG-", i),
      demand = sum(V(g)[name %in% chain]$demand, na.rm = TRUE),
      type = "aggregated",
      original_nodes = chain
    )
  })
  
  return(aggregated_nodes)
}

add_aggregated_nodes <- function(g, aggregated_nodes) {
  # Prepare attributes for new vertices
  new_names <- sapply(aggregated_nodes, `[[`, "name")
  new_demands <- sapply(aggregated_nodes, `[[`, "demand")
  new_types <- sapply(aggregated_nodes, `[[`, "type")
  
  print('hey1')

  # Add vertices in bulk
  g_extended <- add_vertices(
    g,
    nv = length(aggregated_nodes),
    name = new_names,
    demand = new_demands,
    type = new_types
  )

  print('hey2')

  # Add edges from aggregated nodes to external neighbors
  for (node in aggregated_nodes) {
    chain <- node$original_nodes
    external_neighbors <- unique(unlist(lapply(chain, function(v) {
      setdiff(neighbors(g_extended, v, mode = "all")$name, chain)
    })))
    
    for (ext_node in external_neighbors) {
      g_extended <- add_edges(g_extended, c(node$name, ext_node))
    }
  }

  print('hey3')
  
  return(g_extended)
}


remove_chain_nodes <- function(g, chains) {
  chain_nodes <- unique(unlist(chains))  # Flatten the list of chains
  g_reduced <- delete_vertices(g, chain_nodes)
  return(g_reduced)
}

squashing_d1nodes <- function(g) {
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

reduce_graph <- function(g, chains) {
  # Step 1: Compute aggregated nodes
  message("    * computing aggregated nodes")
  aggregated_nodes <- compute_aggregated_nodes(chains, g)
  
  # Step 2: Add aggregated nodes
  message("    * adding aggregated nodes")
  new_g <- add_aggregated_nodes(g, aggregated_nodes)
  
  # Step 3: Remove chain nodes
  message("    * deleting chain nodes")
  new_g <- remove_chain_nodes(new_g, chains)
  
  # Step 4: Remove degree-1 nodes
  message("    * squashing degree-1 nodes")
  new_g <- squashing_d1nodes(new_g)

  # Clean up attributes
  V(g_reduced)$x <- NULL
  V(g_reduced)$y <- NULL
  V(g_reduced)$z <- NULL
  E(g_reduced)$length <- NULL
  
  return(new_g)
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

# Reduce the graph
message("Reducing the graph...")
g_reduced <- reduce_graph(g, chains)