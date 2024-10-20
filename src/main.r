rm(list = ls())

library(ggplot2)
library(readr)
library(R6)
library(here)

# Import graph classes and utils
source(here("src", "R", "Node.r"))
source(here("src", "R", "Edge.r"))
source(here("src", "R", "Graph.r"))
source(here("src", "R", "utils.r"))

# Paths to figures and data files
fig_path <- here("fig")
data_path <- here("data", "csv")

# Load graph
execution_time <- system.time({
  graph <- load_graph(here("src", "njgraph.rds"))
})["elapsed"]
cat("Time to execute load_graph:", execution_time, "seconds\n")

cat("\nGraph Structure:\n")
graph$display_graph()

visualize_graph(graph, file.path(fig_path, "graph_plot.png"))
