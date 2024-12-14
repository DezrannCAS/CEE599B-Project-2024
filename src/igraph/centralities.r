rm(list = ls())

here::i_am("src/igraph/centralities.r")

library(igraph)
library(dplyr)
library(here)
library(progress)


# ------------- FUNCTIONS -------------

compute_centralities <- function(g, weights = NULL) {
  # Initialize a data frame to store results
  centralities <- data.frame(
    name = V(g)$name,
    demand = V(g)$demand
  )
  
  # Start computing metrics one by one
  print(is.null(weights))
  n <- 6

  # Degree centrality
  start_time <- Sys.time()
  centralities$degree <- degree(g)
  end_time <- Sys.time()
  cat(sprintf("1/%d - execution time: %f seconds\n", n, as.numeric(difftime(end_time, start_time, units = "secs"))))
  
  # Strength centrality
  start_time <- Sys.time()
  centralities$strength <- strength(g, weights = weights)
  end_time <- Sys.time()
  cat(sprintf("2/%d - execution time: %f seconds\n", n, as.numeric(difftime(end_time, start_time, units = "secs"))))
  
  # Closeness centrality
  start_time <- Sys.time()
  centralities$closeness <- closeness(g, weights = weights)
  end_time <- Sys.time()
  cat(sprintf("3/%d - execution time: %f seconds\n", n, as.numeric(difftime(end_time, start_time, units = "secs"))))
  
  # Betweenness centrality
  start_time <- Sys.time()
  centralities$betweenness <- betweenness(g, weights = weights)
  end_time <- Sys.time()
  cat(sprintf("4/%d - execution time: %f seconds\n", n, as.numeric(difftime(end_time, start_time, units = "secs"))))
  
  # Eccentricity
  start_time <- Sys.time()
  centralities$eccentricity <- eccentricity(g)
  end_time <- Sys.time()
  cat(sprintf("5/%d - execution time: %f seconds\n", n, as.numeric(difftime(end_time, start_time, units = "secs"))))
  
  # Tank distance
  if (!is.null(weights)) {
    start_time <- Sys.time()
    centralities$tank_distance <- all_min_distances_to_tanks(g)
    end_time <- Sys.time()
    cat(sprintf("6/%d - execution time: %f seconds\n", n, as.numeric(difftime(end_time, start_time, units = "secs"))))
  } else {
    # Efficiency-based metric
    start_time <- Sys.time()
    centralities$efficiency_based <- compute_C(g)
    end_time <- Sys.time()
    cat(sprintf("6/%d - execution time: %f seconds\n", n, as.numeric(difftime(end_time, start_time, units = "secs"))))
  }

  return(centralities)
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


compute_C <- function(g) {
  n <- vcount(g)
  
  # Compute H(v) for all vertices
  H <- harmonic_centrality(g, normalized = FALSE)
  
  # Compute E(g)
  E_g <- sum(H) / (n * (n - 1))
  
  # Initialize progress bar
  pb <- progress_bar$new(
    format = "[:bar] :percent ETA: :eta",
    total = n,
    clear = FALSE,
    width = 60
  )
  
  # Compute C(i) for each node
  C <- sapply(V(g), function(i) {
    g_minus_i <- delete_vertices(g, i)
    H_minus_i <- harmonic_centrality(g_minus_i, normalized = FALSE)
    E_g_minus_i <- sum(H_minus_i) / ((n - 1) * (n - 2))
    result <- (E_g - E_g_minus_i) / E_g
    
    # Update progress bar
    pb$tick()
    
    return(result)
  })
  
  return(C)
}


# ------------- MAIN CODE -------------

output_path <- here("output")

##### Reduced Graph #####

reduc_graph_path <- file.path(output_path, "reduced_graphv2.rds")
g_reduc <- readRDS(reduc_graph_path)
message(paste("Graph successfully loaded from:", reduc_graph_path))

print(graph_attr_names(g_reduc))
print(graph_attr(g_reduc, "demand"))

junction_vertices <- V(g_reduc)[type %in% c("junction", "aggregated")]
subgraph <- induced_subgraph(g_reduc, junction_vertices)

num_vertices <- vcount(subgraph)
num_edges <- ecount(subgraph)
cat("The subgraph has", num_vertices, "vertices and", num_edges, "edges.\n")

# Compute centralities
centrality_df2 <- compute_centralities(subgraph)

# Save results
csv_file2 <- file.path(output_path, "RG_centrality_results.csv")
write.csv(centrality_df2, csv_file2, row.names = FALSE)
message(paste("Results successfully saved at:", csv_file2))


### Original Graph #####

graph_path <- file.path(output_path, "original_graph.rds")
g <- readRDS(graph_path)
message(paste("Graph successfully loaded from:", graph_path))

# Compute centralities
centrality_df <- compute_centralities(g, weights = E(g)$length)

# Save results
csv_file <- file.path(output_path, "OG_centrality_results.csv")
write.csv(centrality_df, csv_file, row.names = FALSE)
message(paste("Results successfully saved at:", csv_file))

