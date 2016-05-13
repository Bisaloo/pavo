#' Plot a Maxwell Triangle
#' 
#' \code{triplot} produces a Maxwell triangle plot
#'
#' @param tridata (required) a data frame, possibly a result from the \code{trispace} 
#'  function, containing values for the 'x' and 'y' coordinates as columns (labeled as such)
#' @param achro should a point be plotted at the origin (defaults to \code{TRUE})?
#' @param labels plot verticy labels? Defaults to \code{TRUE}
#' @param cex.labels character expansion factor for category labels when \code{labels = TRUE})
#' @param achrosize size of the point at the origin when \code{achro = TRUE} (defaults to 0.8)
#' @param achrocol color of the point at the origin \code{achro = TRUE} (defaults to grey)
#' @param out.lwd line width for triangle outline (defaults to 1)
#' @param out.lcol line colour for triangle outline (defaults to black)
#' @param out.lty line type for triangle outline (defaults to 1)
#' @param ... additional graphical options. See \code{\link{par}}.
#'
#' @examples \dontrun{
#' data(flowers)
#' vis.flowers <- vismodel(flowers, visual = 'apis')
#' tri.flowers <- colspace(vis.flowers, space = 'tri')
#' plot(tri.flowers)
#' }
#'
#' @author Thomas White \email{thomas.white026@@gmail.com}
#' 
#' @references Kelber A, Vorobyev M, Osorio D. (2003). Animal colour vision
#'    - behavioural tests and physiological concepts. Biological Reviews, 78,
#'    81 - 118.
#' @references Neumeyer C (1980) Simultaneous color contrast in the honeybee. 
#'  Journal of comparative physiology, 139(3), 165-176.

.triplot <- function(tridata, labels = TRUE, achro = TRUE, achrocol = 'grey', achrosize = 0.8, 
                     cex.labels = 1, out.lwd = 1, out.lcol = 'black', out.lty = 1, ...){ 
    
# Check if object is of class colspace and trichromat
  if(!('colspace' %in% attr(tridata, 'class')) & is.element(FALSE, c('x', 'y') %in% names(tridata)))
    stop('object is not of class ', dQuote('colspace'), ', and does not contain x, y coordinates')
  
  if(('colspace' %in% attr(tridata, 'class')) & attr(tridata, 'clrsp') != 'trispace')
    stop(dQuote('colspace'), ' object is not a result of ', dQuote('trispace()')) 
  
  arg <- list(...)
  
# Set defaults
  if(is.null(arg$col))
    arg$col <- 'black'
  if(is.null(arg$pch))
    arg$pch <- 19
  if(is.null(arg$type))
    arg$type = 'p'
  if(is.null(arg$xlim))
    arg$xlim <- c(-1/sqrt(2), 1/sqrt(2))
  if(is.null(arg$ylim))
    arg$ylim <- c(-sqrt(2)/(2*(sqrt(3))), sqrt(2)/sqrt(3))
    
# Verticy coordinates  
  vert <- data.frame(x = c(0, -1/sqrt(2), 1/sqrt(2)),
                       y = c(sqrt(2)/sqrt(3), -sqrt(2)/(2*(sqrt(3))), -sqrt(2)/(2*(sqrt(3)))))
  
# Plot
  arg$x <- tridata$x
  arg$y <- tridata$y
  arg$xlab = ' '
  arg$ylab = ' '
  arg$bty = 'n'
  arg$axes = FALSE
  
  do.call(plot, arg)
  
# Add lines 
  segments(vert$x[1], vert$y[1], vert$x[2], vert$y[2], lwd = out.lwd, lty = out.lty, col = out.lcol)
  segments(vert$x[1], vert$y[1], vert$x[3], vert$y[3], lwd = out.lwd, lty = out.lty, col = out.lcol)
  segments(vert$x[2], vert$y[2], vert$x[3], vert$y[3], lwd = out.lwd, lty = out.lty, col = out.lcol)
  
# Origin
  if(isTRUE(achro)){
    points(x = 0, y = 0, pch = 15, col = achrocol, cex = achrosize)
  }
  
# Add text (coloured points better as in tcsplot?)
  if(isTRUE(labels)){
    text('S', x = -0.76, y = -0.39, xpd = TRUE, cex = cex.labels)
    text('M', x = 0, y = 0.88, xpd = TRUE, cex = cex.labels)
    text('L', x = 0.76, y = -0.39, xpd = TRUE, cex = cex.labels)
  }
  
}