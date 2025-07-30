/* AT TIME OF WRITING, THE SHINY DISCONNECT PACKAGE DOESN'T PUT ANY TEXT IN ITS "RELOAD THE PAGE" LINK BY DEFAULT, WHICH IS BAD FOR SCREEN READERS. THIS CODE INJECTS SOME TEXT THERE--ADJUST WHERE IT SAYS "REFRESH THE PAGE" TO CHANGE WHAT IT SAYS. */

$(document).ready(function() {
      var reloadLink = document.getElementById('ss-reload-link');
      if (reloadLink) {
        reloadLink.innerText = 'Refresh the page';
       }
      });