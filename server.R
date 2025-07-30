#THE MAIN SERVER FILE IS USUALLY PRETTY SPARSE BECAUSE MUCH OF THE SERVER CODE WILL PROBABLY BE IN MODULE FILES. WHAT EXISTS HERE IS GENERALLY WHAT IS NEEDED TO NAVIGATE BETWEEN TABS/MODULES. 

shinyServer(function(input, output, session) {


# ### NON-MODULARIZED SERVER CODE ### -------------------------------------


# ### LOAD MODULES ### ----------------------------------------------------

exampleServer(input, output, session) 

}) #End Server Side
