rm(list = ls())

here::i_am("src/igraph/data_profile_func.r")

library(igraph)
shapes()
library(here)

# ----------- FUNCTIONS -----------

print_dataset_info <- function(g) {
  cat("\n-------- Dataset Information --------\n")
  
  cat("Number of nodes:", vcount(g), "\n")
  cat("   * Number of tanks:", sum(V(g)$type == "tank"), "\n")
  cat("   * Number of junctions:", sum(V(g)$type == "junction"),
      ";", sum(V(g)$type == "junction" & V(g)$demand == 0), "with no demand", "\n")
  cat("   * Number of special junctions:", sum(V(g)$type == "special"),
      ";", sum(V(g)$type == "special" & V(g)$demand == 0), "with no demand", "\n")
  
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
  
  cat("-------------------------------------\n")
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

plot_degree_distribution <- function(g, filename = "degree_distribution.png") {
  vertex_degrees <- degree(g)
  degree_freq <- table(vertex_degrees)
  png(filename)
  barplot(
    degree_freq,
    main = "Degree Distribution",
    xlab = "Degree",
    ylab = "Frequency",
    col = "lightblue",
    border = "darkblue"
  )
  dev.off()
}

plot_graph <- function(g, filename, graph_type = "not original") {
  # Set default node color and shape
  V(g)$color <- "blue"
  V(g)$shape <- "circle"
  
  # Set tanks to green squares
  V(g)$color[V(g)$type == "tank"] <- "green"
  V(g)$shape[V(g)$type == "tank"] <- "square"
  
  # Set default edge color
  E(g)$color <- "black"
  
  # Set pump edges to red
  if (graph_type == "original") {
    E(g)$color[E(g)$type == "pump"] <- "red"
  }
  
  # Set node sizes
  node_sizes <- ifelse(V(g)$type == "tank", 3, 1)
  
  if (graph_type == "original") {
    layout <- cbind(V(g)$x, V(g)$y) * 1.5
  } else {
    layout <- layout_nicely(g)
  }

  pdf(filename)
  plot(
    g,
    layout = layout,
    vertex.color = V(g)$color,
    vertex.shape = V(g)$shape,
    vertex.size = node_sizes,
    vertex.label = NA,
    edge.color = E(g)$color,
    edge.width = ifelse(E(g)$type == "pump", 10, 1)
  )
  dev.off()
}


# ----------- MAIN CODE -----------

output_path <- here("output")
fig_path <- file.path(output_path, "fig")
data_path <- here("data", "csv")

graph_path <- file.path(output_path, "original_graph.rds")
original_graph <- readRDS(graph_path)
message(paste("Graph successfully loaded from:", graph_path))

graph2_path <- file.path(output_path, "reduced_graphv2.rds")
reduced_graph <- readRDS(graph2_path)
message(paste("Graph successfully loaded from:", graph2_path))


print_dataset_info(original_graph)
print_dataset_info(reduced_graph)

filename1 <- file.path(fig_path, "OG_degree_distribution.png")
filename2 <- file.path(fig_path, "RG_degree_distribution.png")
plot_degree_distribution(original_graph, filename1)
plot_degree_distribution(reduced_graph, filename2)


filename1b <- file.path(fig_path, "OG_plot_graph.pdf")
filename2b <- file.path(fig_path, "RG_plot_graph.pdf")
plot_graph(original_graph, filename1b, graph_type = "original")
plot_graph(reduced_graph, filename2b)
