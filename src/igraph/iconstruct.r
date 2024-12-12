rm(list = ls())

here::i_am("src/igraph/iconstruct.r")

library(igraph)
library(tidyverse)
library(here)

# Define paths
output_path <- here("output")
data_path <- here("data", "csv")

# Load data
junctions <- read.csv(file.path(data_path, "junctions.csv"))
      # properties: "id","x","y","z","demand"
special_junctions <- read.csv(file.path(data_path, "special_junctions.csv"))
      # properties: "id","x","y","z","demand","pattern"
tanks <- read.csv(file.path(data_path, "tanks.csv"))
      # properties: "id","x","y","z","init","capacity"
pipes <- read.csv(file.path(data_path, "pipes.csv"))
      # properties: "id","start","end","length"
pumps <- read.csv(file.path(data_path, "pumps.csv"))
      # properties: "id","start","end","curve"
curves <- read.csv(file.path(data_path, "curves.csv"))
      # properties: "key","x","y"
patterns <- read.csv(file.path(data_path, "patterns.csv"))
      # properties: "key","value","index"

# Combine nodes: Junctions and Tanks
# First column should be "name" then other are considered attributes
nodes <- bind_rows(
  junctions %>%
    mutate(type = "junction", id = as.character(id)) %>%
    select(name = id, x, y, z, demand, type),
  special_junctions %>%
    mutate(type = "special", id = as.character(id), pattern = as.character(pattern)) %>%
    select(name = id, x, y, z, demand, pattern, type),
  tanks %>%
    mutate(type = "tank", id = as.character(id)) %>%
    select(name = id, x, y, z, init, capacity, type)
)
print(head(nodes, 10))

# Verify that we do not have twice the same name
duplicate_names <- nodes %>% 
  count(name) %>% 
  filter(n > 1)
duplicate_nodes <- nodes %>% 
  filter(name %in% duplicate_names)

if (nrow(duplicate_names) > 0) {
  cat("Duplicates found:\n")
  print(duplicate_nodes)
  stop()
} else {
  cat("No duplicate names found.\n")
}

# Combine edges: Pipes and Pumps
# Edge list in the first two columns (`from` and `to`)
edges <- bind_rows(
  pipes %>%
    mutate(type = "pipe", id = as.character(id), start = as.character(start), end = as.character(end)) %>%
    select(from = start, to = end, id, length, type),
  pumps %>%
    mutate(type = "pump", id = as.character(id), start = as.character(start), end = as.character(end), length = NA) %>%
    select(from = start, to = end, id, length, curve, type)
)
print(head(edges, 10))
pump_edges <- edges %>% filter(type == "pump")
print(pump_edges)

#str(nodes)
#summary(nodes)
#str(edges)
#summary(edges)

# Verify that all start and end nodes in edges exist in nodes
all_nodes <- unique(nodes$id)
missing_nodes <- setdiff(unique(c(edges$start, edges$end)), all_nodes)
if (length(missing_nodes) > 0) {
  stop(length(missing_nodes), " nodes in edges are missing in the nodes data: ", paste(missing_nodes, collapse = ", "))
}

# Create the graph from edge and node data
g <- graph_from_data_frame(
  d = edges, vertices = nodes, directed = FALSE
)

# Add attributes
V(g)$x <- nodes$x
V(g)$y <- nodes$y
V(g)$z <- nodes$z
V(g)$type <- nodes$type
E(g)$type <- edges$type
E(g)$length <- edges$length

# Add type-specific attributes
V(g)$demand[V(g)$type == "junction"] <- nodes$demand[nodes$type == "junction"]
V(g)$init[V(g)$type == "tank"] <- nodes$init[nodes$type == "tank"]
V(g)$pattern[V(g)$type == "special"] <- nodes$pattern[nodes$type == "special"]
V(g)$capacity[V(g)$type == "tank"] <- nodes$capacity[nodes$type == "tank"]
E(g)$curve[E(g)$type == "pump"] <- edges$curve[edges$type == "pump"]

# Compute distances for pumps based on coordinates of start and end nodes
for (e in E(g)[E(g)$type == "pump"]) {
  # Retrieve the start and end vertices
  start_node <- ends(g, e)[1]
  end_node <- ends(g, e)[2]
  
  # Retrieve the coordinates of start and end nodes
  x1 <- V(g)[start_node]$x
  y1 <- V(g)[start_node]$y
  z1 <- V(g)[start_node]$z
  x2 <- V(g)[end_node]$x
  y2 <- V(g)[end_node]$y
  z2 <- V(g)[end_node]$z

  # Check for missing coordinates
  if (is.na(x1) | is.na(y1) | is.na(z1) | is.na(x2) | is.na(y2) | is.na(z2)) {
    warning(paste("NA distance for pump edge", e))
    distance <- NA
    next
  } else {
    # Compute Euclidean distance
    distance <- sqrt((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2)
  }

  # Update the edge attribute in the graph
  E(g)[e]$length <- distance
}

# Check for edges with NA as length
na_length_edges <- E(g)[is.na(E(g)$length)]
if (length(na_length_edges) > 0) {
  cat("Edges with NA length:\n")
  print(data.frame(
    ID = E(g)$id[na_length_edges],
    Type = E(g)$type[na_length_edges]
  ))
} else {
  cat("No edges with NA length found.\n")
}

# Verify that all nodes are connected to at least one edge
isolated_nodes <- V(g)[degree(g) == 0]
if (length(isolated_nodes) > 0) {  
  # Remove isolated nodes from the graph
  g <- delete_vertices(g, isolated_nodes)
  
  warning_msg <- paste("The following isolated nodes were removed from the graph:",
                       paste(V(g)[isolated_nodes]$name, collapse = ", "))
  warning(warning_msg)
}

# Save graph
graph_path <- file.path(output_path, "original_graph.rds")
saveRDS(g, file = graph_path)
message(paste("Graph saved successfully at:", graph_path))
