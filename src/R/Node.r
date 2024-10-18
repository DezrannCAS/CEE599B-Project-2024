# Node superclass
Node <- R6Class("Node",
  public = list(
    id = NULL,
    x = NULL,
    y = NULL,
    z = NULL,

    initialize = function(id, coord) {
      self$id <- id
      self$x <- coord[1]
      self$y <- coord[2]
      self$z <- coord[3]
    }
  )
)

# Tank subclass
Tank <- R6Class("Tank",
  inherit = Node,
  
  public = list(
    capacity = NULL,
    
    initialize = function(id, coord, capacity) {
      super$initialize(id, coord)
      self$capacity <- capacity
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