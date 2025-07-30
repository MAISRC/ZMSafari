// THIS FUNCTION LISTENS FOR THE DRAW.DT EVENT, WHICH HAPPENS EVERY TIME A DT TABLE IS REDRAWN ANYWHERE IN THE APP. 
    $(document).on('draw.dt', function(e, settings) {
      // 'settings' is the DataTables settings object
      // We'll get the table API for the table that was just drawn
      var api = new $.fn.dataTable.Api(settings);
      
      // The container for this specific table
      var tableContainer = $(api.table().container());
      
      // In a scroll-enabled DT, the 'footer' portion is often a second
      // table that lines up columns with the main table (visual layout). This is undesirable from an accessibility standpoint.
      var footerTable = tableContainer.find('div.dataTables_scrollFootInner table');
      
      //SO, WE HIDE THAT FOOTER AND GIVE IT A ARIA-HIDDEN OF TRUE SO SCREEN READERS DON'T GET STUCK ON IT. 
      if (footerTable.length > 0) {
        footerTable.attr('role', 'presentation');
        footerTable.attr('aria-hidden', 'true');
        
        //AND WE GIVE IT A FAKE HEADER ROW THAT IS ALSO HIDDEN AND CONTAINS SOMETHING CLARIFYING.
        if (footerTable.find('thead').length === 0) {
          footerTable.prepend('<thead><tr><th style=\"visibility: hidden;\">Not a real table.</th></tr></thead>');
        }
      }
    });