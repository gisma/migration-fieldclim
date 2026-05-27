#' Minimum Distance between Climate Station and Obstacle
#'
#' Calculates the minimum distance required between a climate station and an obstacle (e.g., forest) to ensure independence of measurements.
#'
#' @rdname pos_min_dist
#' @param ... Additional arguments.
#' @return Minimum distance in meters (m).
#' @details
#' The minimum distance is calculated to ensure that the climate station's measurements are not influenced by nearby obstacles. The calculation varies based on whether the obstacle surrounds the station circularly or is positioned behind the station.
#'
#' Formulas used:
#' - For a circularly surrounded obstacle: \eqn{d_{min} = \pi \cdot r + 10 \cdot h}
#' - For an obstacle behind the station:
#'   - If \eqn{h > w}: \eqn{d_{min} = 0.5 \cdot h + 10 \cdot w}
#'   - If \eqn{h < w}: \eqn{d_{min} = 0.5 \cdot w + 10 \cdot h}
#'   - If \eqn{h \approx w} (within \eqn{±5\%}): \eqn{d_{min} = 5 \cdot (h + w)}
#'
#' @param obs_width Width of the obstacle in meters (m).
#' @param obs_height Height of the obstacle in meters (m).
#' @param ring Logical. If TRUE, the obstacle surrounds the station circularly.
#' @param obs_radius If `ring` is TRUE, radius of the circular obstacle in meters (m).
#' @return Minimum distance between the measurement point and the obstacle for undisturbed measurement in meters (m).
#' @examples
#' # Minimum distance for an obstacle behind the station
#' pos_min_dist(obs_width = 50, obs_height = 30)
#'
#' # Minimum distance for a circularly surrounded obstacle
#' pos_min_dist(obs_width = 50, obs_height = 30, ring = TRUE, obs_radius = 100)
#' @references Bendix 2004, p. 189, eq. 9.1.
#' @export
pos_min_dist <- function(...) {
  UseMethod("pos_min_dist")
}

#' @rdname pos_min_dist
#' @export
pos_min_dist.default <- function(obs_width, obs_height, ring = FALSE, obs_radius = NULL, ...) {
  # if climate station is positioned on a clearing:
  if (ring == TRUE) {
    min_dist <- pi * obs_radius + 10 * obs_height
  } else {
    # check if height > width
    if (obs_height > obs_width) {
      min_dist <- 0.5 * obs_height + 10 * obs_width
    }
    # check if height < width
    else if (obs_height < obs_width) {
      min_dist <- 0.5 * obs_width + 10 * obs_height
    }
    # check if height ~ width (height = width ±5%)
    else if (obs_height <= obs_width * 1.05 && obs_height >= obs_width * 0.95) {
      min_dist <- 5 * (obs_height + obs_width)
    }
  }
  return(min_dist)
}

#' Maximum Distance between Climate Station and Obstacle
#'
#' Checks if the climate station is positioned within the maximum allowable distance from the obstacle.
#'
#' @param dist Distance between the climate station and the obstacle (e.g., forest) in meters (m).
#' @param obs_width Width of the obstacle in meters (m).
#' @param obs_height Height of the obstacle in meters (m).
#' @param ring Logical. If TRUE, the obstacle surrounds the station circularly.
#' @return A message indicating if the climate station is well positioned or if it needs to be moved closer to the obstacle.
#' @details
#' The maximum distance is calculated to ensure that the climate station's measurements are within a reasonable range from the obstacle. If the station is positioned too far, it needs to be moved closer.
#'
#' Formula used:
#' - For a circularly surrounded obstacle: \eqn{d_{max} = 15 \cdot h}
#' - For an obstacle behind the station:
#'   - If \eqn{h > w}: \eqn{d_{max} = 15 \cdot w}
#'   - If \eqn{h < w}: \eqn{d_{max} = 15 \cdot h}
#'
#' @examples
#' # Check maximum distance for an obstacle behind the station
#' pos_max_dist(dist = 500, obs_width = 50, obs_height = 30)
#'
#' # Check maximum distance for a circularly surrounded obstacle
#' pos_max_dist(dist = 500, obs_width = 50, obs_height = 30, ring = TRUE)
#' @references Bendix 2004, p. 189, eq. 9.1.
#' @export
pos_max_dist <- function(dist, obs_width, obs_height, ring = FALSE) {
  if (ring == TRUE) {
    if (dist < 15 * obs_height) {
      return("The climate station is positioned well.")
    } else {
      max_dist <- 15 * obs_height
      return(paste("The climate station is positioned too far from the obstacle. It needs to be placed in a position closer than", max_dist, "m from the obstacle."))
    }
  } else {
    if (obs_height > obs_width) {
      if (dist < 15 * obs_width) {
        return("The climate station is positioned well.")
      } else {
        max_dist <- round(15 * obs_width, 2)
        return(paste("The climate station is positioned too far from the obstacle. It needs to be placed in a position closer than", max_dist, "m from the obstacle."))
      }
    } else if (obs_height < obs_width) {
      if (dist < 15 * obs_height) {
        return("The climate station is positioned well.")
      } else {
        max_dist <- round(15 * obs_height, 2)
        return(paste("The climate station is positioned too far from the obstacle. It needs to be placed in a position closer than", max_dist, "m from the obstacle."))
      }
    }
  }
}

#' Necessary Anemometer Height
#'
#' Checks if the distance between the climate station and the forest is smaller than the minimum distance. If so, calculates the height at which the anemometer needs to be positioned to ensure independent measurements.
#'
#' @param dist Distance between the climate station and the obstacle (e.g., forest) in meters (m).
#' @param min_dist Minimum distance between the climate station and the obstacle required to ensure independent measurements, in meters (m).
#' @param obs_height Height of the obstacle in meters (m).
#' @return A message indicating if the climate station is well positioned or, if not, the height at which the anemometer needs to be positioned.
#' @details
#' If the climate station is positioned closer than the minimum required distance, the anemometer needs to be positioned at a higher altitude to avoid measurement interference.
#'
#' Formula used:
#' \eqn{h_{new} = h \cdot \frac{d_{min} - d}{d_{min}}}
#'
#' @examples
#' # Check anemometer height for a station too close to the obstacle
#' pos_anemometer_height(dist = 50, min_dist = 100, obs_height = 30)
#' @export
pos_anemometer_height <- function(dist, min_dist, obs_height) {
  if (dist >= min_dist) {
    return("The climate station is positioned beyond the needed minimum distance. It is not required to change the height of the anemometer.")
  } else {
    repos <- round(obs_height * (min_dist - dist) / min_dist, 2)
    return(paste("The climate station is positioned too close to the obstacle. The anemometer needs to be repositioned", repos, "m higher."))
  }
}
