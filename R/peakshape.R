#' Peak shape descriptors
#'
#' Calculates height, location and width of peak at the reflectance midpoint (FWHM).
#' Note: bounds should be set wide enough to incorporate all minima in spectra. Smoothing
#' spectra using \code{\link{procspec}} is also recommended.
#'
#' @param rspecdata (required) a data frame, possibly an object of class \code{rspec},
#' with a column with wavelength data, named 'wl', and the remaining column containing
#' spectra to process.
#' @param select specification of which spectra to plot. Can be a numeric vector or
#' factor (e.g., \code{sex == 'male'}).
#' @param lim a vector specifying the wavelength range to analyze.
#' @param plot logical. Should plots indicating calculated parameters be returned?
#' (Defaults to \code{TRUE}).
#' @param ask logical, specifies whether user input needed to plot multiple plots
#' when number of spectra to analyze is greater than 1 (defaults to \code{FALSE}).
#' @param absolute.min logical. If \code{TRUE}, full width at half maximum will be
#' calculated using the absolute minimum reflectance of the spectrum, even if
#' that value falls outside the range specified by \code{lim}. (defaults to \code{FALSE})
#' @param ... additional arguments to be passed to plot.
#'
#' @return a data frame containing column names (id); peak height (max value, B3), location (hue, H1) and full width
#' at half maximum (FWHM), as well as half widths on left (HWHM.l) and right side of peak (HWHM.r). Incl.min column
#' indicates whether user-defined bounds incorporate the actual minima of the spectra.
#' Function will return a warning if not.
#'
#' @seealso \code{\link{procspec}}
#'
#' @export
#'
#' @examples
#' data(teal)
#' 
#' peakshape(teal, select = 3)
#' peakshape(teal, select = 10)
#' 
#' # Use wavelength bounds to narrow in on peak of interest
#' peakshape(teal, select = 10, lim = c(400, 550))
#' @author Chad Eliason \email{cme16@@zips.uakron.edu}
#' @author Rafael Maia \email{rm72@@zips.uakron.edu}
#' @author Hugo Gruson \email{hugo.gruson+R@@normalesup.org}

peakshape <- function(rspecdata, select = NULL, lim = NULL,
                      plot = TRUE, ask = FALSE, absolute.min = FALSE, ...) {
  nms <- names(rspecdata)

  wl_index <- which(nms == "wl")
  if (length(wl_index) > 0) {
    haswl <- TRUE
    wl <- rspecdata[, wl_index]
  } else {
    haswl <- FALSE
    wl <- seq_len(nrow(rspecdata))
    warning("No wavelengths provided; using arbitrary index values",
      call. = FALSE
    )
  }

  # set default wavelength range if not provided
  if (is.null(lim)) {
    lim <- range(wl)
  }


  if (is.null(select)) {
    select <- seq_along(rspecdata)
  }
  else {
    # subset based on indexing vector
    if (is.logical(select)) {
      select <- which(select)
    }
    if (isTRUE(wl_index %in% select)) {
      warning("Cannot calculate peak shape on wavelength index", call. = FALSE)
    }
  }

  if (haswl) {
    select <- setdiff(select, wl_index)
  }

  rspecdata <- as.data.frame(rspecdata[, select, drop = FALSE])

  if (ncol(rspecdata) == 0) {
    return(NULL)
  }

  wlrange <- seq(lim[1], lim[2])

  rspecdata2 <- rspecdata[wl >= lim[1] & wl <= lim[2], , drop = FALSE]

  Bmax <- apply(rspecdata2, 2, max) # max refls
  Bmin <- apply(rspecdata2, 2, min) # min refls
  Bmin_all <- apply(rspecdata, 2, min) # min refls, whole spectrum

  if (absolute.min) {
    halfmax <- (Bmax + Bmin_all) / 2
  } else {
    halfmax <- (Bmax + Bmin) / 2
  }

  Xi <- vapply(
    seq_along(rspecdata2),
    function(x) which(rspecdata2[, x] == Bmax[x]),
    numeric(1)
  ) # lambda_max index
  dblpeaks <- vapply(Xi, length, numeric(1))
  if (any(dblpeaks > 1)) {
    # Keep only first peak of each spectrum
    dblpeak_nms <- nms[select][dblpeaks > 1]
    Xi <- vapply(Xi, "[[", 1, numeric(1))
    warning("Multiple wavelengths have the same reflectance value (",
      paste(dblpeak_nms, collapse = ", "), "). Using first peak found. ",
      "Please check the data or try smoothing.",
      call. = FALSE
    )
  }

  hilo <- t(t(rspecdata2) - halfmax) < 0

  FWHM_lims <- sapply(seq_len(ncol(rspecdata2)), function(x) {
    # Start at H1 and find first value below halfmax
    fstHM <- match(TRUE, hilo[seq(Xi[x], 1, -1), x])
    sndHM <- match(TRUE, hilo[Xi[x]:nrow(rspecdata2), x])
    return(c(fstHM, sndHM))
  })

  if (any(Bmin > Bmin_all)) {
    warning("Consider fixing ", dQuote("lim"), " in spectra with ",
      dQuote("incl.min"), " marked ", dQuote("No"),
      " to incorporate all minima in spectral curves",
      call. = FALSE
    )
  }

  hue <- wlrange[Xi]

  # Shift FWHM_lims by 1 because we calculated the index by including H1.
  Xa <- wlrange[Xi - FWHM_lims[1, ] + 1]
  Xb <- wlrange[Xi + FWHM_lims[2, ] - 1]

  if (plot) {
    oPar <- par("ask")
    on.exit(par(oPar))
    par(ask = ask)

    for (i in seq_along(select)) {
      plot(rspecdata[, i] ~ wl,
        type = "l", xlab = "Wavelength (nm)",
        ylab = "Reflectance (%)", main = nms[select[i]], ...
      )
      abline(v = hue[i], col = "red")
      abline(h = halfmax[i], col = "red")
      abline(v = Xa[i], col = "red", lty = 2)
      abline(v = Xb[i], col = "red", lty = 2)
      abline(v = lim, col = "lightgrey")
    }
  }

  data.frame(
    id = nms[select], B3 = as.numeric(Bmax), H1 = hue,
    FWHM = Xb - Xa, HWHM.l = hue - Xa, HWHM.r = Xb - hue,
    incl.min = c("Yes", "No")[as.numeric(Bmin > Bmin_all) + 1]
  )
}
