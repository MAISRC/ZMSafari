# ### LOADING LIBRARIES ### -----------------------------------------------

#BECAUSE EVERY PACKAGE USED MUST BE INSTALLED ON THE INSTANCE WITH EVERY DEPLOYMENT, WE WANT TO MINIMIZE THE NUMBER OF PACKAGES USED IN TOTAL. HERE ARE THE ONES I GENERALLY CONSIDER TO BE ESSENTIAL. DELETE ANY NOT NEEDED. ADD ANY THAT ARE ESSENTIAL IN YOUR CONTEXT.

library(shiny) #ESSENTIAL.
library(dplyr) #DATA MANIPULATION.
library(stringr) #STRING MANIPULATION.
library(gargle) #GOOGLE DRIVE AUTHETICATION.
library(googledrive) #GOOGLE DRIVE INTERACTIONS.
library(googlesheets4) #GOOGLE SHEETS INTERACTIONS.
library(shinyjs) #COMMON JAVASCRIPT OPERATIONS.
library(waiter) #WAITERS, SPINNERS, AND PRELOADERS.
library(shinydisconnect) #CUSTOM DISCONNECT SCREEN.
library(shinyWidgets) #FOR PICKER INPUTS.
library(shinyvalidate) #FOR FORM VALIDATION.
library(magick) #FOR HANDLING IMAGE THUMBNAIL GENERATION.

# ### SETTING GLOBAL OPTIONS ### ------------------------------------------

#IN GENERAL, I DON'T DO MUCH HERE, BUT I DO SET UP CONNECTIONS TO GOOGLE DRIVE HERE AS NEEDED. REMOVE THESE IF THEY ARE IRRELEVANT TO YOU.

#SET SCOPES FOR WHAT OUR GOOGLE APIS WILL BE ALLOWED TO DO
sheets_scope = "https://www.googleapis.com/auth/spreadsheets"
drive_scope = "https://www.googleapis.com/auth/drive"

#SET FILE PATH TO THE GOOGLE SERVICE ACCOUNT TOKEN
sa_key_path = "tokens/.secrets/zm-safari-652312ebb93c.json"

#DON'T TRY TO AUTHENTICATE USING STANDARD TOKENS.
options(
  gargle_oauth_cache = FALSE,
  shiny.maxRequestSize = (100 * (1024^2)) #OTHERWISE, IT WILL NOT ACCEPT ENOUGH FILES FOR UPLOAD.
  )

#AUTHENTICATE USING OUR JSON TOKEN ATTACHED TO OUR GOOGLE SERVICE ACCOUNT W/ PROPER SCOPES
drive_auth(path = sa_key_path, scopes = c(sheets_scope, drive_scope))

#ALSO AUTHENTICATE TO GOOGLE SHEETS SPECIFICALLY
googlesheets4::gs4_auth(path = sa_key_path, scopes = c(sheets_scope, drive_scope))

#  ### ESTABLISH CONVENIENCE FUNCTIONS ### --------------------------------

source("Rcode/Scripts/shinyConvenienceFunctions.R")
 
# ### LOAD NECESSARY INPUTS ### -------------------------------------------

#I SO REGULARLY NEED TO KNOW THE NAMES/DOWS/COUNTIES OF LAKES IN MN THAT I'VE COMBINED ALL THAT INTO A SINGLE DF, LOADED HERE.
dows_lakenames_counties = read.csv("inputs/Static/dows_lakenames_counties.csv", colClasses = "character")
  dows_lakenames_counties$DOW[nchar(dows_lakenames_counties$DOW) == 7] = 
    paste0("0", dows_lakenames_counties$DOW[nchar(dows_lakenames_counties$DOW) == 7])

  counties_list = sort(unique(dows_lakenames_counties$COUNTY))


#GET LINKS TO KEY OUTSIDE FILES IN THE DRIVE STRUCTURE.
metadata_id = googledrive::drive_get("https://docs.google.com/spreadsheets/d/1R7zZBgKYQbk5VAUOzGDWWtIEvX01yyWuxsMhnSrfBbQ/edit?usp=sharing")$id
submitted_pics_id = googledrive::drive_get("https://drive.google.com/drive/folders/1YTtfdp4oEiYLA7KDMMRkL8SiDtgOsxBb/edit?usp=sharing")$id


# ### PRE-BAKE GLOBAL ENVIRONMENT OBJECTS ### -----------------------------
valid_image_exts = c("jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", 
                     "heic", "heif", "webp", "pdf")

##CREATE FILE PATH FOR THUMBNAIL DIRECTORY
thumb_dir = file.path(tempdir(), "thumbs")
dir.create(thumb_dir, showWarnings = FALSE, recursive = TRUE)
shiny::addResourcePath("thumbs", thumb_dir)

# Optional: helper to check magick codec support (handy for debugging servers)
magick_formats = tryCatch(magick::magick_config()$formats, error = function(e) NULL)
can_read_heic  = isTRUE(any(grepl("\\bHEIC\\b|\\bHEIF\\b", magick_formats, ignore.case = TRUE)))
can_write_webp = isTRUE(any(grepl("\\bWEBP\\b", magick_formats, ignore.case = TRUE)))

##CREATE THUMBNAIL-CREATING CONVENIENCE FUNCTION
# Returns a list:
#   ok         : TRUE/FALSE (thumbnail available?)
#   rel_src    : relative URL like "thumbs/abc.webp" (only if ok == TRUE)
#   width      : intended CSS width for display (you set this)
#   reason     : if ok == FALSE, a short code e.g. "unreadable", "heic_no_libheif"
#   msg        : friendly message for users
make_thumb = function(in_path, 
                      max_px = 1000, 
                      quality = 70,
                      prefer  = c("webp","jpeg"),
                      display_width_px = 310,
                      bg = "white"){
  
  prefer = match.arg(prefer)
  out_ext = if(prefer == "webp" && can_write_webp) { "webp" } else { "jpg" }
  
  # Basic sanity
  if(!nzchar(in_path) || !file.exists(in_path)) {
    return(list(ok = FALSE, rel_src = NULL, width = display_width_px,
                reason = "missing_file",
                msg = "Preview unavailable, but your file uploaded successfully."))
  }
  
  # Read image safely
  img = NULL
  read_err = NULL
  tryCatch({
    # PDFs often look better with explicit density; magick handles others fine.
    if (tolower(tools::file_ext(in_path)) %in% c("pdf")) {
      img = magick::image_read(in_path, density = 144)
    } else {
      img = magick::image_read(in_path)
    }
  }, error = function(e){
    read_err = conditionMessage(e)
  })
  
  if(is.null(img)) {
    # Could not read — likely unsupported (HEIC) or corrupt
    ext = tolower(tools::file_ext(in_path))
    reason = if(ext %in% c("heic","heif")) { "heic_no_libheif" } else { "unreadable" }
    msg = if(reason == "heic_no_libheif") {
      "An image preview for HEIC files is not possible at this time, but your file uploaded successfully."
    } else {
      "An image preview for your file is not possible, but your file uploaded successfully."
    }
    return(list(ok = FALSE, rel_src = NULL, width = display_width_px,
                reason = reason, msg = msg))
  }

  # If it’s multi-frame (gif/pdf), take first frame for the thumb
  if(length(img) > 1) img = img[1]
  
  # Normalize colorspace (reduces weird shifts)
  img = magick::image_convert(img, colorspace = "sRGB")
  
  # Downscale (only if larger than max_px on the long edge)
  img = magick::image_resize(img, paste0(max_px, "x", max_px, ">"))
  
  # If our target format doesn't support alpha (JPEG), flatten onto a solid bg
  # WebP supports alpha, so we keep transparency there.
  if(identical(out_ext, "jpg")) {
    img = magick::image_background(img, bg, flatten = TRUE)
  }
  
  # Build output filename next to the temp thumb_dir
  base = tools::file_path_sans_ext(basename(in_path))
  out = file.path(thumb_dir, paste0(base, ".", out_ext))

  # Write safely: if WebP write fails for any reason, try JPEG
  wrote = TRUE
  tryCatch({
    magick::image_write(img, path = out, format = out_ext, quality = quality)
  }, error = function(e) {
    wrote <<- FALSE
  })
  
  if(!wrote) { #IF WROTE IS FALSE, TRY JPEG FALLBACK
    out_ext_fb = "jpg"
    out_fb = file.path(thumb_dir, paste0(base, ".", out_ext_fb))
    wrote_fb <- TRUE
    tryCatch({
      magick::image_write(img, path = out_fb, format = "jpeg", quality = quality)
    }, error = function(e){
      wrote_fb <<- FALSE
    })
    if (!wrote_fb) {
      return(list(ok = FALSE, rel_src = NULL, width = display_width_px,
                  reason = "write_failed",
                  msg = "Preview unavailable due to server codec limits, but your file uploaded successfully."))
    }
    out = out_fb
  }
  
  rel = file.path("thumbs", basename(out))
  return(list(ok = TRUE, rel_src = rel, width = display_width_px,
       reason = NULL, msg = NULL))
  
}