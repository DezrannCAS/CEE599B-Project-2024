rm(list = ls())

here::i_am("src/igraph/reduce_from_extrav2.r")

library(igraph)
library(dplyr)
library(here)
library(jsonlite)

output_path <- here("output")
fig_path <- file.path(output_path, "fig")
data_path <- here("data", "csv")

graph_path <- file.path(output_path, "original_graph.rds")
json_file <- file.path(output_path, "chains_extra.json")

# ----------- FUNCTIONS -----------

process_chain <- function(chain_data, graph) {
  chain_index <- chain_data$chain_index[[1]]
  chain_vertices <- chain_data$chain
  
  # Calculate the sum of demands for vertices in the chain
  demand_sum <- sum(V(graph)[chain_vertices]$demand, na.rm = TRUE)
  
  # Create the named list
  list(
    name = paste0("AGG-", chain_index),
    demand = demand_sum,
    type = "aggregated"
  )
}

# ----------- MAIN CODE -----------


graph <- readRDS(graph_path)
chains_data <- fromJSON(json_file, simplifyVector = FALSE)
cat("Number of chains:", length(chains_data), "\n")

result_list <- lapply(chains_data, process_chain, graph = graph)

cat("Number of elements in the return list:", length(result_list), "\n")

