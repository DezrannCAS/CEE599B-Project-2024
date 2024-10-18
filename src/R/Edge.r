# Edge superclass
Edge <- R6Class("Edge",
  public = list(
    id = NULL,
    node1 = NULL,
    node2 = NULL,
    
    initialize = function(id, node1, node2) {
      self$id <- id
      self$node1 <- node1
      self$node2 <- node2
    },
    
    # Abstract-like method
    print_edge = function() {
      stop("This method must be implemented by subclasses.")
    }
  )
)

# Pipe subclass
Pipe <- R6Class("Pipe",
  inherit = Edge,
  
  public = list(
    flow_rate = NULL,
    
    initialize = function(id, node1, node2, flow_rate) {
      super$initialize(id, node1, node2)
      self$flow_rate <- flow_rate
    },
    
    # Concrete method
    print_edge = function() {
      cat("Pipe ID:", self$id, "- Node1:", self$node1, "- Node2:", self$node2, "- Flow Rate:", self$flow_rate, "\n")
    }
  )
)

# Pump subclass
Pump <- R6Class("Pump",
  inherit = Edge,
  
  public = list(
    efficiency = NULL,
    
    initialize = function(id, node1, node2, efficiency) {
      super$initialize(id, node1, node2)
      self$efficiency <- efficiency
    },
    
    # Concrete method
    print_edge = function() {
      cat("Pump ID:", self$id, "- Node1:", self$node1, "- Node2:", self$node2, "- Efficiency:", self$efficiency, "\n")
    }
  )
)