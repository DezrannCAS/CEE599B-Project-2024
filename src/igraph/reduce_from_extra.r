rm(list = ls())

here::i_am("src/igraph/reduce.r")

library(igraph)
library(dplyr)
library(here)
library(jsonlite)


# ----------- FUNCTIONS -----------

# Compute aggregated node attributes based on chain details
compute_aggregated_nodes <- function(graph, chain_details) {
  aggregated_nodes <- list()
  
  for (i in seq_along(chain_details)) {
    chain <- chain_details[[i]]$chain
    chain_demands <- sum(V(graph)[name %in% chain]$demand, na.rm = TRUE)
    
    aggregated_nodes <- append(aggregated_nodes, list(list(
      name = paste0("AGG-", i),
      demand = chain_demands,
      type = "aggregated",
      chain = chain
    )))
  }
  
  return(aggregated_nodes)
}

# Add aggregated nodes and create edges
add_aggregated_nodes <- function(graph, aggregated_nodes, chain_details) {
  for (i in seq_along(aggregated_nodes)) {
    agg_node <- aggregated_nodes[[i]]
    external_vertices <- chain_details[[i]]$external_vertices

    # Add the aggregated node
    graph <- add_vertices(graph, nv = 1, name = agg_node$name, type = agg_node$type, demand = agg_node$demand)

    # Add edges between the aggregated node and external vertices
    for (ext_vertex in external_vertices) {
      if (degree(graph, V(graph)[name == ext_vertex]) == 1 && !grepl("\\*\\*$", ext_vertex) && !grepl("\\+\\+$", ext_vertex)) {
        # If external vertex has degree 1 and is not special, aggregate it
        ext_demand <- V(graph)[name == ext_vertex]$demand
        V(graph)[name == agg_node$name]$demand <- V(graph)[name == agg_node$name]$demand + ext_demand
        graph <- delete_vertices(graph, V(graph)[name == ext_vertex])
      } else {
        if (endsWith(ext_vertex, "**")) {
          ext_vertex <- sub("\\*\\*$", "", ext_vertex)
          graph <- add_edges(graph, c(agg_node$name, ext_vertex), type = "pseudopipe")
          message(paste("We have a special node or edge as external:", ext_vertex))
        } else if (endsWith(ext_vertex, "++")) {
          ext_vertex <- sub("\\+\\+$", "", ext_vertex)
          message(paste("We have a pump to the external:", ext_vertex))
          graph <- add_edges(graph, c(agg_node$name, ext_vertex), type = "pump")
        } else {
          graph <- add_edges(graph, c(agg_node$name, ext_vertex), type = "pseudopipe")
        }
      }
    }
  }
  
  return(graph)
}

# Remove chain nodes from the graph
remove_chain_nodes <- function(graph, chains) {
  all_chain_nodes <- unlist(lapply(chains, function(x) x$chain))
  graph <- delete_vertices(graph, V(graph)[name %in% all_chain_nodes])
  return(graph)
}

# Reduce the graph by aggregating chains
reduce_graph <- function(graph, chain_details) {
  # Step 1: Compute aggregated nodes
  message("  * Computing aggregates")
  aggregated_nodes <- compute_aggregated_nodes(graph, chain_details)
  message(paste("    - Number of aggregated nodes computed:", length(aggregated_nodes)))
  
  # Step 2: Add aggregated nodes and connect to external vertices
  message("  * Adding aggregated nodes")
  graph <- add_aggregated_nodes(graph, aggregated_nodes, chain_details)
  agg_node_count <- sum(grepl("^AGG", V(graph)$name))
  message(paste("    - Number of nodes with name 'AGG-...':", agg_node_count))
  
  # Step 3: Remove original chain nodes
  message("  * Deleting chain nodes")
  initial_node_count <- vcount(graph)
  graph <- remove_chain_nodes(graph, chain_details)
  final_node_count <- vcount(graph)
  message(paste("    - Difference in number of nodes after removing chains:",
                initial_node_count - final_node_count))
  
  # Clean up attributes
  graph <- delete_vertex_attr(graph, "x")
  graph <- delete_vertex_attr(graph, "y")
  graph <- delete_vertex_attr(graph, "z")
  graph <- delete_edge_attr(graph, "length")

  return(graph)
}


# ----------- MAIN CODE -----------

output_path <- here("output")
fig_path <- file.path(output_path, "fig")
data_path <- here("data", "csv")

graph_path <- file.path(output_path, "original_graph.rds")
g <- readRDS(graph_path)
message(paste("Graph successfully loaded from:", graph_path))

json_file <- file.path(output_path, "chains_extra.json")
chain_details <- fromJSON(json_file, simplifyVector = FALSE)
message(paste("Chains successfully loaded from:", json_file))
message(paste("    - Number of chains:", length(chain_details)))
message(paste("    - Number of nodes in the chains:", length(chain_details)))

# Reduce the graph
message("Reducing the graph...")
g_reduced <- reduce_graph(g, chain_details)

# Save the reduced graph
reduced_graph_path <- file.path(output_path, "reduced_graphv2.rds")
saveRDS(g_reduced, reduced_graph_path)
message(paste("Reduced graph saved to:", reduced_graph_path))