% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/points.colspace.R
\name{points.colspace}
\alias{points.colspace}
\title{Plot points in a colourspace}
\usage{
\method{points}{colspace}(x, ...)
}
\arguments{
\item{x}{(required) an object of class \code{colspace}.}

\item{...}{additional graphical options. See \code{\link{par}}.}
}
\value{
\code{points.colspace} adds points to a colorspace plot. When \code{space = 'tcs'},
 it creates 3D points in a tetrahedral color space plot using functions of the package \code{rgl},
 based on openGL capabilities.
}
\description{
Add points to a colourspace plot
}
\author{
Rafael Maia \email{rm72@zips.uakron.edu}

Thomas White \email{thomas.white026@gmail.com}
}
