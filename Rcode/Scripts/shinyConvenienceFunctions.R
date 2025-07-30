#FUNCTION FOR CHECKING IF A VALUE IS EVEN (FOR COLLAPSIBLES MOSTLY)
checkIfEven = function(val) {
  if(val %% 2 == 0) { 
    return(TRUE) 
  } else { return(FALSE) }
}

#FUNCTION TO OPEN/CLOSE MODALS DEPENDING ON BUTTON CLICKS
openCloseInfo = function(result, answer, question, session) {
  if(result) {
    shinyjs::hide(answer, anim=T, animType = "slide")
    updateActionButton(session, question, icon=icon("plus"))
    runjs(paste0("$('#", question, "').attr('aria-expanded', 'false');")) #These commands update the aria-expanded attribute to reflect whether the accordion is open or closed.
  } else {
    shinyjs::show(answer, anim=T, animType="slide")
    updateActionButton(session, question, icon=icon("minus"))
    runjs(paste0("$('#", question, "').attr('aria-expanded', 'true');"))
  }
}

#RELATED FUNCTION THAT TOGGLES THE ARIA-EXPANDED ATTRIBUTE OF A SHINY ACTIONBUTTON THAT IS RUNNING AN ACCORDIAN-STYLE MENU.
toggleAriaExpanded = function(id) {
  runjs(sprintf("
    (function() {
      var el = document.getElementById('%s');
      if (el) {
        var current = el.getAttribute('aria-expanded');
        // Toggle from 'true' -> 'false' or 'false' -> 'true'
        if (current === 'true') {
          el.setAttribute('aria-expanded', 'false');
        } else {
          el.setAttribute('aria-expanded', 'true');
        }
      }
    })();
  ", id))
}

#FUNCTION FOR DETECTING A VALID EMAIL ADDRESS
isValidEmail = function(x) {
  grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>",
        as.character(x), 
        ignore.case=TRUE)
}

#Function converts a lookup table into a function that does find and replacement in a vectorized way.
replaceViaLookup = function(strings, toreplace, replacements) {
  
  replacement.vec = setNames(replacements, toreplace) #Make a named vector with the replacements as the names.
  
  stringr::str_replace_all(strings, replacement.vec) #Use this function to do the string replacements.
}

# BY DEFAULT, R SHINY'S SELECTINPUT (AND SELECTIZEINPUT) COMES WITH TWO INPUT ELEMENTS--ONE FOR THE TEXT BOX COMPONENT AND ONE FOR THE DROPDOWN MENU COMPONENT. HOWEVER, THESE GET JUST ONE LABEL, WHICH MEANS THE OTHER GOES UNLABELED, WHICH VIOLATES DIGITAL ACCESSIBILITY. THIS FUNCTION CAN BE USED TO SET ARIA-LABELS FOR BOTH INPUT ELEMENTS MANUALLY USING THE ELEMENT'S INPUT ID AND THE DESIRED LABELS FOR BOTH INPUTS.
setSelectInputAria = function(
    inputId, 
    ariaLabelText = "Enter or select here.", 
    ariaLabelDropdown = "List of available options"
) {

  script = str_c(
    "$(document).ready(function() {\n",
    "  var checkExist = setInterval(function() {\n",
    "    var selectEl = document.getElementById('", inputId, "');\n",
    "    if (selectEl) {\n",
    "      // Set ARIA label for the text box widget \n",
    "      selectEl.setAttribute('aria-label', '", ariaLabelText, "');\n",
    "      \n",
    "      // For the dropdown portion, we generally target something like\n",
    "      // '#", inputId, "-selectized ~ .selectize-dropdown .selectize-dropdown-content'\n",
    "      // but exact class sometimes depends. This path is often reliable:\n",
    "      var dropdown = document.querySelector('#", inputId, "-selectized ~ .selectize-dropdown .selectize-dropdown-content[role=\"listbox\"]');\n",
    "      if (dropdown) {\n",
    "        dropdown.setAttribute('aria-label', '", ariaLabelDropdown, "');\n",
    "      }\n",
    "      clearInterval(checkExist); // stop checking\n",
    "    }\n",
    "  }, 100);\n", 
    "});\n"
  )
  
  # Wrap in HTML script tag
  tags$script(HTML(script))
}