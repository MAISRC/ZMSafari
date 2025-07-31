shinyServer(function(input, output, session) {


# REACTIVES ---------------------------------------------------------------

  reactives = reactiveValues(
    valid_files = FALSE, #STEP 1 IN REACTION CHAIN--ENSURE 6 FILES OF APPROPRIATE TYPES SUBMITTED.
    pic_ui_done = FALSE, #STEP 2--ONLY ONCE WE HAVE 6 WORKABLE FILES DO WE ASSEMBLE PIC UI
    picinputs_alldiff = FALSE, #STEP 3--ONCE THE VALIDATION IS ON, WE ALSO PERFORM CHECKS TO ENSURE ALL OTHER VALIDATION IS ON AND THAT ALL THREE CHECKS PASS.
  )


# VALIDATORS --------------------------------------------------------------

  
  #VALIDATE THAT USERS HAVE SELECTED A REAL ANSWER FOR ALL PIC INPUTS
  piccheck.valid = InputValidator$new() 
  piccheck.valid$add_rule("submitted_pic_plate1", sv_not_equal("No selection", "Note: Indicate which plate this is."))
  piccheck.valid$add_rule("submitted_pic_plate2", sv_not_equal("No selection", "Note: Indicate which plate this is."))
  piccheck.valid$add_rule("submitted_pic_plate3", sv_not_equal("No selection", "Note: Indicate which plate this is."))
  piccheck.valid$add_rule("submitted_pic_plate4", sv_not_equal("No selection", "Note: Indicate which plate this is."))
  piccheck.valid$add_rule("submitted_pic_plate5", sv_not_equal("No selection", "Note: Indicate which plate this is."))
  piccheck.valid$add_rule("submitted_pic_plate6", sv_not_equal("No selection", "Note: Indicate which plate this is."))
  piccheck.valid$add_rule("submitted_pic_surface1", sv_not_equal("No selection", "Note: Indicate which surface this is."))
  piccheck.valid$add_rule("submitted_pic_surface2", sv_not_equal("No selection", "Note: Indicate which surface this is."))
  piccheck.valid$add_rule("submitted_pic_surface3", sv_not_equal("No selection", "Note: Indicate which surface this is."))
  piccheck.valid$add_rule("submitted_pic_surface4", sv_not_equal("No selection", "Note: Indicate which surface this is."))
  piccheck.valid$add_rule("submitted_pic_surface5", sv_not_equal("No selection", "Note: Indicate which surface this is."))
  piccheck.valid$add_rule("submitted_pic_surface6", sv_not_equal("No selection", "Note: Indicate which surface this is."))
  
  #VALIDATOR FOR THE REST OF THE FORM'S QUESTIONS
  form.valid = InputValidator$new() 
  form.valid$add_rule("collector_name", sv_required("Note: Enter your full name."))
  form.valid$add_rule("collector_email", sv_email("Note: Enter a valid email address."))
  form.valid$add_rule("collector_address", function(value) {
    if(!grepl("^[0-9]+\\s+[a-zA-Z0-9\\s\\p{P}]+$", value, perl = TRUE)) {
      "Note: Enter a proper street address."
    }
  })
  form.valid$add_rule("collection_date", function(value) {
    if(is.null(value) | as.Date(value) <= as.Date("2025-07-01") | as.Date(value) > Sys.Date()) {
      "Note: Pick a valid date."
    }}
  )
  form.valid$add_rule("collector_county", 
                      sv_not_equal("No selection", "Note: Select your county."))
  form.valid$add_rule("collector_lake", function(value) {
    if(value == "Select a county first!" | value == "No selection") {
      "Note: Choose your lake."
    }
  })
  form.valid$add_rule("confirm_address", sv_equal(TRUE, "Note: This question is required!"))
  

# OBSERVERS ---------------------------------------------------------------


  ## UI UPDATING OBSERVERS ---------------------------------------------------

  #ONCE USERS SELECT A COUNTY, UPDATE THE LAKE PICKER TO POPULATE WITH JUST LAKES FROM THAT COUNTY.
  observeEvent(input$collector_county, ignoreInit = TRUE, {
    
    newlakeslist = dows_lakenames_counties %>% 
      filter(COUNTY == input$collector_county) %>% 
      mutate(formatted = paste0(NAME, " (DOW ", DOW, ")")) %>% 
      select(formatted) %>% 
      pull()
    
    updatePickerInput(session, "collector_lake", 
                      choices = c("No selection", 
                                  sort(unique(newlakeslist))))
    
  })

  ## PIC SUBMISSION LOGIC OBSERVERS ---------------------------------------------------
  
  #STEP 1 IN PIC SUBMISSION LOGIC CHAIN: WHEN USERS UPLOAD FILES, WE NEED TO CHECK THAT THEY ARE CORRECT IN TYPE AND NUMBER.
  observeEvent(list(input$submitted_files), ignoreInit = TRUE, {
    
    reactives$valid_files = FALSE #TURN FLAG OFF TO START.

    req(input$submitted_files)
    
    data1 = data.frame(input$submitted_files)
    ext = tools::file_ext(data1$datapath) 
    
    if(all(ext %in% c("tif", "tiff", "bmp", "jpg", "jpeg", "gif","pdf", "png", "PNG", 
                      "TIF", "TIFF", "BMP", "JPG", "JPEG", "GIF", "PDF")) &&
       length(ext) == 6) { #THERE SHOULD BE EXACTLY 6 FILES. 
      
      reactives$valid_files = TRUE #FLIP FLAG TO TRUE IF SO.
    }
    
  })
  
  #STEP 2 IN PIC SUBMISSION LOGIC CHAIN: WHEN USERS DO SUCCESSFULLY SUBMIT 6 FILES, WE'RE GOING TO UPDATE THE UI TO SHOW THEIR PICS AND THEN INPUTS THAT ALLOW THEM TO SPECIFY THE SURFACE AND PLATE.
  observeEvent(reactives$valid_files, ignoreInit = TRUE, {
    
    #WIPE THEM CLEAN AT FIRST
    output$submitted_ui_1 = renderUI({})
    output$submitted_ui_2 = renderUI({})
    output$submitted_ui_3 = renderUI({})
    output$submitted_ui_4 = renderUI({})
    output$submitted_ui_5 = renderUI({})
    output$submitted_ui_6 = renderUI({})
    reactives$pic_ui_done = FALSE
    shinyjs::hide("confirm_address")
    
    req(isTruthy(reactives$valid_files)) #COULD ONLY EVER PASS IF THERE ARE EXACTLY 6 FILES.
    
    data1 = data.frame(input$submitted_files)
    
    for(i in 1:6) {
      local({
        my_i = i  #NECESSARY FOR SOME REASON
        b64 = base64enc::dataURI(file = data1$datapath[i], mime = "image/png") #GRAB THE IMAGE FILE
        output_id = paste0("submitted_ui_", my_i)
        descriptor_text = paste0("Submitted pic #", my_i, ". Original file name: ", data1$name[i])
        output[[output_id]] = renderUI({ #USE LIST ASSIGNMENT INSTEAD OF $ OPERATOR
          tagList(
            p(descriptor_text),
            column(width = 5, 
            img(src = b64, width = "310px", height = "100%", alt = "")
            ),
            column(width = 7,
                   class = "flexthis flexwrap flexcol",
            radioButtons(
              inputId = paste0("submitted_pic_plate", my_i),
              label = "Which plate within the sampler is in this picture?",
              choiceValues = c("No selection", "Top", "Middle", "Bottom"),
              choiceNames = c("No selection", "The top one (Closest to the surface)", "The middle one", "The bottom (closest to the lakebed)"),
              inline = F
            ),
            suppressRadioGroupLabelWarnings(paste0("submitted_pic_plate", my_i)),
            radioButtons(
              inputId = paste0("submitted_pic_surface", my_i),
              label = "Which surface of that place is in this picture?",
              choiceValues = c("No selection", "Top", "Bottom"),
              choiceNames = c("No selection", "The upper surface (facing the sky)", "The lower surface (facing the lakebed)"),
              inline = F
            ),
            suppressRadioGroupLabelWarnings(paste0("submitted_pic_surface", my_i))
           )
          )
        })
      })
    }
    
    shinyjs::show("confirm_address")
    reactives$pic_ui_done = TRUE
    
  })

    #STEP 3 IN PIC SUBMISSION LOGIC CHAIN: ONCE THEY HAVE ACCESS TO THE PIC QUESTIONS, ENSURE THAT ALL THOSE ANSWERS ARE UNIQUE.
   observe({
     
      req(isTruthy(reactives$pic_ui_done)) #ONLY DOESN'T GATE WHEN READY.
      
      ##WE FIRST DO A CHECK TO ENSURE THAT ALL THE PIC INPUTS YIELD DIFFERENT OUTPUT STRINGS TO ENSURE THEY ARE ALL DIFFERENT. THAT MEANS WE ARE GETTING A PIC FROM EACH PLATE'S SURFACE.
      str1 = paste0(input$submitted_pic_plate1, input$submitted_pic_surface1, collapse = '')
      str2 = paste0(input$submitted_pic_plate2, input$submitted_pic_surface2, collapse = '')
      str3 = paste0(input$submitted_pic_plate3, input$submitted_pic_surface3, collapse = '')
      str4 = paste0(input$submitted_pic_plate4, input$submitted_pic_surface4, collapse = '')
      str5 = paste0(input$submitted_pic_plate5, input$submitted_pic_surface5, collapse = '')
      str6 = paste0(input$submitted_pic_plate6, input$submitted_pic_surface6, collapse = '')
      
      #THIS CHECK WILL PASS EVEN IF SOME ARE STILL NO SELECTION, BUT piccheck.valid WOULDN'T PASS IN THAT CASE, SO BETWEEN THE TWO, WE'RE GOOD.
      if(length(unique(c(str1, str2, str3, str4, str5, str6))) == 6) {
        reactives$picinputs_alldiff = TRUE
      } else {
        reactives$picinputs_alldiff = FALSE
        form.valid$enable()
        piccheck.valid$enable()
      }
      
   })
   
   #STEP 4 IN PIC SUBMISSION LOGIC CHAIN: ONLY ONCE ALL 6 UNIQUE ANSWERS WERE PROVIDED TO THE PIC QUESTIONS DO WE PERFORM THE FINAL CHECK TO TURN ON SUBMISSION.
   observe({

      if(
        isTruthy(reactives$picinputs_alldiff) && ##ALL THEIR ANSWERS MUST BE UNIQUE
        isTruthy(piccheck.valid$is_valid()) && # AND THEY'VE SUBMITTED 6 VALID FILES AND HAVE ALSO ANSWERED ALL THE QUESTIONS (NO REMAIN AS 'NO SELECTION')
        isTruthy(form.valid$is_valid()) #AND THEIR OTHER ANSWERS ARE VALID
        ) {
        
        updateActionButton(session, 
                           "submit_inputs",
                           label = "Submit!",
                           icon = icon("upload"))
        shinyjs::enable("submit_inputs")
        
      } else {
        
        updateActionButton(session, 
                           "submit_inputs",
                           label = "Complete form to unlock submission.")
        shinyjs::disable("submit_inputs")
        
       }
    })
   

  ## SUBMISSION OBSERVERS -----------------------------------------------------
   observeEvent(input$submit_inputs, {
     
     print(js)
     
     data1 = input$submitted_files
     file.num = nrow(data1) + 2
     
     shinyjs::js$showProgressOverlay()
     name.vec = rep(NA, nrow(data1))
     
     for (i in seq_len(nrow(data1))) {
       ext = tools::file_ext(data1$datapath[i])
       
       dow = stringr::str_sub(input$collector_lake, nchar(input$collector_lake) - 8, nchar(input$collector_lake) - 1)
       lake = dows_lakenames_counties$NAME[dows_lakenames_counties$DOW == dow]
       
       nameslug1 = stringr::str_sub(as.character(Sys.Date()), 1, 4)
       nameslug2 = lake
       nameslug3 = dow
       nameslug4 = gsub(" ", "", input$collector_address)
       
       plate_str = paste0("submitted_pic_plate", i)
       nameslug5 = input[[plate_str]]
       
       surface_str = paste0("submitted_pic_surface", i)
       nameslug6 = input[[surface_str]]
       
       all_slugs = paste(nameslug1, nameslug2, nameslug3, nameslug4, nameslug5, nameslug6, sep = "_")
       name.me = paste0(all_slugs, ".", ext)
       
       tmp.path1 = file.path(tempdir(), name.me)
       file.copy(from = data1$datapath[i], to = tmp.path1)
       
       drive_upload(media = tmp.path1, path = submitted_pics_id, name = name.me)
       name.vec[i] = name.me
       
       progress_value = round((i / file.num) * 100)
       progress_label = paste("Uploading file", i, "of", file.num - 1)
       
       shinyjs::js$updateProgress(value = progress_value, label = progress_label)
     }
     
     shinyjs::js$updateProgress(value = i+1/file.num, label = 'Uploading metadata')

     submitted.df = data.frame(
       name = input$collector_name,
       date = as.character(input$collection_date),
       email = input$collector_email,
       county = input$collector_county,
       lake = input$collector_lake,
       street = input$collector_address,
       files = paste0(name.vec, collapse = ',')
     )
     
     sheet_append(data = submitted.df, ss = metadata_id, sheet = "Sheet1")
     
     shinyjs::js$updateProgress(value = i+2/file.num, label = 'Submission complete! Refresh the page to be able to submit again!')
     
     Sys.sleep(time = 60)
     
     shinyjs::disable("submit_inputs")
     shinyjs::js$hideProgressOverlay()
   })

}) #End Server Side
