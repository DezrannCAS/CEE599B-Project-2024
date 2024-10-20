rm(list = ls())

library(readr)
library(R6)
library(here)

# Import graph classes and utils
source(here("src", "R", "Node.r"))
source(here("src", "R", "Edge.r"))
source(here("src", "R", "Graph.r"))
source(here("src", "R", "utils.r"))

data_path <- here("data", "csv")

# Constructor
graph <- Graph$new()

# Start with nodes
load_junctions(graph, file.path(data_path, "junctions.csv"))
cat("Junctions loaded\n")
load_tanks(graph, file.path(data_path, "tanks.csv"))
cat("Tanks loaded\n")

# Then edges
load_pumps(graph, file.path(data_path, "pumps.csv"), file.path(data_path, "curves.csv"))
cat("Pumps loaded\n")
load_pipes(graph, file.path(data_path, "pipes.csv"))
cat("Pipes loaded\n")

save_graph(graph, here("src", "njgraph.rds"))
