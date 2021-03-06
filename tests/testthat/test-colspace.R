library(pavo)
context("colspace")

test_that("Receptor orders/names", {
  data(flowers)

  # dichromat
  di <- sensmodel(c(440, 330))
  names(di) <- c("wl", "l", "s")
  di.vis <- vismodel(flowers, visual = di)
  di.space <- colspace(di.vis)
  expect_equal(di.vis, di.space[, 2:1], check.attributes = FALSE)

  # trichromat
  tri <- sensmodel(c(550, 440, 330))
  names(tri) <- c("wl", "l", "m", "s")
  tri.vis <- vismodel(flowers, visual = tri)
  tri.space <- colspace(tri.vis)
  expect_equal(tri.vis, tri.space[, 3:1], check.attributes = FALSE)

  # tetrachromat
  tetra <- sensmodel(c(660, 550, 440, 330))
  names(tetra) <- c("wl", "l", "m", "s", "u")
  tetra.vis <- vismodel(flowers, visual = tetra)
  tetra.space <- colspace(tetra.vis)
  expect_equal(tetra.vis, tetra.space[, 4:1], check.attributes = FALSE)
  expect_warning({
    sumtcs <- summary(tetra.space, by = 3)
  })
  # expect_equal(digest::sha1(sumtcs, digits = 4), "2a4f6b9dcb757139c3c6d2436d6e2a1d27a2d41d")
})

test_that("Relative quantum catches", {
  data(flowers)

  # dichromat
  di <- sensmodel(c(440, 330))
  names(di) <- c("wl", "l", "s")

  di_vis <- vismodel(flowers, visual = di)
  di_vis_norel <- vismodel(flowers, visual = di, relative = FALSE)
  di_vis_noreldf <- as.data.frame(di_vis_norel)

  expect_warning(colspace(di_vis_norel), "not relative")
  expect_warning(colspace(di_vis_noreldf), "not relative")

  expect_equal(
    suppressWarnings(colspace(di_vis)),
    suppressWarnings(colspace(di_vis_norel))
  )

  # trichromat
  tri <- sensmodel(c(550, 440, 330))
  names(tri) <- c("wl", "l", "m", "s")

  tri_vis <- vismodel(flowers, visual = tri)
  tri_vis_norel <- vismodel(flowers, visual = tri, relative = FALSE)
  tri_vis_noreldf <- as.data.frame(tri_vis_norel)

  expect_warning(colspace(tri_vis_norel), "not relative")
  expect_warning(colspace(tri_vis_noreldf), "not relative")

  expect_equal(
    suppressWarnings(colspace(tri_vis)),
    suppressWarnings(colspace(tri_vis_norel))
  )
})

test_that("Overlap", {
  data(sicalis)
  tcs.sicalis.C <- subset(colspace(vismodel(sicalis)), "C")
  tcs.sicalis.T <- subset(colspace(vismodel(sicalis)), "T")
  tcs.sicalis.B <- subset(colspace(vismodel(sicalis)), "B")

  expect_equivalent(round(sum(voloverlap(tcs.sicalis.T, tcs.sicalis.B)), 5), 0.19728)
  expect_equivalent(round(sum(voloverlap(tcs.sicalis.T, tcs.sicalis.C)), 7), 9.9e-06)
  expect_equivalent(round(sum(voloverlap(tcs.sicalis.T, tcs.sicalis.B, montecarlo = TRUE)[1:2]), 5), 1e-05)
})

test_that("Errors/messages", {
  data(flowers)

  # Categorical
  expect_error(colspace(vismodel(flowers, visual = "apis"), space = "categorical"), "tetrachromatic")
  expect_warning(colspace(vismodel(flowers, visual = sensmodel(c(300, 400, 500, 600, 700))), space = "categorical"), "first four")
  expect_warning(colspace(vismodel(flowers, visual = sensmodel(c(300, 400, 500, 600, 700))), space = "categorical"), "not find")
  expect_warning(colspace(vismodel(flowers, visual = "musca", relative = FALSE), space = "categorical"), "relative")

  vis.flowers <- vismodel(flowers, visual = "musca")
  class(vis.flowers) <- "data.frame"
  expect_warning(colspace(vis.flowers, space = "categorical"), "vismodel")
  # expect_warning(colspace(cbind(vis.flowers, vis.flowers[,3]), space = 'categorical'), 'vismodel')
  # expect_warning(colspace(cbind(vis.flowers, vis.flowers[,3]), space = 'categorical'), 'undefined')
  expect_error(colspace(vis.flowers[1:3], space = "categorical"), "fewer")

  # Segment
  vis.flowers <- vismodel(flowers, visual = "segment")
  names(vis.flowers)[1] <- "Nada"
  expect_warning(colspace(vis.flowers, space = "segment"), "named")
  expect_error(colspace(vismodel(flowers, visual = "apis"), space = "segment"), "tetrachromatic")
  expect_warning(colspace(vismodel(flowers, visual = "segment", relative = FALSE), space = "segment"), "overriding")

  vis.flowers <- vismodel(flowers, visual = "segment")
  class(vis.flowers) <- "data.frame"
  expect_error(colspace(vis.flowers[1:3], space = "segment"), "fewer")
  expect_warning(colspace(vis.flowers, space = "segment"), "vismodel")
  expect_warning(colspace(vis.flowers, space = "segment"), "transformed")

  # Coc
  expect_error(colspace(vismodel(flowers, visual = "canis"), space = "coc"), "trichromatic")
  fak <- sensmodel(c(300, 400, 500, 600))
  expect_warning(colspace(vismodel(flowers, visual = fak, relative = FALSE, qcatch = "Ei", vonkries = TRUE), space = "coc"), "first")
  expect_warning(colspace(vismodel(flowers, visual = fak, relative = FALSE, qcatch = "Ei", vonkries = TRUE), space = "coc"), "trichromatic")
  expect_error(colspace(vismodel(flowers, visual = "apis", relative = TRUE, qcatch = "Ei", vonkries = TRUE), space = "coc"), "relative")
  expect_error(colspace(vismodel(flowers, visual = "apis", relative = FALSE, qcatch = "Qi", vonkries = TRUE), space = "coc"), "hyperbolically")
  expect_error(colspace(vismodel(flowers, visual = "apis", relative = FALSE, qcatch = "Ei", vonkries = FALSE), space = "coc"), "von-Kries")

  vis.flowers <- vismodel(flowers, visual = "apis", relative = FALSE, qcatch = "Ei", vonkries = TRUE)
  class(vis.flowers) <- "data.frame"

  expect_error(colspace(vis.flowers[1:2], space = "coc"), "fewer than three")
  expect_warning(colspace(vis.flowers, space = "coc"), "treating columns as")
  expect_warning(colspace(cbind(vis.flowers, vis.flowers[, 2]), space = "coc"), "has more than three")

  vis.flowers <- vismodel(flowers, visual = "apis", relative = TRUE, qcatch = "Ei", vonkries = TRUE)
  class(vis.flowers) <- "data.frame"
  expect_error(colspace(vis.flowers, space = "coc"), "relative")

  # Hexagon
  expect_error(colspace(vismodel(flowers, visual = "canis"), space = "hexagon"), "trichromatic")
  fak <- sensmodel(c(300, 400, 500, 600))
  expect_error(colspace(vismodel(flowers, visual = "apis", relative = TRUE), space = "hexagon"), "relative")
  expect_warning(colspace(vismodel(flowers, visual = fak, relative = FALSE), space = "hexagon"), "first three")
  expect_warning(colspace(vismodel(flowers, visual = "apis", relative = FALSE, vonkries = FALSE), space = "hexagon"), "hyperbolically")
  expect_warning(colspace(vismodel(flowers, visual = "apis", relative = FALSE, vonkries = FALSE), space = "hexagon"), "von-Kries")

  vis.flowers <- vismodel(flowers, visual = "apis", relative = FALSE, qcatch = "Ei", vonkries = TRUE)
  class(vis.flowers) <- "data.frame"
  names(vis.flowers)[1] <- "a"

  expect_error(colspace(vis.flowers[1:2], space = "hexagon"), "fewer than three")
  expect_warning(colspace(vis.flowers, space = "hexagon"), "treating columns as")
  expect_warning(colspace(cbind(vis.flowers, vis.flowers[, 2]), space = "hexagon"), "has more than three")

  vis.flowers <- vismodel(flowers, visual = "apis", relative = TRUE, qcatch = "Ei", vonkries = TRUE)
  class(vis.flowers) <- "data.frame"
  expect_error(colspace(vis.flowers, space = "hexagon"), "relative")
})

test_that("Output regression", {
  library(digest)
  data(flowers)

  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "canis", achromatic = "all")), digits = 4), "786b890b13c01c79f545acea59e04597f4757ddd") # dispace
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "apis", achromatic = "l")), digits = 4), "b6e9903af99aa8b6dab9aa6e8e5e5954a6f16bb1") # trispace
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "bluetit", achromatic = "ch.dc")), digits = 4), "f7b2fdc06e9e3d6597011aa05a654a79b306c03e") # tcs
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "musca", achro = "md.r1"), space = "categorical"), digits = 4), "5defb10dbb4f988431a2e706025aa613448220ec") # categorical
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "segment", achromatic = "bt.dc"), space = "segment"), digits = 4), "5b6a96fac5140f9109ab4cee6ad96e8ff6beecb1") # segment
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "apis", relative = FALSE, qcatch = "Ei", vonkries = TRUE, achromatic = "l"), space = "coc"), digits = 4), "2c2afbdc41577ba095cf6879cfac157315a65afe") # coc
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "apis", qcatch = "Ei", vonkries = TRUE, relative = FALSE, achromatic = "l"), space = "hexagon"), digits = 4), "20ce621deff5b1bf62134f585daaf9941af631eb") # hexagon
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "cie10"), space = "ciexyz"), digits = 4), "ab8b1f06949fc1f5ee5263c557f317a33b66515e") # ciexyz
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "cie10"), space = "cielab"), digits = 4), "21bfa24aadddb421c1af706b75042fd6703f5610") # cielab
  expect_equal(digest::sha1(colspace(vismodel(flowers, visual = "cie10"), space = "cielch"), digits = 4), "395817a5a0a2d5a3469c39595787738020e66f57") # cielch

  expect_equal(digest::sha1(summary(colspace(vismodel(flowers, visual = "cie10"), space = "cielch")), digits = 4), "8d9c05ec7ae28b219c4c56edbce6a721bd68af82")
  expect_equivalent(round(sum(summary(colspace(vismodel(flowers)))), 5), 4.08984)
  expect_equivalent(round(sum(summary(colspace(vismodel(flowers))), by = 3), 5), 7.08984)
})
