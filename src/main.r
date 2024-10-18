rm(list = ls())

library(R6)
library(here)

source(here("src", "R", "Node.R"))
source(here("src", "R", "Edge.R"))
source(here("src", "R", "Graph.R"))
source(here("src", "R", "utils.R"))

fig_path <- here("fig")
data <- read.csv(here("data", "dataset.csv"))
