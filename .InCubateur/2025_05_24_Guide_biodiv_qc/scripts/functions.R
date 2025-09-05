## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Définition de fonction supplémentaire pour exécuter les scripts
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-08-31
# auteur: Marc-Olivier Beausoleil

#### ____________####
#### Lisez-moi --------
#   --> Fonctions pour extraire les photos de iNaturalist et pour obtenir que les photos de certaines licences

# https://stackoverflow.com/questions/9543343/plot-a-jpg-image-using-base-graphics-in-r
#' Download image and plot it  
#'
#' @param path URL of an iNaturalist image
#' @param plot logical. TRUE will plot the image 
#' @param ... Other arguments passed to `plot()`
#'
#' @description
#' Downloads an image from a URL (e.g., rinat jpeg URL) and plot it. 
#'
#' @returns
#' @export
#'
#' @examples
get_jpeg = function(path, plot=TRUE, ...)
{
  tmp_f = base::tempfile(pattern = 'image_inat', fileext = '.jpg')
  utils::download.file(url = path, destfile = tmp_f) 
  
  # Add plot if plot==TRUE
  if (plot) {
    require('jpeg')
    jpg = jpeg::readJPEG(tmp_f, native=T) # read the file
    res = dim(jpg)[2:1] # get the resolution, [x, y]
    plot(1,1,xlim=c(1,res[1]),ylim=c(1,res[2]),
         asp=1,type='n',xaxs='i',yaxs='i',xaxt='n',
         yaxt='n',xlab='',ylab='',bty='n', ...)
    graphics::rasterImage(jpg,1,1,res[1],res[2])
  }
}

#' Title
#'
#' @param sp_check Species name to get observations 
#' @param ... Other arguments passed to `rinat::get_inat_obs()`
#'
#' @description
#' Function tries to get iNaturalist observations. If there is an error, will not fail the script. 
#'
#' @returns
#' @export
#'
#' @examples
iNatTry <- function(sp_check, ...) {
  require(rinat)
  tryCatch(
    {
      sp_obs_tab_cc0 = get_inat_obs(taxon_name  = sp_check, 
                                    ...
      )
    },
    error = function(cond) {
      message(conditionMessage(cond))
      sp_check
    },
    finally = {
      message(paste("Processed Species:", sp_check))
    }
  )
}


#' Fonction pour convertir des points x et y 
#'
#' @param x longitude
#' @param y latitude
#' @param crs_from crs original
#' @param crs_to crs final 
#'
#' @description Transforme les valeurs longitude et latitude d'un CRS vers un autre CRS
#' @returns
#' @export
#'
#' @examples
xy_convert <- function(x, y, crs_from = 4326, crs_to) {
  pts = st_point(x = c(x, y)) |> 
    st_sfc( crs = crs) |> 
    st_transform(st_crs(trans)) |> 
    st_coordinates()
  return(pts)
}