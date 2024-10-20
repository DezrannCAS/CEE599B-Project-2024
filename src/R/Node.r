# Node superclass
Node <- R6Class("Node",
  public = list(
    id = NULL,
    x = NULL,
    y = NULL,
    z = NULL,
    adjacencyList = list(),  # list of directed edges

    initialize = function(id, coord) {
      self$id <- id
      self$x <- coord[1]
      self$y <- coord[2]
      self$z <- coord[3]
      self$adjacencyList <- list()
    },

    add_edge = function(edge) {
      self$adjacencyList[[edge$id]] <- edge
    },

    print_node = function(showDetails = TRUE) {
      cat("Node", self$id, "with coordinates:", self$x, ",", self$y, ",", self$z, "\n")
      if (showDetails && length(self$adjacencyList) > 0) {
        cat("--- Connected edges:\n")
        for (edge in self$adjacencyList) {
          edge$print_edge()
        }
      }
    }
  )
)

# Junction subclass
Junction <- R6Class("Junction",
  inherit = Node,

  public = list(
    demand = NULL,

    initialize = function(id, coord, demand) {
      super$initialize(id, coord)
      self$demand <- demand
    }
  )
)

# Tank subclass
Tank <- R6Class("Tank",
  inherit = Node,

  public = list(
    capacity = NULL,
    level = NULL,

    initialize = function(id, coord, capacity, init_level) {
      super$initialize(id, coord)
      self$capacity <- capacity
      self$level <- init_level
    }
  )
)
