## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Définition de fonction supplémentaire pour exécuter les scripts
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-08-31
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
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
  
  sp_id = get_inat_taxon_id(sp_check)$id
  tryCatch(
    {
      sp_obs_tab_cc0 = get_inat_obs(
        taxon_name  = sp_check, 
        taxon_id = sp_id,
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

#' Extract Taxon ID from scientific name (iNaturalist API)
#'
#' @param scientific_name Character. The genus and species epithet name.
#' 
#' @description
#' Queries the iNaturalist API (v1) to retrieve the unique Taxon ID and 
#' the official web URL for a given species name. 
#'
#' @details 
#' The function performs an exact match filter on the results first. If no exact 
#' match is found in the API response, it defaults to the first result returned 
#' by the iNaturalist search relevance ranking.
#' 
#' @returns 
#' A list containing `id` (numeric) and `url` (character), or 
#' `NA` if no results are found.
#' 
#' @export
#' @importFrom httr GET
#' @importFrom jsonlite fromJSON
#' 
#' @examples
#' get_inat_taxon_id(scientific_name = "Poecile atricapillus")
get_inat_taxon_id <- function(scientific_name) {
  # Ensure necessary packages are loaded
  if (!requireNamespace("httr", quietly = TRUE)) stop("Package 'httr' needed.")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' needed.")
  
  url <- sprintf("https://api.inaturalist.org/v1/taxa?q=%s%s%s%s", 
                 URLencode(scientific_name), 
                 "&rank=species",
                 "&per_page=200", 
                 "&is_active=true")
  
  res <- httr::GET(url)
  data <- jsonlite::fromJSON(rawToChar(res$content))
  
  if (length(data$results) > 0) {
    # Match the exact scientific name to avoid synonyms/homonyms
    match <- data$results[data$results$name == scientific_name, ]
    if (nrow(match) > 0) {
      return(
        list(
          obs_cnt = match$observations_count, 
          name_comm = match$preferred_common_name, 
          name_sci = match$name, 
          id = match$id[1], 
          url = sprintf("https://www.inaturalist.org/taxa/%s", match$id[1]),
          photo_lic = match$default_photo$license_code,
          photo_att = match$default_photo$attribution,
          photo_att_nname = match$default_photo$attribution_name,
          photo_url = match$default_photo$medium_url,
          wiki_url = match$wikipedia_url
        )
      )
    } else {
      no_exact_match = data$results # Fallback to first result
      return(
        
        list(
          obs_cnt = no_exact_match$observations_count, 
          name_comm = no_exact_match$preferred_common_name, 
          name_sci = no_exact_match$name, 
          id = no_exact_match$id[1], 
          url = sprintf("https://www.inaturalist.org/taxa/%s", no_exact_match$id),
          photo_lic = no_exact_match$default_photo$license_code,
          photo_att = no_exact_match$default_photo$attribution,
          photo_att_nname = no_exact_match$default_photo$attribution_name,
          photo_url = no_exact_match$default_photo$medium_url,
          wiki_url = no_exact_match$wikipedia_url
        )
      ) 
    }
  }
  return(NA)
}


#' Get the French common name of a taxon from iNaturalist
#' @param taxon_id Integer. The iNaturalist taxon ID.
#' @returns Character. The French name, or NA if not found.
#' @export
#' @importFrom httr GET content stop_for_status
#' @importFrom jsonlite fromJSON
#' @examples
#' get_french_name(522193) # Orignal
#' get_french_name(64968) # Crapaud
get_french_name <- function(taxon_id) {
  if (!requireNamespace("httr",     quietly = TRUE)) stop("Package 'httr' needed.")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' needed.")
  
  url <- paste0(
    "https://www.inaturalist.org/taxon_names.json?taxon_id=", 
    taxon_id, 
    "&per_page=200" )
  
  res <- httr::GET(
    url,
    httr::add_headers("Accept" = "application/json")
  )
  
  # Check for the 429 status code specifically
  if (status_code(res) == 429) {
    # Extract the Retry-After header
    wait_time <- httr::headers(res)$`retry-after`
    
    if (!is.null(wait_time)) {
      stop(paste("Too Many Requests. Please try again after", wait_time, "seconds."))
    } else {
      stop("Too Many Requests. Rate limit exceeded, but no retry time provided.")
    }
  }
  
  # Error handling 
  httr::stop_for_status(res)
  
  parsed <- jsonlite::fromJSON(
    httr::content(res, as = "text", encoding = "UTF-8"),
    simplifyDataFrame = TRUE
  )
  
  # parsed is a data frame with columns: name, lexicon, ...
  fr <- parsed[tolower(parsed$lexicon) == "french", "name"]
  
  if (length(fr) == 0 || all(is.na(fr))) {
    return(NA)
  } else {
    return(paste0(fr, collapse = ";"))  
  }
}


#' Try to get data from API 
#'
#' @param taxon taxon ID (iNaturalist)
#' @param wait Number of seconds to wait 
#'
#' @returns
#' A list of French species names. 
#' @export
#'
#' @examples
readTaxonFR <- function(taxon, wait) {
  success <- FALSE
  fr_names <- NULL
  
  # Retry if there is an error 
  while (!success) {
    fr_names <- tryCatch(
      {
        # Utilisation de l'API d'iNaturalist 
        # pour prendre les noms français des pages d'espèces 
        # e.g., https://www.inaturalist.org/taxa/43794-Castor-canadensis
        res <- get_french_name(taxon_id = taxon)
        success <- TRUE  # If we reach here, it worked
        res
      },
      error = function(cond) {
        # Report the error and wait before the next loop iteration
        message(paste("Error detected:", conditionMessage(cond)))
        message(sprintf("Waiting %s seconds before retrying...", wait))
        Sys.sleep(time = wait)
        return(NULL) # Keeps success as FALSE
      } # Error 
    )
  } # end while 
  
  # Print message 
  message(sprintf("%s", fr_names))
  # Return value 
  return(fr_names)
}

#' Get taxon information from iNaturalist 
#'
#' @param taxon 
#' @param wait 
#'
#' @returns
#' @export
#'
#' @examples
getTaxonInfo <- function(taxon, wait) {
  success <- FALSE
  sptmp <- NULL
  
  # Retry if there is an error 
  while (!success) {
    sptmp <- tryCatch(
      {
        # Utilisation de l'API d'iNaturalist 
        # pour prendre les noms français des pages d'espèces 
        # e.g., https://www.inaturalist.org/taxa/43794-Castor-canadensis
        res <- get_inat_taxon_id(scientific_name = taxon)
        success <- TRUE  # If we reach here, it worked
        res
      },
      error = function(cond) {
        # Report the error and wait before the next loop iteration
        message(paste("Error detected:", conditionMessage(cond)))
        message(sprintf("Waiting %s seconds before retrying...", wait))
        Sys.sleep(time = wait)
        return(NULL) # Keeps success as FALSE
      } # Error 
    )
  } # end while 
  
  # Return value 
  return(sptmp)
}



#' Convertir CRS des points (spatiaux) x et y
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