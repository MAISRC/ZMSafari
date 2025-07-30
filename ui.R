ui = fluidPage(
  id = "whole_page",
  
  title = "Zm Safari App", 
  
  tags$html(lang = "en"), 
  
#   ### LOAD IN OUTSIDE FILES ### -----------------------------------------
  
  #LOAD IN OUR STYLE SHEET.
  tags$head(tags$link(
    rel = "stylesheet", 
    type = "text/css",
    href = "ZmSafari.css"
  ),
  

## ### LOAD IN CONTEXT-DEPENDENT JS SCRIPTS ### ----------------------------

  #LOAD IN GOOGLE ANALYTICS SCRIPT, IF USING.
  shiny::tags$head(
    shiny::tags$script(
      src = "https://www.googletagmanager.com/gtag/js?id=G-81GV463XPS", #YOU WILL NEED TO GET ONE OF THESE G-TAGS FROM GOOGLE ANALYTICS
      async = ""
    ),
    shiny::tags$script(
      src = "js/googleanalytics.js" #PLACE THE G-TAG IN THE CODE PROVIDED HERE ALSO.
    )
  ),

#BY DEFAULT, THE LINK DISPLAYED IN THE SHINY DISCONNECT MESSAGE IS EMPTY, WHICH IS BAD FOR SCREEN READERS. THIS CODE INSERTS TEXT THERE--IT SHOULD MATCH WHATEVER THE REFRESH ARGUMENT IS IN THE ACTUAL DISCONNECT CODE
tags$head(
  tags$script(
    src = "js/preventEmptyReloadLink.js"
  )
),

#JS FUNCTION THAT FORCES THE DATE PICKER POPUP THAT COMES ALONG WITH SHINY'S DATE SELECTOR TO BE A BIT ABOVE THE ACCOMPANYING TEXT BOX SO IT DOESN'T COVER UP THE TYPING BOX.
tags$head(
  tags$script(
    src = "js/preventDateInputOverlaps.js"
  )
),
  
# ### ENABLING OPTIONAL FUNCTIONALITY ### ------------------------------------------

#SOME SHINY-AFFILIATED PACKAGES NEED TO HAVE THEIR FEATURES "ENABLED" IN THE UI. I PUT THOSE FUNCTION CALLS HERE. COMMENT OUT OR DELETE IF THE ASSOCIATED PACKAGES AREN'T BEING USED.

waiter::useWaiter(), #NECESSARY TO TURN ON THE WAITER PACKAGE'S FEATURES.
shinyjs::useShinyjs(), #ENABLE SHINYJS


#   ### ADD POLISHING UI ELEMENTS ### -------------------------------------

  #USING THE SHINYDISCONNECT PACKAGE, WE CAN SET A CUSTOM DISCONNECT MESSAGE SO IT'S ABUNDANTLY CLEAR TO USERS THAT THE APP HAS CLOSED (IT'S NOT OBVIOUS OTHERWISE). 
  disconnectMessage(text = "Hmm...something has gone wrong. Either you have been idle for too long and the app has timed out or an error has been triggered in the R code of the application. To try again, refresh the page. If, after doing so, you encounter this page again after taking the same actions as before, please file a bug report with Alex at bajcz003@umn.edu. We appreciate your cooperation!", 
                    refresh = "Refresh the page", 
                    width = "full", 
                    top = "center", 
                    size = 22, 
                    background = "#7a0019", 
                    colour = "white", 
                    refreshColour = "#ffb71e", 
                    css = "z-index: 100000 !important;"),

#USING THE WAITER PACKAGE, WE CAN ADD IN A "PRELOADER WAITER" THAT SITS ON SCREEN WHILE THE APP BOOTS UP, WHICH IS REALLY ONLY NECESSARY IF START-UP TAKES KIND OF A WHILE. 
  waiter::waiter_preloader(
    html = tagList(
      waiter::spin_loaders(6), 
      br(), 
      br(),
      HTML("<em>Welcome to XXX, operated by the Minnesota Aquatic Invasive Species Research Center! Please wait while we gas up the Jeep...</em>"),
      br(),
      br(),
      img(src = "preload.png", alt = "")), #EITHER PROVIDE ALT TEXT OR DESCRIBE ANY IMAGE USED HERE IN THE MAIN TEXT ABOVE.
      color = "#7a0019",
      fadeout = 500,
  )
),


# ### CORE APP UI ELEMENTS ### --------------------------------------------

## ### HEADER, H1, NAV ### -------------------------------------------------

#THE FIRST ELEMENT OF THE PAGE SHOULD PROBABLY BE A HEADER, IF APPLICABLE. 
tags$header(
    class = "flexthis flexcol width100 justifycenter flexwrap",
    #THE TITLE OF THE APP SHOULD BE IN THE HEADER, AND PROBABLY ALSO BEAR THE H1 TAG.
    h1("",
    class = "flexthis flexcol width100 justifycenter flexwrap"), 

                    ), 


## ### MAIN CONTENT/MODULES ### --------------------------------------------


## ### FOOTER ### ----------------------------------------------------------

#Insert a footer with links, contact info, funding credits, and current version number.
tags$footer(
HTML("<br><br>The Zebra Mussel Safari App was designed and is maintained by <address><a href='mailto:bajcz003@umn.edu'>Dr. Alex Bajcz (bajcz003@umn.edu)</a>, staff Quantitative Ecologist for <a href ='https://maisrc.umn.edu/ target = '_blank'>MAISRC</a></address>.<br><br>App last updated August 1st, 2025. Version 1.0.0. <br><br>
                                   Funding for this work was provided by the Minnesota Environment and Natural Resources Trust Fund (ENRTF) as recommended by the Minnesota Aquatic Invasive Species Research Center (MAISRC) and the Legislative-Citizen Commission on Minnesota Resources (LCCMR) and also the State of Minnesota.<br>"), 
                          img(src = "jointlogo.png",
                              alt = "", #THIS ALT TEXT CAN BE EMPTY BECAUSE THE LOGOS ARE FUNCTIONALLY DECORATIVE--THE ESSENTIAL FUNDING INFO IS LISTED IN TEXT ABOVE THEM.
                              ID = "footerLogo")
 )

) #End UI
