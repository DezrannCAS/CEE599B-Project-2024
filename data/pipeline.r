rm(list = ls())

library(epanetReader)
library(dplyr)
library(tidyr)
library(here)

setwd(here("data"))


################# Load the dataset #################

nj_network <- read.inp("NJ1.inp")
print(names(nj_network))

# Basic exploration of dataset
get_element_count <- function(component) {
  if (is.null(component)) return(0)
  if (is.data.frame(component) || is.matrix(component)) return(nrow(component))
  if (is.vector(component)) return(length(component))
  return(length(component))
}

element_counts <- sapply(names(nj_network), function(name) {
  get_element_count(nj_network[[name]])
})

for (name in names(element_counts)) {
  cat(sprintf("%s: %d\n", name, element_counts[name]))
}

cat("\n")

print_component <- function(component, component_name, n = NULL) {
  cat(paste("\n====", component_name, "====\n"))
  if (!is.null(component) && length(component) > 0) {
    if (is.null(n)) {
      print(component)
    } else {
      print(head(component, n))
    }
  } else {
    cat("No data available for this component.\n")
  }
}

# Print information for each component
print_component(nj_network$Junctions, "Junctions", 10)
print_component(nj_network$Tanks, "Tanks")
print_component(nj_network$Coordinates, "Coordinates", 10)  # for junctions and tanks
print_component(nj_network$Pipes, "Pipes", 10)
print_component(nj_network$Pumps, "Pumps")
print_component(nj_network$Patterns, "Patterns") # for junctions
print_component(nj_network$Curves, "Curves")  # for pumps
print_component(nj_network$Controls, "Controls") # for pumps
#print_component(nj_network$Energy, "Energy")
print_component(nj_network$Status, "Status")  # for pumps
#print_component(nj_network$Times, "Times")
#print_component(nj_network$Report, "Report")
#print_component(nj_network$Options, "Options") # check that one again
#print_component(nj_network$Labels, "Labels")
#print_component(nj_network$Backdrop, "Backdrop")


################## Check the data ##################
cat("\n=============================================\n")

# Check the status
closed_pipes <- nj_network$Pipes[nj_network$Pipes$Status == "Closed", ]
if (nrow(closed_pipes) > 0) {
  cat(sprintf("Found %d closed pipes:\n", nrow(closed_pipes)))
  print(closed_pipes)
} else {
  cat("No closed pipes found.\n")
}

# Get the maximum ID from Pipes and Junctions
max_junction_id <- max(as.numeric(nj_network$Junctions$ID), na.rm = TRUE)
max_pipe_id <- max(as.numeric(nj_network$Pipes$ID), na.rm = TRUE)
cat(sprintf("Maximum Junction ID: %d\n", max_junction_id))
cat(sprintf("Maximum Pipe ID: %d\n", max_pipe_id))

# Check for overlap between Pump IDs and Status IDs
pump_ids <- nj_network$Pumps$ID
status_ids <- nj_network$Status$ID
pumps_in_status <- pump_ids[pump_ids %in% status_ids]
if (length(pumps_in_status) > 0) {
  cat("Pump IDs found in Status:\n")
  print(pumps_in_status)
} else {
  cat("No Pump IDs found in Status.\n")
}

# Check that all Coordinates IDs are present in either Junctions or Tanks
coords_ids <- nj_network$Coordinates$ID
junctions_ids <- nj_network$Junctions$ID
tanks_ids <- nj_network$Tanks$ID
missing_from_junctions_tanks <- setdiff(coords_ids, union(junctions_ids, tanks_ids))
if (length(missing_from_junctions_tanks) > 0) {
  cat(length(missing_from_junctions_tanks), " IDs in Coordinates but not in Junctions or Tanks:\n")
  print(missing_from_junctions_tanks)
} else {
  cat("All Coordinates IDs are present in Junctions or Tanks\n")
}

# Check whether the pumps are also pipes (share the same Node1 and Node2)
pipes <- nj_network$Pipes
pumps <- nj_network$Pumps
pump_as_pipe <- FALSE
for (i in 1:nrow(pumps)) {
  pump_node1 <- pumps$Node1[i]
  pump_node2 <- pumps$Node2[i]
  matching_pipe <- pipes[pipes$Node1 == pump_node1 & pipes$Node2 == pump_node2, ]
  
  if (nrow(matching_pipe) > 0) {
    cat("Pump with Node1 =", pump_node1, "and Node2 =", pump_node2, "matches the following pipe(s):\n")
    print(matching_pipe)
    pump_as_pipe <- TRUE
  }
}
if (pump_as_pipe == FALSE) {cat("No pump is a pipe\n")}

# Count the number of occurence of each pattern in Junctions
cat("Patterns count in Junctions")
pattern_counts <- table(nj_network$Junctions$Pattern)
print(pattern_counts)

# stop()

######### Convert into separate CSV files #########

# Files:
# 1. Nodes:
# ----- Junctions: ID, 3D-coordinates, base demand, pattern ID
# ----- Tanks: ID, 3D-coordinates, init level, capacity
# 2. Edges:
# ----- Pipes: ID, node1, node2
# ----- Pumps: ID, node1, node2, curve ID
# 3. Patterns, curves and control

# Instructions:
# Clean off the closed junctions, and the closed pumps, look for links with missing nodes
# Maybe also delete the junctions with 0-pattern (ie `28-W15`, `25-W38`, `27-W20`, `31-W21`)
# Set all indices to string (in particular "start" in pipes.csv & "start"+"end" in pumps.csv)
# Check whether pumps are already pipes + check temporal coherence (esp for point 3.)

# Extract data
all_junctions <- merge(
  nj_network$Junctions[, c("ID", "Elevation", "Demand", "Pattern")], 
  nj_network$Coordinates[, c("Node", "X.coord", "Y.coord")],
  by.x = "ID", by.y = "Node"
)
all_junctions$ID <- as.character(all_junctions$ID) # format everything...
all_junctions$Elevation <- as.numeric(all_junctions$Elevation)
all_junctions$Demand <- as.numeric(all_junctions$Demand)
all_junctions$Pattern <- as.character(all_junctions$Pattern)
all_junctions <- all_junctions[, c("ID", "X.coord", "Y.coord", "Elevation", "Demand", "Pattern")]
colnames(all_junctions) <- c("id", "x", "y", "z", "demand", "pattern")

standard_junctions <- subset(all_junctions, pattern == "1")
standard_junctions <- standard_junctions[, c("id", "x", "y", "z", "demand")]

special_junctions <- subset(all_junctions, pattern != "1")

tanks <- merge(
  nj_network$Tanks[, c("ID", "Elevation", "InitLevel", "MaxLevel")],
  nj_network$Coordinates[, c("Node", "X.coord", "Y.coord")],
  by.x = "ID", by.y = "Node"
)
tanks$ID <- as.character(tanks$ID)
tanks$Elevation <- as.numeric(tanks$Elevation)
tanks$InitLevel <- as.numeric(tanks$InitLevel)
tanks$MaxLevel <- as.numeric(tanks$MaxLevel)
tanks <- tanks[, c("ID", "X.coord", "Y.coord", "Elevation", "InitLevel", "MaxLevel")]
colnames(tanks) <- c("id", "x", "y", "z", "init", "capacity")

pipes <- nj_network$Pipes[nj_network$Pipes$Status == "Open", c("ID", "Node1", "Node2", "Length")]  # only open pipes
pipes$ID <- as.character(pipes$ID)
pipes$Node1 <- as.character(pipes$Node1)
pipes$Node2 <- as.character(pipes$Node2)
pipes$Length <- as.numeric(pipes$Length)
colnames(pipes) <- c("id", "start", "end", "length")

pumps <- nj_network$Pumps[, c("ID", "Node1", "Node2", "Parameters")]
pumps$ID <- as.character(pumps$ID)
pumps$Node1 <- as.character(pumps$Node1)
pumps$Node2 <- as.character(pumps$Node2)
pumps$Parameters <- as.character(pumps$Parameters)
closed_ids <- nj_network$Status$ID[nj_network$Status$Status == "Closed"]
pumps <- pumps[!pumps$ID %in% closed_ids, ] # Delete closed pumps
colnames(pumps) <- c("id", "start", "end", "curve")

# Check the dataset
check_nans <- function(df, component_name) {
  nan_values <- which(is.na(df), arr.ind = TRUE)
  if (nrow(nan_values) > 0) {
    cat(sprintf("Warning: NaN values found in %s at the following locations:\n", component_name))
    print(nan_values)
  }
}
check_nans(all_junctions, "Junctions")
check_nans(pipes, "Pipes")

# Identify junctions with 0-pattern
zero_patterns <- c("28-W15", "25-W38", "27-W20", "31-W21")
zero_junctions <- all_junctions[all_junctions$pattern %in% zero_patterns, ]
if (nrow(zero_junctions) > 0) {
  cat("Junctions with 0-pattern found:\n")
  print(zero_junctions)
  # Delete these junctions?
} else {
  cat("No junctions with 0-pattern found.\n")
}

# Save clean data
write.csv(standard_junctions, "csv/junctions.csv", row.names = FALSE)
write.csv(special_junctions, "csv/special_junctions.csv", row.names = FALSE)
write.csv(tanks, "csv/tanks.csv", row.names = FALSE)
write.csv(pipes, "csv/pipes.csv", row.names = FALSE)
write.csv(pumps, "csv/pumps.csv", row.names = FALSE)

# Save patterns, curves and controls in CSV format
patterns_df <- do.call(rbind,
                       lapply(names(nj_network$Patterns), function(key) {
                         data.frame(key = as.character(key), 
                                    value = as.numeric(nj_network$Patterns[[key]]),
                                    index = seq_along(nj_network$Patterns[[key]]))
                       }))
write.csv(patterns_df, "csv/patterns.csv", row.names = FALSE)

curves_df <- do.call(rbind,
                     lapply(names(nj_network$Curves), function(curve_name) {
                       X_vals <- nj_network$Curves[[curve_name]]$X
                       Y_vals <- nj_network$Curves[[curve_name]]$Y
                       data.frame(key = as.character(curve_name), x = as.numeric(X_vals), y = as.numeric(Y_vals))
                     }))
write.csv(curves_df, "csv/curves.csv", row.names = FALSE)

parse_control <- function(entry) {
  matches <- regmatches(entry, regexec("LINK (\\d+) (\\S+) AT TIME (\\S+)", entry))
  data.frame(
    link = as.character(matches[[1]][2]),   # link number
    state = as.character(matches[[1]][3]),  # state (e.g., "CLOSED", "1.00")
    time = as.numeric(matches[[1]][4])      # time
  )
}
controls_df <- do.call(rbind, lapply(nj_network$Controls, parse_control))
write.csv(controls_df, "csv/controls.csv", row.names = FALSE)
