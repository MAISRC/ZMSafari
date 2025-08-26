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

#THIS JS HELPS US REPOSITION THE SCREEN FOR THE USER ONCE INTERACTIONS WITH THE FILE INPUT OCCUR--OTHERWISE, INTERACTING WITH THE FILE INPUT JUMPS THEM TO THE TOP OF THE PAGE.
tags$head(
  tags$script(HTML("
  Shiny.addCustomMessageHandler('scrollToTarget', function(message) {
    const target = document.getElementById(message.id);
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
"))
),

#THIS JS CODE CHECKS LOCAL BROWSER STORAGE FOR PREVIOUSLY CACHED NAMES AND EMAIL ADDRESSES FROM PREVIOUS SUBMISSIONS AND, IF IT FINDS IT, TRIGGERS SHINY EVENTS WE CAN WATCH SERVER-SIDE.  
tags$head(
tags$script(HTML("
  $(document).on('shiny:connected', function() {
    var name = localStorage.getItem('ZMSafariSubmittedName');
    var email = localStorage.getItem('ZMSafariSubmittedEmail');
    if(name) Shiny.setInputValue('stored_name', name, {priority: 'event'});
    if(email) Shiny.setInputValue('stored_email', email, {priority: 'event'});
  });
"))
),

##RIGHT NOW, UPON REFRESH, YOU STAY DOWN BY THE SUBMIT BUTTON INSTEAD OF JUMPING BACK TO THE TOP. THIS FIXES THAT.
tags$head(
  tags$script(HTML("
  $(document).on('shiny:connected', function() {
      window.scrollTo(0, 0);
    });
  "))
),

  
# ### ENABLING OPTIONAL FUNCTIONALITY ### ------------------------------------------

#SOME SHINY-AFFILIATED PACKAGES NEED TO HAVE THEIR FEATURES "ENABLED" IN THE UI. I PUT THOSE FUNCTION CALLS HERE. COMMENT OUT OR DELETE IF THE ASSOCIATED PACKAGES AREN'T BEING USED.

waiter::useWaiter(), #NECESSARY TO TURN ON THE WAITER PACKAGE'S FEATURES.
shinyjs::useShinyjs(), #ENABLE SHINYJS

#WE WERE GETTING A SITUATION WHEREIN USERS WEREN'T GETTING THE FEEDBACK NEEDED DURING FILE UPLOADING AND UI BUILDING TO KNOW SOMETHING WAS HAPPENING FOR SEVERAL MINUTES. THIS WAS BECAUSE A LOT OF IT WASN'T DIRECTLY ATTACHED TO THE SERVER-SIDE PROCESSING, SO WE NEEDED A WAY FOR THE CLIENT TO ALSO BE ABLE TO REPORT ITS PROGRESS. THIS CODE FROM CHATGPT BUILDS AN OVERLAY THAT FUNCTIONS AS A PROGRESS BAR/THROBBER THAT WILL COMMUNICATE INFO FROM THE CLIENT TOO, REPLACING THE WAITER THAT WAS THERE. 
tags$head(
  tags$script(HTML("
(function(){
  const $ = window.jQuery; //SHORTCUT??

  //STORAGE OBJs
  let inflight = 0, totalBytes = 0, sentBytes = 0;
  
  let forceHidden = false; //FLAG THAT PREVENTS RE-FIRES UNLESS/UNTIL A NEW UPLOAD BEGINS.
  let overlayVisible = false;
  let ellipsisTimer = null;
  var phase = 'idle';   // 'idle' | 'upload' | 'processing' | 'custom'
  var copyLock = false;   // when true, upload progress can't change title/text
  
  //THIS CODE IS TO HELP US CACHE A OVERLAY TITLE AND MAKE SURE THE PROPER TITLE IS ALWAYS BEING USED.
  var TITLE = null;  // cache after DOM is ready-ish
    function ensureTitleNode(){
      if (!TITLE) TITLE = $('#app-overlay-title');
      return TITLE;
    }
    function setBaseTitle(base){
     var t = ensureTitleNode();
      if (base == null) { t.removeData('base'); return; }
      t.data('base', base);
    }
    function getBaseTitleOrCurrentStripped(){
      var t = ensureTitleNode();
      var s = (t.data('base') || t.text() || '');
      return s.replace(/\\.*$/, ''); // R-escaped backslash
    }
  
  //BUILD AN OVERLAY HTML OBJ
  const Overlay = {
  
    //ADD A METHOD CALLED INDETERMINATE FOR WHEN WE CAN'T EASILY KNOW THE PROGRESS OF A SET OF ACTIONS.
    indeterminate: function(on, text, title){
     var t = ensureTitleNode();
      if (on) {
      if (typeof title === 'string' && title.length){
      var base = title.replace(/\\.*$/, '');
      setBaseTitle(base);
      t.text(base);
    } else {
      setBaseTitle(getBaseTitleOrCurrentStripped());
    }
    if (text) { $('#app-overlay-text').text(text); $('#app-overlay-aria').text(text); }
    $('#app-overlay-bar').addClass('is-indeterminate');

    if (!ellipsisTimer) {
      var baseForAnim = getBaseTitleOrCurrentStripped();
      var i = 0;
      ellipsisTimer = setInterval(function(){
        i = (i + 1) % 4; // 0..3 dots
        t.text(baseForAnim + '.'.repeat(i));
      }, 400);
    }
  } else {
    $('#app-overlay-bar').removeClass('is-indeterminate');
    if (ellipsisTimer) { clearInterval(ellipsisTimer); ellipsisTimer = null; }
    // Do not force-reset the title; just forget the stored base.
    setBaseTitle(null);
  }
},

    show(opts){ //SHOW METHOD W/ A TEXT INPUT.

        var o = opts || {};
  // ensure any running indeterminate won’t restore an old title
  this.indeterminate(false);
  setBaseTitle(null);

  if (o.force === true) { forceHidden = false; }
  if (forceHidden) return;

  if (!overlayVisible) {
    $('#app-overlay').css('display','flex');
    $('#app-overlay-panel').focus();
    overlayVisible = true;
  }
  if (o.title) $('#app-overlay-title').text(o.title);
  if (o.text)  { $('#app-overlay-text').text(o.text); $('#app-overlay-aria').text(o.text); }
  if (typeof o.pct === 'number') this.update(o.pct);

  if (o.buttonText){
    $('#app_overlay_btn').text(o.buttonText);
    $('#app-overlay-actions').css({ display:'flex', 'justify-content':'center' });
  } else {
    $('#app-overlay-actions').css('display','none');
  }
},
    
    //UPDATE METHOD W/ % AND TEXT INPUTS.
    update(pct, text, title){
      const p = Math.max(0, Math.min(100, Math.round(pct || 0)));
      $('#app-overlay-bar-fill').css('width', p + '%');
      $('#app-overlay-bar').attr('aria-valuenow', p);
      if (title) $('#app-overlay-title').text(title);   
      if(text) { $('#app-overlay-text').text(text); $('#app-overlay-aria').text(text); }
    },
    
    //HIDE METHOD.
    hide(){
    this.indeterminate(false);
    forceHidden = true; //TURN INVISIBLE AND LOCK TILL NEXT UPLOAD.

      overlayVisible = false;
      copyLock = false;                 // <— reset on full hide
      $('#app-overlay').css('display','none');

      //ENSURE THIS STAYS HIDDEN EVEN IF IT ENDS UP IN A RACE SOMEHOW.
      setTimeout(function(){ $('#app-overlay').css('display','none'); }, 0);
      
      //RESET PROGRESS STATE FOR IF ANOTHER UPLOAD OCCURS.
      sentBytes = 0; totalBytes = 0; inflight = 0;
      $('#app-overlay-bar-fill').css('width', '0%');
      $('#app-overlay-bar').attr('aria-valuenow', 0);
      $('#app-overlay-actions').css('display','none');
    }
  };
 
 //FUNCTION FOR ASSESSING HOW MUCH UPLOAD PROGRESS HAS BEEN MADE. 
  function recalcTotalSize(){
    totalBytes = 0;
    $('input[type=file]').each(function(){
      const fs = this.files || [];
      for(let i=0;i<fs.length;i++){ totalBytes += fs[i].size || 0; }
    });
  }
  
  //FACTORY FUNCTION FOR LINKING UPLOAD PROGRESS W/ THE PROGRESS BAR CONTENTS (I THINK)
  function onProgressFactory(xhr){
    xhr.__lastLoaded = 0;
    if(xhr.upload){
      xhr.upload.addEventListener('progress', function(e){
        if(e.lengthComputable){
          const delta = Math.max(0, e.loaded - (xhr.__lastLoaded || 0));
          xhr.__lastLoaded = e.loaded;
          sentBytes += delta;
          const pct = totalBytes > 0 ? (sentBytes / totalBytes) * 100 : 0;
      if (phase === 'upload') {
        if (!overlayVisible && !forceHidden) {
        // First progress: make it visible, but DO NOT set title/text
        Overlay.show({ pct: pct });
         } else {
        Overlay.update(pct); // update bar only
        }
      } else {
      // Not in upload phase anymore: never touch title/text
      Overlay.update(pct);
      }
        }
      });
    }
    xhr.addEventListener('loadend', function(){
      inflight = Math.max(0, inflight - 1);
      if(inflight === 0){
        Overlay.update(100, 'Processing uploaded files…');
        phase = 'processing';             // <-- now we're past upload
        Overlay.indeterminate(true, 'Processing uploaded files…');  // start animation
        if(window.Shiny && Shiny.setInputValue){
          Shiny.setInputValue('uploads_done_client', Date.now(), {priority:'event'});
        }
      }
    });
  }

  //NOT SURE WHAT THIS HELPER FUNCTION DOES...
  function isUploadUrl(url){ return !!url && url.indexOf('upload') !== -1; }

  //A REAL FRESH UPLOAD HAS BEGUN--START SHOWING AND TRACKING STUFF.
  function beginUpload(){
  if (inflight === 0) {          // first request of this batch
    forceHidden = false;
    recalcTotalSize();           // sum bytes across all selected files
    sentBytes = 0;               // reset once per batch
    phase = 'upload';                // <-- mark we're in upload phase
    copyLock = false;               // <— allow upload copy again for this batch
  }
  inflight++;
}

  //I THINK THIS SCRIPT ACTUALLY TOUCHES OFF THE OTHER PROCESSES THAT WATCH FOR AND MANAGE THE OVERLAY WHEN AN UPLOAD BEGINS...?
  if(window.Shiny && typeof Shiny.xhrHook === 'function'){
    Shiny.xhrHook('send', function(xhr, opts){
      if(!opts || !isUploadUrl(opts.url)) return;
      beginUpload();
      onProgressFactory(xhr);
    });
  } else if($ && $.ajaxPrefilter && $.ajaxSettings && $.ajaxSettings.xhr){
    $.ajaxPrefilter(function(options){
      if(!isUploadUrl(options && options.url)) return;
      const baseXhrFactory = options.xhr || $.ajaxSettings.xhr;
      options.xhr = function(){
        const xhr = baseXhrFactory();
        beginUpload();
        onProgressFactory(xhr);
        return xhr;
      };
    });
  }

  //CREATE A CUSTOM MESSAGE HANDLER FOR THE SHINY SERVER SIDE TO BE ABLE TO CONTROL THE OVERLAY AND USE THE METHODS. 
  if(window.Shiny && Shiny.addCustomMessageHandler){
    Shiny.addCustomMessageHandler('overlay', function(msg){
    
      if(!msg || !msg.action) return;
      
      if(msg.action === 'show')   { 
      forceHidden = false; //MAKE SURE TO RESET THE LOCK
      phase = 'custom';                 // <-- lock copy to server-driven
      copyLock = true;                  // <— lock copy first
      Overlay.indeterminate(false); // <-- ensure we leave indeterminate if it was on
      Overlay.show({title: msg.title, text: msg.text, pct: msg.pct, buttonText: msg.buttonText}); 
      }
      
      if(msg.action === 'update') {
      Overlay.update(msg.pct || 100, msg.text, msg.title);  // <-- title supported now
      }
      
      if(msg.action === 'hide')   { Overlay.hide(); $(document).one('shiny:idle', function(){ Overlay.hide(); }); }
      
      if (msg.action === 'indeterminate') {
        phase = 'processing';
        copyLock = true;                  // <— lock copy first
        if (!overlayVisible) { //FORCE DOWN ANY LINGERING OVERLAY CONTROLLED BY THE CLIENT.
           Overlay.show({
           title: msg.title || 'Working…',
           text:  msg.text  || 'Processing…',
           pct:   100
      });
      } else if (msg.title || msg.text) {
        Overlay.update(undefined, msg.text, msg.title);
        }
      // Force reset base title so the animation uses the new one
      setBaseTitle(msg.title || 'Working…');
      Overlay.indeterminate(true, msg.text, msg.title);
    }
      
      if (msg.action === 'determinate') {
      Overlay.indeterminate(false);
      }
    });
  }
  
  //HOOK OVERLAY BUTTON INTO A SHINY INPUT VALUE FOR EVENT TRACKING
 //USE A DELEGATED BINDING, PUTTING THIS ON THE DOCUMENT INSTEAD OF ON THE BUTTON DIRECTLY SO IT GETS PUT ON THE BUTTON WHENEVER IT APPEARS.
$(document).on('click', '#app_overlay_btn', function(e){
  e.preventDefault();
  if (window.Shiny && Shiny.setInputValue) {
    Shiny.setInputValue('app_overlay_button', Date.now(), { priority: 'event' });
  }
});
  
    // ---- Debug helpers (safe to keep in prod) ----
  window.__appOverlay = Overlay;

window.__overlayDebug = {
  // snapshot of internal state
  get state(){ return {
    phase: phase,
    forceHidden: forceHidden,
    overlayVisible: overlayVisible,
    inflight: inflight,
    totalBytes: totalBytes,
    sentBytes: sentBytes
  };},

  // force phase changes
  setPhase: function(p){
    phase = p;
    console.log('phase ->', phase);
  },

  // show/hide/indeterminate with your copy
  show: function(opts){ (opts = opts || {}).force = true; Overlay.show(opts); },
  hide: function(){ Overlay.hide(); },
  indeterminateOn: function(text, title){ Overlay.indeterminate(true, text, title); },
  indeterminateOff: function(){ Overlay.indeterminate(false); },

  // simulate upload progress callback behavior
  simulateUploadProgress: function(pct){
    if (phase === 'upload') {
      if (!overlayVisible && !forceHidden) {
        console.log('[sim] first progress -> would set default upload copy');
        Overlay.show({ title:'Uploading files…', text:'This may take a few minutes on slower connections.', pct:pct });
      } else {
        console.log('[sim] subsequent progress -> update only');
        Overlay.update(pct);
      }
    } else {
      console.log('[sim] not in upload phase -> update only');
      Overlay.update(pct);
    }
  }
};
  
})();
"))
),

#   ### ADD POLISHING UI ELEMENTS ### -------------------------------------

  #USING THE SHINYDISCONNECT PACKAGE, WE CAN SET A CUSTOM DISCONNECT MESSAGE SO IT'S ABUNDANTLY CLEAR TO USERS THAT THE APP HAS CLOSED (IT'S NOT OBVIOUS OTHERWISE). 
  disconnectMessage(
    text = "Hmm...", #IT ACTUALLY DOESN'T MATTER WHAT THIS SAYS--WE OVERWRITE IT USING THE FUNCTION BELOW ANYWAY.
                    refresh = "Refresh", #SAME HERE.
                    width = "full", 
                    top = "center", 
                    size = 22, 
                    background = "#7a0019", 
                    colour = "white", 
                    refreshColour = "#ffb71e", 
                    css = "z-index: 100000 !important;"),

tags$head(
accessibleDisconnectMessage() #<--ENSURES THE DISCONNECT MESSAGE MEETS GUIDELINES.
),

#USING THE WAITER PACKAGE, WE CAN ADD IN A "PRELOADER WAITER" THAT SITS ON SCREEN WHILE THE APP BOOTS UP, WHICH IS REALLY ONLY NECESSARY IF START-UP TAKES KIND OF A WHILE. 
  waiter::waiter_preloader(
    html = tagList(
      waiter::spin_loaders(6),
      br(),
      br(),
      HTML("<em>Welcome to the Zebra Mussel Safari App, operated by the Minnesota Aquatic Invasive Species Research Center! Please wait while we gas up the Jeep...</em>"),
      br(),
      br(),
      img(src = "preload.png", alt = "")), #EITHER PROVIDE ALT TEXT OR DESCRIBE ANY IMAGE USED HERE IN THE MAIN TEXT ABOVE.
      color = "#7a0019",
      fadeout = 500,
  ),


# ### CORE APP UI ELEMENTS ### --------------------------------------------

## ### HEADER, H1, NAV ### -------------------------------------------------

#THE FIRST ELEMENT OF THE PAGE SHOULD PROBABLY BE A HEADER, IF APPLICABLE. 
tags$header(
    class = "flexthis flexcol width100 justifycenter flexwrap",
    #THE TITLE OF THE APP SHOULD BE IN THE HEADER, AND PROBABLY ALSO BEAR THE H1 TAG.
    h1(
      img(src = "ZM Safari Shiny App Header Image.png", alt = "Zebra Mussel Safari Data Submission App", id = "h1_title_logo")
    ),
    class = "flexthis flexcol width100 justifycenter flexwrap"), 

## ### MAIN CONTENT/MODULES ### --------------------------------------------

tags$main(id = "app_main",
          tags$h2("Instructions", tabIndex = "0"),
  tags$p(HTML("This is the photo submission page for the Zebra Mussel Safari program, managed by AIS Detectors and MAISRC at the University of Minnesota!<br><br>Please fill out the form below once for each sampler you are submitting photos for. Note: When you select picture files to upload, you must select exactly six files (all those from the same sampler)! If you are having trouble doing this on your device, please let us know.<br><br>After you\'ve uploaded your files, click the 'Submit' button, which will be enabled assuming you have filled out the form completely and adequately. The submission process will begin and a progress bar will display. After submission, you will get a notification indicating submission was successful. Submission will then be locked--reload the page to be able to submit again.<br><br>Note: All questions on this form are required. Failure to answer even one question satisfactorily will prevent the submit button from enabling!")),
  
  tags$form(id = "app_form",
    
    ##Inputs regions
    
    tags$fieldset(
      tags$legend(
        h2("Submitter info")
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
        h2("Submission details")
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
    suppressNativeSelectAccessibility("collector_lake"),
    
    sliderTextInput("submission_hardness",
                    label = "Indicate the total water hardness from your water sample according to the color scale on the side of the bottle in parts per million (ppm). The packaging has two sets of numbers for each color; please be sure you are recording results from the parts per million scale, which corresponds to the options available for this question.",
                    choices = c("Pick" = "Pick", "0" = "0", "25" = "25", "50" = "50", "120" = "120", "250" = "250", "425" = "425"), 
                    selected = "Pick", 
                    hide_min_max = TRUE,
                    force_edges = TRUE,
                    grid = TRUE
                      )
    
    ), #END SUBMISSION SPECIFICS FIELDSET
    
    tags$fieldset(id = "whole_input_area",
      tags$legend(
        h2("Photo uploads")
      ),
      
    fileInput(inputId = "submitted_files",
              label = HTML("Important: Upload exactly six image files of your sampler: one photo of each plate surface (three plates (top, middle, and bottom), each with an upper and lower surface).<br>
                <ul>
                <li>All images must be from the sampler deployed at the street address you entered for an earlier question.</li>
                <li>Accepted file types: JPG, PNG, HEIC, HEIF, TIFF, BMP, GIF, WEBP, and PDF.</li>
                <li>Once exactly 6 valid image files are uploaded, thumbnails will appear below this question along with follow-up questions about each image. Answering all those questions is required.</li>
                <li>You may select files to upload in any order.</li>
                <li>It may take up to several minutes for your screen to update after selecting images to upload; please be patient (uploading image files can take a while!).</li>
                <li>Newer phones can take photos that contain all kinds of bells and whistles: video clips, location data, captions, etc. We just want the highest-quality photo your phone can take and nothing else! So, it\'s optional, but if you know how, disable or exclude other features before uploading (uploading more complex files will take longer and might fail).</ul>"),
              multiple = TRUE, 
              accept = "image/*", 
              buttonLabel = "Select files"
    ),

    suppressFileInputFauxTextbox("submitted_files"),
    
    div(id = "file_warning_area",
    uiOutput("file_val_warning"), #FILE VALIDATION WARNING.
    ),
    
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
    suppressAriaLiveForPhotos("submitted_ui_1", "submitted_ui_"), #<-ONLY GET ONE ARIA-LIVE OUT OF THESE 6 CONTAINERS.
    uiOutput("duped_answers_warning"), #<-IF THEY FAIL TO PROVIDE 6 UNIQUE RESPONSES.
    uiOutput("confirm_address_div"),
    
    ), #END FILE UPLOADING FIELDSET

    tags$fieldset(
      tags$legend(
        h2("Submit form")
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
HTML("The Zebra Mussel Safari App was designed and is maintained by <address><a href='mailto:bajcz003@umn.edu'>Dr. Alex Bajcz (bajcz003@umn.edu)</a></address>, staff Quantitative Ecologist for <a href ='https://maisrc.umn.edu/ target = '_blank'>MAISRC</a>.<br><br>App last updated August 26, 2025. Version 1.0.3. <a href = 'https://docs.google.com/document/d/1mc2aGAWRS2uIpR_4a7o4w95h-yWAseBcIxF9c3A44fk/edit?usp=sharing' target = '_blank'>View our accessibility statement (opens in a new tab)</a><br><br>
                                   Funding for this work was provided by the Minnesota Environment and Natural Resources Trust Fund (ENRTF) as recommended by the Minnesota Aquatic Invasive Species Research Center (MAISRC) and the Legislative-Citizen Commission on Minnesota Resources (LCCMR) and also the State of Minnesota.<br>"), 
img(src = "jointlogo.png", id = "logo", alt = "")
 ),

# ### PROGRESS OVERLAY ### ----------------------------------------------------------
tags$div(
  id = "app-overlay",
  style = "display:none; position:fixed; inset:0; z-index:10000; background:rgba(0,0,0,0.65);
           align-items:center; justify-content:center; text-align:left;",
  
  tags$div(
    id = "app-overlay-panel",
    role = "dialog", 
    `aria-modal` = "true", 
    tabindex = "-1",
    
    tags$h2(
      id = "app-overlay-title",
      "Working…"
    ),
    
    tags$p(
      id = "app-overlay-text",
      `aria-live` = "assertive",
      "Please wait while we complete this step."
    ),
    
    tags$div(
      id = "app-overlay-bar",
      role = "progressbar", 
      `aria-valuemin` = "0", 
      `aria-valuemax` = "100", 
      `aria-valuenow` = "0",
      
      tags$div(id = "app-overlay-bar-fill")
      
    ),
    
    tags$div(id = "app-overlay-actions",
             # optional button slot (e.g., a 'Refresh' or 'Cancel' button if you need it)
             tags$button(
               id = "app_overlay_btn",
               type = "button",
               class = "btn btn-default",
               style = "min-width:200px;",
               "Refresh"
             )
    ),
    
    tags$div(id="app-overlay-aria", 
             `aria-live`="polite", 
             class="sr-only")
  )
)

) #End UI
