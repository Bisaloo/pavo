#' Process spectra
#'
#' Applies normalization and/or smoothing to spectra for further analysis or plotting.
#'
#' @param rspecdata (required) a data frame, possibly an object of class \code{rspec},
#' with a column with wavelength data, named 'wl', and the remaining column containing
#' spectra to process.
#' @param opt what type of processing options to apply. User can select multiple options
#'            by providing a vector. Possibilities are:
#' \itemize{
#' 	\item \code{"none"} does not perform any processing (default).
#' 	\item \code{"smooth"} applies LOESS smoothing to each spectrum using
#'                      \code{\link{loess.smooth}}. Optimal smoothing parameter
#'                      can be assessed by using \code{\link{plotsmooth}}.
#' 	\item \code{"minimum"} subtracts the minimum from each individual spectra.
#' 	\item \code{"maxmimum"} divides each spectrum by its maximum value.
#' 	\item \code{"sum"} divides each spectrum by summed values.
#' 	\item \code{"bin"} bins each spectrum into the specified number of bins.
#'                      \code{bins} argument must be set.
#'      \item \code{"center"} centers individual spectra by subtracting mean
#'                      reflectance from all values.
#' }
#'
#' @param fixneg how to handle negative values. Possibilities are:
#' \itemize{
#' 	\item \code{"none"} does not perform negative value correction (default).
#'      \item \code{"zero"} sets all negative values to zero.
#'      \item \code{"addmin"} adds the absolute value of the maximally negative
#'                      values of each spectra to the reflectance at all other
#'                      wavelengths (setting the minimum value to zero, but
#'                      scaling other values accordingly).
#' }
#' @param span sets the smoothing parameter used by \code{loess.smooth}.
#' @param bins sets the number of equally sized wavelength bins for \code{opt = "bin"}.
#'
#' @return A data frame of class \code{rspec} with the processed data.
#'
#' @export
#'
#' @author Chad Eliason \email{cme16@@zips.uakron.edu}
#'
#' @examples
#' data(teal)
#' plot(teal, select = 10)
#' 
#' # Smooth data to remove noise
#' teal.sm <- procspec(teal, opt = "smooth", span = 0.25)
#' plot(teal.sm, select = 10)
#' 
#' # Normalize to max of unity
#' teal.max <- procspec(teal, opt = c("max"))
#' plot(teal.max, select = 10)
#' @seealso \code{\link{loess.smooth}}, \code{\link{plotsmooth}}
#'
#' @references Cuthill, I., Bennett, A. T. D., Partridge, J. & Maier, E. 1999.
#'  Plumage reflectance and the objective assessment of avian sexual dichromatism.
#'  The American Naturalist, 153, 183-200.
#' @references Montgomerie R. 2006. Analyzing colors. In Hill, G.E, and McGraw,
#'  K.J., eds. Bird Coloration. Volume 1 Mechanisms and measurements. Harvard
#'  University Press, Cambridge, Massachusetts.
#' @references White, T. E., Dalrymple, R. L., Noble D. W. A., O'Hanlon, J. C.,
#' Zurek, D. B., Umbers, K. D. L. 2015. Reproducible research in the study
#' of biological coloration. Animal Behaviour, 106, 51-57.

procspec <- function(rspecdata, opt = c(
                       "none", "smooth", "maximum", "minimum",
                       "bin", "sum", "center"
                     ),
                     fixneg = c("none", "addmin", "zero"),
                     span = 0.25, bins = 20) {
  opt <- match.arg(opt, several.ok = TRUE)

  fixneg <- match.arg(fixneg)

  applied <- "processing options applied:"

  if (any(opt == "none")) {
    opt <- "none" # remove other opt arguments (so they are not called further on, but still allowing for fixneg to work)

    if (fixneg == "none") {
      stop("No processing options selected")
    }
  }

  wl_index <- which(names(rspecdata) == "wl")

  if (length(wl_index > 0)) {
    wl <- rspecdata[, wl_index]
    rspecdata <- as.data.frame(rspecdata[-wl_index])
  } else {
    warning("No wavelengths supplied; using arbitrary values")
    rspecdata <- as.data.frame(rspecdata)
    wl <- seq_len(nrow(rspecdata))
  }

  nam <- names(rspecdata)

  if (any(opt == "smooth")) {
    rspecdata <- vapply(seq_len(ncol(rspecdata)), function(z) {
      loess.smooth(
        x = wl,
        y = as.data.frame(rspecdata[, z]), span = span, degree = 2,
        family = "gaussian", evaluation = length(wl)
      )$y
    }, numeric(nrow(rspecdata)))
    applied <- c(applied, paste("smoothing spectra with a span of", span))
  }

  mins <- apply(rspecdata, 2, min)
  maxs <- apply(rspecdata, 2, max)

  if (fixneg == "addmin") {
    rspecdata <- t(t(rspecdata) + abs(pmin(0, mins)))
    applied <- c(applied, "Negative value correction: added min to all reflectance")
  }

  if (fixneg == "zero") {
    rspecdata[rspecdata < 0] <- 0
    applied <- c(applied, "Negative value correction: converted negative values to zero")
  }

  if (any(opt == "minimum")) {
    rspecdata <- t(t(rspecdata) - mins)
    applied <- c(applied, "Scaling spectra to a minimum value of zero")
  }

  if (any(opt == "maximum")) {
    rspecdata <- t(t(rspecdata) / maxs)
    applied <- c(applied, "Scaling spectra to a maximum value of 1")
  }

  if (any(opt == "sum")) {
    rspecdata <- t(t(rspecdata) / colSums(rspecdata))
    applied <- c(applied, "Scaling spectra to a total area of 1")
  }

  if (any(opt == "center")) {
    rspecdata <- t(t(rspecdata) - colMeans(rspecdata))
    applied <- c(applied, "Centering spectra to a mean of zero")
  }

  # Calculate medians according to # of bins specified for use in PCA
  # Method follows Cuthill et al. (1999)
  if (any(opt == "bin")) {
    bw <- floor(length(wl) / (bins - 1))
    wl_bin <- seq(min(wl), by = bw, length.out = bins)
    wl_ind <- match(wl_bin, wl)
    rspecdata <- as.data.frame(rspecdata)
    rspecdata <- vapply(
      seq_along(wl_ind), function(z)
        apply(rspecdata[wl_ind[z]:(wl_ind[z] + bw), , drop = FALSE], 2, median, na.rm = TRUE),
      numeric(ncol(rspecdata))
    )

    rspecdata <- data.frame(matrix(unlist(rspecdata), nrow = bins, byrow = TRUE))
    rspecdata <- as.data.frame(cbind(wl_bin, rspecdata))
    applied <- c(applied, paste("binned spectra to ", bw, "-nm intervals\n", sep = ""))
  } else {
    rspecdata <- as.data.frame(cbind(wl, rspecdata))
  }

  names(rspecdata) <- c("wl", nam)
  class(rspecdata) <- c("rspec", "data.frame")

  applied <- paste(applied, collapse = "\n")
  message(applied)

  rspecdata
}
