#' Test is object is of class 'vismodel'
#' 
#' @param object an R object
#'  
#' @return a logical value indicating whether the object is of class \code{vismodel}
is.vismodel <- function(object) {
  inherits(object, "vismodel")
}