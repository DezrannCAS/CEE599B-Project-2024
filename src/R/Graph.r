# Graph class
Graph <- R6Class("Graph",
  public = list(
    nodes = list(),
    edges = list(),

    # Add node
    add_node = function(node) {
      self$nodes[[node$id]] <- node
    },

    # Add edge
    add_edge = function(edge) {
      self$edges[[edge$id]] <- edge
      edge$node1$add_edge(edge)
    },

    # Get node
    get_node = function(node_id) {
      for (node in self$nodes) {
        if (!is.null(node$id) && node$id == node_id) { # some nodes have ID null, check why!!!!!
          return(node)
        }
      }
      return(NULL)  # returns NULL if the node does not exist -- used to check existence of node
    },

    # Display the graph
    display_graph = function() {
      for (node in self$nodes) {
        node$print_node(TRUE)
      }
    }
  )
)
