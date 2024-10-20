# Load junctions from CSV
load_junctions <- function(graph, filepath) {
  data <- read_csv(filepath)
  for (i in 1:nrow(data)) {
    #stopifnot(!is.null(data$id[i]))
    coord <- c(data$x[i], data$y[i], data$z[i])
    graph$add_node(Junction$new(data$id[i], coord, data$demand[i]))
  }
}

# Load tanks from CSV
load_tanks <- function(graph, filepath) {
  data <- read_csv(filepath)
  for (i in 1:nrow(data)) {
    #stopifnot(!is.null(data$id[i]))
    coord <- c(data$x[i], data$y[i], data$z[i])
    graph$add_node(Tank$new(data$id[i], coord, data$capacity[i], data$init[i]))
  }
}

# Load pipes from CSV
load_pipes <- function(graph, filepath) {
  data <- read_csv(filepath)
  total_rows <- nrow(data)

  for (i in 1:total_rows) {
    node1 <- graph$get_node(data$start[i])
    node2 <- graph$get_node(data$end[i])

    # Check that both nodes exist in the graph
    if (is.null(node1)) {
      cat("Node", data$start[i], "does not exist in the graph. Skipping pipe", data$id[i], "\n")
      next
    }
    if (is.null(node2)) {
      cat("Node", data$end[i], "does not exist in the graph. Skipping pipe", data$id[i], "\n")
      next
    }
    # this will skip potential edges not linked to nodes

    graph$add_edge(Pipe$new(data$id[i], node1, node2, NULL, NULL, NULL))

    # Print progress (this loader takes some time...)
    if (i %% 100 == 0) {
      cat(sprintf("Progress: %d/%d (%.2f%%)\n", i, total_rows, i/total_rows*100))
    }
  }
}

# Load pumps from CSV
load_pumps <- function(graph, filepath, curves_path) {
  data <- read_csv(filepath)
  curves <- read_csv(curves_path)
  for (i in 1:nrow(data)) {
    node1 <- graph$get_node(data$start[i])
    node2 <- graph$get_node(data$end[i])
    curve_points <- subset(curves, key == data$curve[i])
    graph$add_edge(Pump$new(data$id[i], node1, node2, NULL, curve_points, 0.85))
  }
}

# Visualize the graph
visualize_graph <- function(graph, output_path = "figures/graph_plot.png") {
  edges <- do.call(rbind, lapply(graph$edges, function(e) {
    data.frame(node1_x = e$node1$x, node1_y = e$node1$y,
               node2_x = e$node2$x, node2_y = e$node2$y, id = e$id)
  }))
  
  ggplot() +
    geom_segment(data = edges, aes(x = node1_x, y = node1_y, xend = node2_x, yend = node2_y, color = id),
                 arrow = arrow(length = unit(0.3, "cm")), size = 1) +
    geom_point(data = do.call(rbind, lapply(graph$nodes, function(n) data.frame(x = n$x, y = n$y, id = n$id))),
               aes(x = x, y = y, label = id), size = 5) +
    geom_text(aes(x = x, y = y, label = id), hjust = 0, vjust = 1.5) +
    theme_minimal() +
    labs(title = "Water Distribution Network Graph") +
    ggsave(output_path)
}

save_graph <- function(graph, file_path) {
  saveRDS(graph, file = file_path)
  cat("Graph saved to", file_path, "\n")
}

load_graph <- function(file_path) {
  graph <- readRDS(file_path)
  cat("Graph loaded from", file_path, "\n")
  return(graph)
}
