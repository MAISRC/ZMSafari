# ### LOADING LIBRARIES ### -----------------------------------------------

#BECAUSE EVERY PACKAGE USED MUST BE INSTALLED ON THE INSTANCE WITH EVERY DEPLOYMENT, WE WANT TO MINIMIZE THE NUMBER OF PACKAGES USED IN TOTAL. HERE ARE THE ONES I GENERALLY CONSIDER TO BE ESSENTIAL. DELETE ANY NOT NEEDED. ADD ANY THAT ARE ESSENTIAL IN YOUR CONTEXT.

library(shiny) #ESSENTIAL.
library(dplyr) #DATA MANIPULATION.
library(gargle) #GOOGLE DRIVE AUTHETICATION.
library(googledrive) #GOOGLE DRIVE INTERACTIONS.
library(googlesheets4) #GOOGLE SHEETS INTERACTIONS.
library(shinyjs) #COMMON JAVASCRIPT OPERATIONS.
library(waiter) #WAITERS, SPINNERS, AND PRELOADERS.
library(shinydisconnect) #CUSTOM DISCONNECT SCREEN.

# ### SETTING GLOBAL OPTIONS ### ------------------------------------------

#IN GENERAL, I DON'T DO MUCH HERE, BUT I DO SET UP CONNECTIONS TO GOOGLE DRIVE HERE AS NEEDED. REMOVE THESE IF THEY ARE IRRELEVANT TO YOU.

#SET SCOPES FOR WHAT OUR GOOGLE APIS WILL BE ALLOWED TO DO
sheets_scope = "https://www.googleapis.com/auth/spreadsheets"
drive_scope = "https://www.googleapis.com/auth/drive"

#SET FILE PATH TO THE GOOGLE SERVICE ACCOUNT TOKEN
sa_key_path = "tokens/.secrets/zm-safari-652312ebb93c.json"

#DON'T TRY TO AUTHENTICATE USING STANDARD TOKENS.
options(
  gargle_oauth_cache = FALSE
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

#AN OUTLINE OF THE STATE OF MINNESOTA FOR MAPS.
MN = readRDS("inputs/Static/MN") 

#GET LINKS TO KEY OUTSIDE FILES IN THE DRIVE STRUCTURE.
metadata_id = googledrive::drive_get("https://docs.google.com/spreadsheets/d/1Tz58-rYss9Rq0vG_ac6MQr4LfMwN4SJ3fpxOZqNSCGE")$id
submitted_pics_id = googledrive::drive_get("https://drive.google.com/drive/folders/1U9apDRatN-Ab9qif4uOxc0ywRYy-aMCu")$id


# ### PRE-BAKE GLOBAL ENVIRONMENT OBJECTS ### -----------------------------
