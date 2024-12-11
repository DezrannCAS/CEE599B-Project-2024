library(igraph)
shapes()
library(here)

graph_path <- here("original_graph.rds")
g <- readRDS(graph_path)
message(paste("Graph loaded successfully from:", graph_path))


cat("\n-------- Dataset Information --------\n")

cat("Number of nodes:", vcount(g), "\n")
cat("   * Number of tanks:", sum(V(g)$type == "tank"), "\n")
cat("   * Number of junctions:", sum(V(g)$type == "junction"),
    ";", sum(V(g)$type == "junction" & V(g)$demand == 0), "with no demand", "\n")
cat("   * Number of special junctions:", sum(V(g)$type == "special"),
    ";", sum(V(g)$type == "special" & V(g)$demand == 0), "with no demand", "\n") # check also pattern to see if no demand!

cat("Number of edges:", ecount(g), "\n")
cat("   * Number of pumps:", sum(E(g)$type == "pump"), "\n")
cat("   * Number of pipes:", sum(E(g)$type == "pipe"), "\n")

cat("Graph density:", edge_density(g), "\n")

degree_info <- degree(g)
cat("Average degree:", mean(degree_info), "\n")
cat("Maximum degree:", max(degree_info), "\n")
cat("Minimum degree:", min(degree_info), "\n")

degree_assort <- assortativity_degree(g)
cat("Degree assortativity:", degree_assort, "\n")

# Eccentricity as minimum distance between a node and a water tank
# tank_ids <- V(g)[type == "tank"]$name
# eccentricities <- sapply(V(g)$name, function(node) {
#   min(distances(g, v = node, to = tank_ids, mode = "all", weights = E(g)$length))
# })
# V(g)$eccentricity <- eccentricities
# average_eccentricity <- mean(V(g)$eccentricity, na.rm = TRUE)
# cat("Average Eccentricity:", average_eccentricity, "\n")

# V2 for eccentricity:
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
# eccentricities <- all_min_distances_to_tanks(g, weights = E(g)$length)
# V(g)$eccentricity <- eccentricities
# saveRDS(g, file = graph_path)
average_eccentricity <- mean(V(g)$eccentricity, na.rm = TRUE)
cat("Average eccentricity:", average_eccentricity, "\n")

cat("-------------------------------------\n")


# ------------- Basic Plots -------------

vertex_degrees <- degree(g)
degree_freq <- table(vertex_degrees)
png("degree_distribution.png")
barplot(
  degree_freq,
  main = "Degree Distribution",
  xlab = "Degree",
  ylab = "Frequency",
  col = "lightblue",
  border = "darkblue"
)
dev.off()

# Node colors based on type
node_colors <- V(g)$type
node_colors[node_colors == "junction"] <- "darkblue"
node_colors[node_colors == "tank"] <- "green"
node_colors[node_colors == "special"] <- "orange"

# Edge colors based on type
edge_colors <- E(g)$type
edge_colors[edge_colors == "pipe"] <- "black"
edge_colors[edge_colors == "pump"] <- "red"

# Node shapes based on type
node_shapes <- V(g)$type
node_shapes[node_shapes == "junction"] <- "circle"
node_shapes[node_shapes == "tank"] <- "square"
node_shapes[node_shapes == "special"] <- "circle"

# Node sizes (we could adjust these based on other attributes like demand or capacity)
node_sizes <- ifelse(V(g)$type == "tank", 3,
                     ifelse(V(g)$type == "special", 2, 1))

# 2D layout using x and y coordinates
layout_2d <- cbind(V(g)$x, V(g)$y) * 1.5

# Plot the graph
# png("graph_plot.png", width = 800, height = 600)
# postscript("graph_plot.eps")#, width = 10, height = 8, horizontal = FALSE, onefile = FALSE, paper = "special")
pdf("graph_plot.pdf")#, width = 10, height = 8)
plot(
  g,
  layout = layout_2d,
  vertex.color = node_colors,
  vertex.shape = node_shapes,
  vertex.size = node_sizes,
  vertex.label = NA,  # remove labels for clarity
  edge.color = edge_colors,
  edge.width = ifelse(E(g)$type == "pump", 10, 1),  # thicker lines for pumps
)
dev.off()


# ---------- Checking the pumps ----------

distance_to_tank <- function(graph, edge, visited = NULL, depth = 0) {
  node_indices <- ends(graph, edge, names = FALSE) # current edge ends
  
  if (is.null(visited)) visited <- rep(FALSE, vcount(graph)) # initialize if no visited yet
  
  visited[node_indices] <- TRUE
  
  if (any(V(graph)$type[node_indices] == "tank")) {
    return(depth)  # found a tank
  }
  
  neighbor_edges <- unique(unlist(lapply(node_indices, function(node_idx) {
    incident(graph, V(graph)[node_idx], mode = "all")
  })))
  
  # Exclude edges leading to already visited nodes
  neighbor_edges <- neighbor_edges[!apply(ends(graph, neighbor_edges, names = FALSE), 1, function(x) all(visited[x]))]
  
  if (length(neighbor_edges) == 0) {
    return(Inf)  # tank not reachable
  }
  
  # Recursion
  return(min(sapply(neighbor_edges, function(next_edge) {
    distance_to_tank(graph, next_edge, visited, depth + 1)
  })))
}

# pump_edges <- E(g)[E(g)$type == "pump"]
# distances <- sapply(pump_edges, function(e) {
#   distance_to_tank(g, e)
# })
# cat("Distances of pump edges to nearest tank:\n")
# print(data.frame(edge_id = E(g)$id[pump_edges], distance_to_tank = distances))
