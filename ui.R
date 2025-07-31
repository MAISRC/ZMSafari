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
  )),
  

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

#WE EXTEND SHINYJS'S FUNCTION CATALOGUE BY ADDING IN THREE NEW ONES TO CONTROL THE SUBMISSIONS PROGRESS OVERLAY.
shinyjs::extendShinyjs(
  text = "
    shinyjs.updateProgress = function(params) {
      const value = params.value;
      const label = params.label;
      document.getElementById('custom_progress_bar').value = value;
      document.getElementById('progress_status_text').innerText = label;
      document.getElementById('aria_status').innerText = label;
    };

    shinyjs.showProgressOverlay = function() {
      const overlay = document.getElementById('custom_progress_overlay');
      overlay.style.display = 'flex';
      overlay.style.opacity = 0;
      $(overlay).animate({ opacity: 1 }, 200);
    };

    shinyjs.hideProgressOverlay = function() {
      const overlay = document.getElementById('custom_progress_overlay');
      $(overlay).animate({ opacity: 0 }, 200, function() {
        overlay.style.display = 'none';
      });
    };
  ",
  functions = c("updateProgress", "showProgressOverlay", "hideProgressOverlay")
),


#   ### ADD POLISHING UI ELEMENTS ### -------------------------------------

  #USING THE SHINYDISCONNECT PACKAGE, WE CAN SET A CUSTOM DISCONNECT MESSAGE SO IT'S ABUNDANTLY CLEAR TO USERS THAT THE APP HAS CLOSED (IT'S NOT OBVIOUS OTHERWISE). 
  disconnectMessage(
    text = HTML(
        "Hmm...something has gone wrong. Either you have been idle for too long and the app has timed out or an error has been triggered in the R code of the application. To try again, refresh the page. If this happens again, please file a bug report with Alex at <a href='mailto:bajcz003@umn.edu'>bajcz003@umn.edu</a>. We appreciate your cooperation!"
    ),
                    refresh = "Refresh the page", 
                    width = "full", 
                    top = "center", 
                    size = 22, 
                    background = "#7a0019", 
                    colour = "white", 
                    refreshColour = "#ffb71e", 
                    css = "z-index: 100000 !important;"),

#USING THE WAITER PACKAGE, WE CAN ADD IN A "PRELOADER WAITER" THAT SITS ON SCREEN WHILE THE APP BOOTS UP, WHICH IS REALLY ONLY NECESSARY IF START-UP TAKES KIND OF A WHILE. 
  # waiter::waiter_preloader(
  #   html = tagList(
  #     waiter::spin_loaders(6),
  #     br(),
  #     br(),
  #     HTML("<em>Welcome to the Zebra Mussel Safari App, operated by the Minnesota Aquatic Invasive Species Research Center! Please wait while we gas up the Jeep...</em>"),
  #     br(),
  #     br(),
  #     img(src = "preload.png", alt = "")), #EITHER PROVIDE ALT TEXT OR DESCRIBE ANY IMAGE USED HERE IN THE MAIN TEXT ABOVE.
  #     color = "#7a0019",
  #     fadeout = 500,
  # ),


# ### CORE APP UI ELEMENTS ### --------------------------------------------

## ### HEADER, H1, NAV ### -------------------------------------------------

#THE FIRST ELEMENT OF THE PAGE SHOULD PROBABLY BE A HEADER, IF APPLICABLE. 
tags$header(
    class = "flexthis flexcol width100 justifycenter flexwrap",
    #THE TITLE OF THE APP SHOULD BE IN THE HEADER, AND PROBABLY ALSO BEAR THE H1 TAG.
    h1("Zebra Mussel Safari Photo Submissions App!"),
    h2("New logo goes here."),
    class = "flexthis flexcol width100 justifycenter flexwrap"), 

## ### MAIN CONTENT/MODULES ### --------------------------------------------

tags$main(
  tags$p(HTML("This is the photo submission page for the Zebra Mussel Safari program, managed by AIS Detectors and MAISRC at the University of Minnesota!<br><br>Please fill out the form below once for each sampler you are submitting photos for. Note: When you select picture files to upload, you must select exactly six files (all those from the same sampler)! If you are having trouble doing this on your device, please let us know.<br><br>After you\'ve uploaded your files, click the 'Submit' button, which will be enabled assuming you have filled out the form completely and adequately. The submission process will begin and a progress bar will display. After submission, you will get a notification indicating submission was successful. Submission will then be locked--reload the page to be able to submit again.")),
  
  tags$form(
    
    ##Inputs regions
    
    tags$fieldset(
      tags$legend(
        h3("Submitter info")
        ),
    textInput(inputId = "collector_name",
              label = "Full name (First Last)",
              value = "",
    ),
    textInput(inputId = "collector_email",
              label = "Your full email address (XX@YY.ZZ)",
              value = "", 
     ),
    textInput("collector_address", 
              "Street address where sampler was deployed (123 Elm St)",
              value = ""
    )
    ), #END SUBMITTER INFO FIELDSET
    
    tags$fieldset(
      tags$legend(
        h3("Submission details")
        ),
      
    dateInput(inputId = "collection_date", 
              label = "Date sampler plates photos were taken (yyyy-mm-dd)", 
              value = NULL, 
              min = "2025-07-31",
              startview = "month",
              weekstart = "1", 
              autoclose = TRUE
    ),
    
    fixDateInputLabel("collection_date"),
    
    pickerInput(inputId = "collector_county", 
                label = "Your lake's county",
                multiple = FALSE,
                choices = c("No selection", counties_list),
                selected = "No selection",
                options = list(
                  liveSearch = TRUE,
                  liveSearchStyle = "startsWith",
                  mobile = TRUE
                  )
    ),
    
    stripPickerDuplicateTitles("collector_county"),
    suppressNativeSelectAccessibility("collector_county"),
    
    pickerInput(inputId = "collector_lake", 
                label = HTML("Your lake's name and DOW # (if you don't know the DOW number, use <a href = https://maps1.dnr.state.mn.us/lakefinder/mobile/#search target = '_blank' >Lakefinder</a> to retrieve it)"),
                multiple = FALSE,
                choices = c("Select a county first!"),
                selected = "Select a county first!",
                options = list(
                  liveSearch = TRUE,
                  liveSearchStyle = "startsWith",
                  mobile = TRUE,
                  virtualScroll = TRUE
                )
    ),
    stripPickerDuplicateTitles("collector_lake"),
    suppressNativeSelectAccessibility("collector_lake")
    
    ), #END SUBMISSION SPECIFICS FIELDSET
    
    tags$fieldset(
      tags$legend(
        h3("Photo uploads")
      ),
      
    fileInput(inputId = "submitted_files",
              label = "Upload photos of your sampler here. You should select exactly six image files: three pictures of top surfaces of plates and three pictures of bottom surfaces. They can be selected in any order.",
              multiple = TRUE, 
              accept = "image/*", 
              buttonLabel = "Select files"
    ),
    
    suppressFileInputFauxTextbox("submitted_files"),
    
    div(id = "submitted_photos_div", #WHERE WE'LL DROP THUMBNAILS AND SELECTORS FOR EACH SUBMITTED PHOTO.
        div(id = "submitted_photos_row1",
            class = "submitted_photos_rows",
            uiOutput("submitted_ui_1")),
        
        div(id = "submitted_photos_row2",
            class = "submitted_photos_rows",
            uiOutput("submitted_ui_2")),
        
        div(id = "submitted_photos_row3",
            class = "submitted_photos_rows",
            uiOutput("submitted_ui_3")),
        
        div(id = "submitted_photos_row4",
            class = "submitted_photos_rows",
            uiOutput("submitted_ui_4")),
        
        div(id = "submitted_photos_row5",
            class = "submitted_photos_rows",
            uiOutput("submitted_ui_5")),
        
        div(id = "submitted_photos_row6",
            class = "submitted_photos_rows",
            uiOutput("submitted_ui_6"))

        ),
    shinyjs::hidden(checkboxInput(inputId = "confirm_address", 
                  label = "Please confirm these pictures are for the street address you provided above!",
                  value = FALSE))
    
    ), #END FILE UPLOADING FIELDSET

    tags$fieldset(
      tags$legend(
        h3("Submit form")
      ),
    shinyjs::disabled(actionButton(inputId = "submit_inputs",
                 label = "Complete form to unlock submission!"
    ))
    ) #END SUBMISSION AREA FIELDSET
    
  ) #END FORM

), #END MAIN


## ### FOOTER ### ----------------------------------------------------------

#Insert a footer with links, contact info, funding credits, and current version number.
tags$footer(
HTML("The Zebra Mussel Safari App was designed and is maintained by <address><a href='mailto:bajcz003@umn.edu'>Dr. Alex Bajcz (bajcz003@umn.edu)</a></address>, staff Quantitative Ecologist for <a href ='https://maisrc.umn.edu/ target = '_blank'>MAISRC</a>.<br><br>App last updated August 1st, 2025. Version 1.0.0. <a href = 'https://docs.google.com/document/d/1mc2aGAWRS2uIpR_4a7o4w95h-yWAseBcIxF9c3A44fk/edit?usp=sharing' target = '_blank'>View our accessibility statement (opens in a new tab)</a><br><br>
                                   Funding for this work was provided by the Minnesota Environment and Natural Resources Trust Fund (ENRTF) as recommended by the Minnesota Aquatic Invasive Species Research Center (MAISRC) and the Legislative-Citizen Commission on Minnesota Resources (LCCMR) and also the State of Minnesota.<br>"), 
img(src = "jointlogo.png", id = "logo", alt = "")
 ),

# ### HIDDEN SUBMISSIONS PROGRESS OVERLAY ### ----------------------------------------------------------
div(
  id = "custom_progress_overlay",
  style = "
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.75);
    z-index: 10000;
    display: none;
    align-items: center;
    justify-content: center;
    text-align: center;
  ",
  div(
    style = "
      color: white;
      font-size: 2rem;
      background: #222;
      padding: 40px;
      border-radius: 10px;
      max-width: 600px;
      width: 90%;
      text-align: center;
      box-shadow: 0 0 20px rgba(0,0,0,0.6);
    ",
    "Uploading files...",
    br(), br(),
    tags$progress(
      id = "custom_progress_bar",
      value = 0,
      max = 100,
      style = "
        width: 100%;
        height: 40px;
        border: 1px solid #ccc;
        background-color: #eee;
      "
    ),
    tags$div(
      id = "progress_status_text",
      style = "margin-top: 20px; font-size: 1.5rem; color: white;"
    ),
    tags$div(
      id = "aria_status",
      `aria-live` = "polite",
      class = "sr-only"
    )
  )
)

) #End UI
