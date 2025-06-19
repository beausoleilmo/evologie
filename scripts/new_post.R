# Nouvelle publication blogue
# Gabarit : https://github.com/AlbertRapp/quarto_bottomup_blog/blob/master/posts/new/new_post.qmd 
# Guide : 
# https://albert-rapp.de/posts/13_quarto_blog_writing_guide/13_quarto_blog_writing_guide.html#initialize-your-blog

# À faire
# En fait ça devrait être dossier = NULL et billet (obligatoire). Le nom du billet devrait être le nom du dossier. 

#' Faire un nouveau billet et son dossier
#'
#' @param dossier Character. Nom du dossier pour le billet 
#' @param date Character. Date d'ouverture ou de publication du billet (format = "%Y_%m_%d")
#' @param billet Character. Nom du billet qui sera le nom du ficher 
#' @param dir.base Character. Structure de dossier (chemin d'accès)
#' @param ... Autres arguments à passer à la fonction `entete_qmd()`
#'
#' @description Permet de faire un nouveau dossier (avec nom 'X') *et* un 'billet' si non NULL (avec nom 'Y')
#'
#' @return La commande est faite par l'ordinateur automatiquement. Ne retourne rien. 
#' @export
#'
#' @examples blg_post(dossier = 'GBIF_bias_Qc', billet = 'spatial_gbif')
blg_post <- function(dossier, 
                     date = NULL, 
                     billet = NULL, 
                     ...,
                     dir.base = 'posts') {
  # Si date = NULL, prendre date actuelle
  if (is.null(date)) {
    date = format(Sys.time(), format = "%Y_%m_%d")
  } 
  # Dossier des articles
  
  dir.b = gsub("/$", "", dir.base) # Retire le dernier '/'
  
  # Chemin vers nouveau dossier 
  nouveau_dossier = file.path(dir.b, 
                              paste(date, dossier, sep = '_'))
  
  # Nouveau dossier
  dir.create(path = nouveau_dossier, 
             showWarnings = FALSE)
  
  # Si le billet n'est pas null, faire le dossier avec date et le nom du 'billet' 
  if (!is.null(billet)) {
    entete_qmd(fichier = billet, 
            dossier = nouveau_dossier, 
            date = date, 
            ...)
  }
# return(NULL)
}


#' Squelette YAML et mettre dans fichier gabarit 
#'
#' @param fichier Character. Nom fichier qui est le nom du billet 
#' @param dossier Character. Nom du dossier parent 
#' @param date Character. Date d'ouverture ou de publication du billet
#' @param titre Character. Titre du billet. 
#'
#' @description Permet de faire un nouveau ficher avec titre 'dossier' 
#' 
#' @return Cette fonction est utile avec blg_post
#' @export
#'
#' @examples 
entete_qmd = function(fichier, dossier, date, 
                      # auteur = NULL, # Character. Nom de l'auteur
                      titre = 'Billet avec code') {
  
  # YAML du quarto et ajout de section (code)
  blg_init <- c(
    '---',
    sprintf(fmt = 'title: "%s"', titre),
    'description: ""', # Soustitre 
    'bibliography: ../ref_blg.bib', # bib
    'csl: ../evolution.csl', # reference style  
    # sprintf(fmt = 'author: "%s"', auteur),
    sprintf(fmt = 'date: "%s"', gsub(pattern = '_', replacement = '-', x = date)),
    'categories: ["analysis"]',
    'image: "https://marcolivierbeausoleil.wordpress.com/wp-content/uploads/2015/07/cropped-imgp81461.jpg"',
    'execute: ',
    '  message: false',
    '  warning: false',
    'editor_options: ',
    '  chunk_output_type: console',
    '---',
    '',
    '## Titre de section',
    '',
    '```{r}',
    '',
    '```',
    '',
    '### Références',
    '',
    '::: {#refs}',
    ':::'
  )
  
  # Nom du ficher 
  nom_fichier = file.path(gsub("/$", "", dossier), # Retire le dernier '/'
                          paste0(fichier, '.qmd'))
  # Test si le fichier existe 
  fichier_existe = file.exists(nom_fichier)
  
  # Si n'existe pas, va faire le fichier 
  if (!fichier_existe) {
    message(sprintf('Votre prochaine aventure débute ici... %s', nom_fichier))
    # Ouvrir un fichier 
    fd <- file(nom_fichier, open = "wt")
    # exporte fichier .qmd 
    writeLines(text = blg_init, 
               con = fd)
    # Ferme le fichier 
    close(fd)  
  } else {
    message(sprintf('Ce billet existe... continuez votre aventure ici : %s.', nom_fichier))
  }
}

# blg_post(dossier = 'le_mot_en_E', billet = 'mot_en_E') # Maintenant le tapis de l'évolution 
blg_post(dossier = 'picbois', billet = 'le_pic-bois')
blg_post(dossier = 'GBIF_bias_Qc', billet = 'spatial_gbif')
blg_post(dossier = 'laChasseAuCanard', billet = 'Chasse_Au_Canard')
blg_post(dossier = 'Guide_Visuel_chant', billet = 'Guide_Visuel_chant')
blg_post(dossier = 'Guide_biodiv_qc', billet = 'Guide_biodiv_qc')
blg_post(dossier = 'test', billet = 'test', dir.base = '.InCubateur/')

