# Edge superclass
Edge <- R6Class("Edge",
  public = list(
    id = NULL,
    node1 = NULL,
    node2 = NULL,
    flow_rate = NULL,

    initialize = function(id, node1, node2, flow_rate) {
      self$id <- id
      self$node1 <- node1
      self$node2 <- node2
      self$flow_rate <- flow_rate
    },

    print_edge = function() {
      cat("Edge ID:", self$id, 
          "- Start:", self$node1$id, 
          "- End:", self$node2$id
    }
  )
)

# Pipe subclass
Pipe <- R6Class("Pipe",
  inherit = Edge,

  public = list(
    length = NULL,
    diameter = NULL,

    initialize = function(id, node1, node2, flow_rate, length, diameter) {
      super$initialize(id, node1, node2, flow_rate)
      self$length <- length
      self$diameter <- diameter
    }
  )
)

# Pump subclass
Pump <- R6Class("Pump",
  inherit = Edge,
  
  public = list(
    curve_points = data.frame(),
    efficiency = NULL,
    
    initialize = function(id, node1, node2, flow_rate, curve_points, efficiency) {
      super$initialize(id, node1, node2, flow_rate)
      self$curve_points <- curve_points
      self$efficiency <- efficiency
    }
  )
)
