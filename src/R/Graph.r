library(R6)

Graph <- R6Class("Graph",
  public = list(
    nodes = list(),
    edges = list(),
    
    add_node = function(node) {
      self$nodes[[node$id]] <- node
    },
    
    add_edge = function(edge) {
      self$edges[[edge$id]] <- edge
    }
  )
)