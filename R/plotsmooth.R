#' Plot loess smoothed curves
#'
#' Plots spectral curves with various levels of loess smoothing to help decide which
#' loess parameters are best for subsequently smoothing the data (e.g. via \code{procspec}).
#'
#' @param rspecdata (required) a data frame, possibly of class \code{rspec}, which
#' contains a column containing a wavelength range , named 'wl', and spectra data in
#' remaining columns.
#' @param minsmooth the minimum f value of the loess function to visualize (defaults to \code{0.05}).
#' @param maxsmooth the maximum f value of the loess function to visualize (defaults to \code{0.20}).
#' @param curves the number of curves to display on the same plot (defaults to \code{5}).
#' @param specnum the number of spectral curves, from the data frame, to visualize (defaults to \code{ALL}).
#' @param ask logical. if \code{TRUE}, asks for user input before changing plot pages
#'
#' @return Series of plot with curves processed with varying level of loess smoothing
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(sicalis)
#' plotsmooth(sicalis, minsmooth = 0.05, maxsmooth = 0.1, curves = 7, specnum = 6)
#' }
#' 
#' @author Pierre-Paul Bitton \email{bittonp@@uwindsor.ca}

plotsmooth <- function(rspecdata, minsmooth = 0.05, maxsmooth = 0.20,
                       curves = 5, specnum = 0, ask = TRUE) {
  oPar <- par("mfrow", "ask", "mar", "oma")
  on.exit(par(oPar))

  curves <- curves + 1

  titlenames <- names(rspecdata[, 2:dim(rspecdata)[2]])

  if (specnum == 1) {
    titlenames <- titlenames [2]
    rspecdata <- rspecdata[, seq_len(specnum + 1)]
  }

  if (specnum > 1) {
    rspecdata <- rspecdata[, seq_len(specnum + 1)]
    titlenames <- titlenames[2:dim(rspecdata)[2]]
  }

  wl_index <- which(names(rspecdata) == "wl")
  wl <- rspecdata[, wl_index]

  nplots <- ncol(rspecdata) - 1

  plotdata <- matrix(nrow = dim(rspecdata)[1], ncol = nplots * curves)

  legnames <- as.character(seq(minsmooth, maxsmooth, by = (maxsmooth - minsmooth) / (curves - 2)))
  legnames <- sprintf("%.4s", legnames)
  legnames <- paste("span = ", legnames, sep = "")
  legnames <- rev(c("raw", legnames))

  # Creates the smooth data matrix

  inc <- (maxsmooth - minsmooth) / (curves - 2)

  for (i in seq_len(nplots)) {
    plotdata[, ((i - 1) * curves) + 1] <- rspecdata[, i + 1]

    plotdata[, ((i - 1) * curves) + 2] <-

      loess.smooth(wl, rspecdata [, i + 1],
        span = minsmooth,
        evaluation = length(wl), degree = 2, family = "gaussian"
      )$y + 5

    plotdata[, ((i - 1) * curves) + curves] <-
      loess.smooth(wl, rspecdata [, i + 1],
        span = maxsmooth,
        evaluation = length(wl), degree = 2, family = "gaussian"
      )$y + ((curves - 1) * 5)

    for (j in seq_len(curves - 3)) {
      plotdata[, ((i - 1) * curves) + 2 + j] <-
        loess.smooth(wl, rspecdata [, i + 1],
          span = (minsmooth + (inc * j)),
          evaluation = length(wl), degree = 2, family = "gaussian"
        )$y + (10 + ((j - 1) * 5))
    }
  }

  # Sets plot parameters based on the number of curves on the plots
  par(mfrow = c(3, 4), ask = ask)
  numplots <- 12

  if (curves > 4) {
    par(mfrow = c(2, 3))
    numplots <- 6
  }
  if (curves > 7) {
    par(mfrow = c(2, 2))
    numplots <- 4
  }
  if (curves > 9) {
    par(mfrow = c(1, 2))
    numplots <- 2
  }
  if (curves > 12) {
    par(mfrow = c(1, 1))
    numplots <- 1
  }

  if (nplots == 1) {
    par(mfrow = c(1, 1))
    numplots <- 1
    par(ask = FALSE)
  }

  # Plots all curves
  # all below does not work yet

  par(mar = c(2, 2, 2, 2), oma = c(3, 3, 0, 0))

  col_list <- c(
    "#000000", "#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
    "#FF7F00", "#ffdd33", "#A65628", "#F781BF"
  )

  for (i in seq_len(nplots)) {
    bloc <- plotdata[, (((i - 1) * curves) + 1):(i * curves)]
    cols <- col_list[1:curves]

    yaxismin <- min(bloc)
    yaxismax <- max(bloc)

    plot(rspecdata[, 1], bloc[, 1], cex = 0.1, ylim = c(yaxismin, yaxismax + 5), xlab = "Wavelength (nm)", ylab = "% Reflectance")
    legend(rspecdata[1, 1] - 20, yaxismax + 6, legend = legnames, text.col = rev(cols), cex = 0.7, bty = "n", xjust = 0)
    title(titlenames[i])

    if (i %% numplots == 0) {
      mtext("Wavelength (nm)", side = 1, outer = TRUE, line = 1)
      mtext("Reflectance (%)", side = 2, outer = TRUE, line = 1)
    }

    nextplot <- 2
    while (nextplot < ncol(bloc) + 1) {
      lines(rspecdata[, 1], bloc[, nextplot], cex = 0.1, col = cols[nextplot])
      nextplot <- nextplot + 1
    }
  }

  if (i %% numplots != 0) {
    mtext("Wavelength (nm)", side = 1, outer = TRUE, line = 1)
    mtext("Reflectance (%)", side = 2, outer = TRUE, line = 1)
  }
}
