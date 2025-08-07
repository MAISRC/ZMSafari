##SHINY'S DATE INPUTS WILL BY DEFAULT SET A LABEL'S FOR ATTRIBUTE TO POINT AT THE HOUSING DIV INSTEAD OF AT THE INPUT SUB-ELEMENT. THIS FUNCTION IS A DROP-IN FIX FOR THIS--ADD IT TO THE UI AFTER ANY DATE INPUT AND REFERENCE ITS inputID.
fixDateInputLabel = function(inputId) {
  tags$script(HTML(sprintf("
    $(document).ready(function() {
      const container = document.getElementById('%s');
      if (!container) return;

      const label = document.getElementById('%s-label');
      const input = container.querySelector('input');

      if (label && input) {
        if (!input.id) {
          input.id = '%s-fixed-input';
        }
        label.setAttribute('for', input.id);
      }
    });
  ", inputId, inputId, inputId)))
}


##APPARENTLY, PICKER INPUTS FUNCTIONALLY SUPPRESS A SELECT INPUT THEY CREATE BY JUST HIDING IT VIA TRANSPARENCY, BUT OBVIOUSLY WAVE DOESN'T LIKE THAT, SO WE USE THIS JS TO GO FULL NUCLEAR IN TERMS OF ACTUALLY HIDING THAT ELEMENT SO THAT NO ASSISTIVE TECHNOLOGIES COULD TRIP ON IT AND NO USER WOULD EASIER RE-DISPLAY IT.
suppressNativeSelectAccessibility = function(inputId) {
  tags$script(HTML(sprintf("
    $(document).ready(function() {
      var el = document.getElementById('%s');
      if (el) {
        el.setAttribute('aria-hidden', 'true');
        el.setAttribute('tabindex', '-1');
        el.style.visibility = 'hidden';
        el.style.position = 'absolute';
        el.style.width = '0';
        el.style.height = '0';
        el.style.overflow = 'hidden';
        el.style.pointerEvents = 'none';
        el.style.color = 'inherit';  // prevent contrast warnings
        el.style.backgroundColor = 'inherit';
      }
    });
  ", inputId)))
}

##PICKERINPUTS ACTUALLY FUNCTION UNDER THE HOOD BY CREATING BUTTON ELEMENTS THAT DO THE REAL WORK. HOWEVER, BY DEFAULT, THEY GIVE THESE BUTTONS A TITLE ATTRIBUTE THAT DUPLICATES THE BUTTON TEXT, WHICH WAVE DOESN'T LIKE. THIS FUNCTION SUPPRESSES THE TITLE ATTRIBUTE SINCE IT'D BE REDUNDANT IN THESE INSTANCES ANYHOW
stripPickerDuplicateTitles = function(inputId) {
  tags$script(HTML(sprintf("
    $(document).ready(function() {
      function fixTitle() {
        var button = document.querySelector('button[data-id=\"%s\"]');
        if (button) {
          var labelText = button.innerText.trim();
          var titleText = button.getAttribute('title')?.trim();
          button.setAttribute('tabindex', '0'); //MAKE IT TABBABLE AND PUT IN ACCESSIBILITY TREE.

          if (titleText && labelText === titleText) {
            button.removeAttribute('title');
            console.log('Removed redundant title from: %s');
          }
        }
      }

      // Run once on load
      fixTitle();

      // Set up a MutationObserver to detect DOM changes
      var target = document.getElementById('%s');
      if (!target) return;

      var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          if (mutation.type === 'childList') {
            fixTitle();
          }
        });
      });

      observer.observe(target.parentNode, { childList: true, subtree: true });
    });
  ", inputId, inputId, inputId)))
}


#FILEINPUTS HAVE THIS BOGUS, JUST-FOR-SHOW TEXT INPUT ELEMENT THAT HOLDS PLACEHOLDER TEXT, PROGRESS BAR, AND FILE NAMES. THIS FAILS TO GET A LABEL, WHICH WAVE DOESN'T LIKE. THIS FUNCTION CHANGES THIS INPUT'S ATTRIBUTES TO BE MORE FULLY IGNORABLE. IT ALSO PROVIDES SOME ADDITIONAL ATTRIBUTES TO MAKE SURE IT CAN'T GET FOCUS OR GET PUT IN THE ACCESSIBILITY TREE FOR SCREEN READERS.
suppressFileInputFauxTextbox = function(inputId) {
  tags$script(HTML(sprintf("
    $(document).ready(function() {
      var fileInput = document.getElementById('%s');
      if (!fileInput) return;

      var inputGroup = fileInput.closest('.input-group');
      if (!inputGroup) return;

      var fauxInput = inputGroup.querySelector('input.form-control[type=\"text\"]');
      if (fauxInput) {
        fauxInput.setAttribute('aria-hidden', 'true');
        fauxInput.setAttribute('tabindex', '-1');
        fauxInput.setAttribute('role', 'presentation');
        fauxInput.setAttribute('aria-label', 'Filename display only (decorative)'); 
      }
    });
  ", inputId)))
}

#RADIOBUTTONS TURN THE PROVIDED LABEL INTO AN "OUTER LABEL" FOR THE WHOLE GROUP OF BUTTONS, EVEN THOUGH EACH IS AN INPUT THAT THEN GETS A LABEL FORMED BY ITS CHOICE'S STRING. SO, THE OUTER LABEL HAS A FOR ATTRIBUTE THAT SAYS IT LABELS A FORM CONTROL WHEN IT DOESN'T.
suppressRadioGroupLabelWarnings = function(inputId){
  tags$script(HTML(sprintf("
    $(document).ready(function() {
      var label = document.getElementById('%s-label');
      if (label && label.tagName.toLowerCase() === 'label') {
        var ele = document.createElement('p');
        ele.id = label.id;
        ele.className = label.className;
        ele.classList.add('p-label');
        ele.textContent = label.textContent;
        label.parentNode.replaceChild(ele, label);
      }
    });
  ", inputId)))
}

##THE DISCONNECT MESSAGE FROM THE SHINYDISCONNECT PACKAGE UNWISELY PUTS TEXT CONTENTS INTO A CONTENT CSS PROPERTY OF A BEFORE PSEUDOELEMENT...NOT GREAT. THIS FUNCTION RELOCATES THAT TEXT TO AN ACTUAL DIV, DOES THE SAME FOR THE LINK TEXT, AND ENSURES THAT THE ALERT GRABS FOCUS AND GETS ANNOUNCED TO SCREEN READERS.
accessibleDisconnectMessage = function() {
  tags$script(HTML("
    $(document).on('shiny:disconnected', function(event) {
      var el = document.getElementById('ss-connect-dialog');
      if (el) {
              // Wipe out Shiny's ::before content styles to avoid duplicate text
        var style = document.createElement('style');
        style.innerHTML = `
          #ss-connect-dialog::before,
          #ss-connect-dialog a::before {
            content: none !important;
          }
          #ss-connect-dialog a {
          display: inline !important;
          font-size: unset !important;
          }
        `;
        document.head.appendChild(style);
      
        // Create an accessible alert container
        var msgContainer = document.createElement('div');
        msgContainer.innerHTML = \"Hmm...something has gone wrong. Either you have been idle for too long and the app has timed out or an error has been triggered in the R code of the application. To try again, refresh the page. If this happens again, please file a bug report with Alex at <a href='mailto:bajcz003@umn.edu'>bajcz003@umn.edu</a>. We appreciate your cooperation!\";
        msgContainer.setAttribute('role', 'alertdialog');
        msgContainer.setAttribute('tabindex', '-1');
        msgContainer.setAttribute('aria-label', 'Error message');
        msgContainer.style.outline = 'none';
        msgContainer.style.marginBottom = '1em';

        // Insert it at the beginning of the disconnect dialog
        el.insertBefore(msgContainer, el.firstChild);

        // Shift focus for screen reader and keyboard users
        msgContainer.focus();

        // Ensure the reload link has readable text
        var reloadLink = document.getElementById('ss-reload-link');
        if (reloadLink && reloadLink.innerText.trim() === '') {
          reloadLink.innerText = 'Refresh the page';
        }
      }
    });
  "))
}

#uiOutputs AUTOMATICALLY COME WITH ARIA-LIVE REGIONS THAT WILL YAP AT SCREEN READERS WHEN THEY RE-UPDATE. HERE, WE'LL HAVE 6 APPEAR AT ONCE AND ONLY THE FIRST NEEDS TO UPDATE USERS AS A RESULT, SO WE'LL REMOVE THE ARIA-LIVE ATTRIBUTES FROM THE OTHERS.
suppressAriaLiveForPhotos <- function(keepId, starts_with) {
  tags$script(HTML(sprintf("
      $(document).on('shiny:connected', function() {
      $('.shiny-html-output').each(function() {
        if (this.id !== '%s' && this.id.startsWith('%s')) {
          this.removeAttribute('aria-live');
        }
      });
    });
  ", keepId, starts_with)))
}