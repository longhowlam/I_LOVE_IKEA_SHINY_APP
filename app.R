#### Description ###############################################################
##
## Skeleton Shiny app  using miniUI 
## This will look just better on mobile devices
##


#### Libraries needed #########################################################
library(shiny)
library(miniUI)
library(jpeg)
library(keras)
library(DT)
library(text2vec)


##### Initals / startup code #################################################

vgg16_notop = application_vgg16(weights = 'imagenet', include_top = FALSE)

# Read in flattened tensors, they are stored as a matrix, each image is a row
# each row corresponds to an ikea image

# normally not needed, but the matrix is split into two matrices so 
# that I can stay below the github file size restriction 
ImageFeatures1 = readRDS("data/ImageFeaturesVGG16_1.RDs")
ImageFeatures2 = readRDS("data/ImageFeaturesVGG16_2.RDs")
ImageFeatures = rbind(ImageFeatures1, ImageFeatures2)

# each image corresponds to a product at IKEA, this data set
# stores the link to the product at the ikea website, the price and name of the product.
ImageMetaData = readRDS("data/Allimages.RDs")

##### Addittional Helper Functions ############################################

calcIkeaSimilarity = function(x)
{
  M1 <- as(matrix(x, ncol = length(x)), "dgCMatrix")
  out = 1-text2vec::dist2(M1,ImageFeatures)
  out
}

#### MINIPAGE #################################################################

ui <- miniPage(
  gadgetTitleBar(
    left = NULL, 
    right = NULL,
    "Check Ikea First"
  ),
  
  miniTabstripPanel(
    
    #### introduction tab ############
    miniTabPanel(
      "introduction", icon = icon("area-chart"),
      miniContentPanel(
        htmlOutput("intro")
      )
    ),
    
    #### parameters tab ##############
    miniTabPanel(
      "Take_picture", icon = icon("sliders"),
      miniContentPanel(
        fileInput('file1', 'Choose an image (max 5MB)'),
        numericInput("input_topN", "Show top N matches", value=7),
        selectInput("typeselect", "help me out here", choices = list(), selected = 1),
        img(SRC="IkeaNew.jpg", height = 340)
      )
    ),
 
    #### image tab ##################
    miniTabPanel(
      "Image_taken", icon = icon("file-image-o"),
      miniContentPanel(
        padding = 0,
        imageOutput("plaatje")
      )
    ),
    
    #### Resultaat tab ############
#    miniTabPanel(
#      "Resultaat", icon = icon("table"),
#      miniContentPanel(
#        verbatimTextOutput("ResultaatOut")
#      )
#    ),
    
    #### Tabel resultaat ###########
    miniTabPanel(
      "Best_Matches", icon = icon("table"),
      miniContentPanel(
        dataTableOutput("ResultaatTabel")
      )
    )
    
  )
)

################################################################################

#### SERVER FUNCTION ###########################################################

server <- function(input, output, session) {
  
  #### observe functions ####################
  observe({
    # Create a list of new options, where the name of the items is something
    # like 'option label x 1', and the values are 'option-x-1'.
    s_options <- as.list(c("I feel Lucky", names(table(ImageMetaData$type2))))
    
    updateSelectInput(session, "typeselect", choices = s_options)
    
  })
  
  
  #### reactive functions ###################
  ProcessImage <- reactive({
    
    progress <- Progress$new(session, min=1, max=15)
    on.exit(progress$close())
    
    progress$set(
      message = 'in progress', 
      detail = 'This may take a few seconds...'
    )
    
    inFile = input$file1
    if(is.null(inFile)){
      imgfile  = "www/kast.png"
    }else{
      imgfile = inFile$datapath
    }
    
    img = image_load(imgfile, target_size = c(224,224))
    x = image_to_array(img)
    
    dim(x) <- c(1, dim(x))
    x = imagenet_preprocess_input(x)
    
    # extract features
    features = vgg16_notop %>% predict(x)
    IkeaDistance = calcIkeaSimilarity(features)
    IkeaDistance
  })
  
  
  ###### OUTPUT ELEMENTS ######################################################
  
  #### intro ####
  output$intro <- renderUI({
    list(
      h4("When NOT at an IKEA store, take a picture of what you see, check if Ikea has something similair and then GO TO Ikea"), 
      img(SRC="InstructiesIkea.PNG", height = 340)
    )
  })
  
  
  #### plaatje ####
  output$plaatje <- renderImage({
    
    inFile = input$file1
    print(inFile)
    if (!is.null(inFile))
    {
      
      width  <- session$clientData$output_plaatje_width
      height <- session$clientData$output_plaatje_height
      list(
        src = inFile$datapath,
        width=width,
        height=height
      )
    }
    else
    {
      list(src="www/kast.png")
    }
  },
  deleteFile = FALSE
  )
  
  
  #### ResultaatOut ####
  output$ResultaatOut = renderPrint({
    pp = ProcessImage()
    print(pp)
  })
  
  
  #### ResultaatTabel ####
  output$ResultaatTabel =  renderDataTable({
   
    simies = ProcessImage()
    ImageMetaData2 = ImageMetaData
    
    ImageMetaData2$match = as.numeric(simies)
    ImageMetaData2$image = paste0(
      "<img src='",
      "http://www.ikea.com/nl/nl/images/products/",
      ImageMetaData2$imagefile,
      "'",
      "height='80' width='90' </img>"
    )
    
    ImageMetaData2$link = paste0(
      "<a href='",
      ImageMetaData2$link,
      "' target='_blank'>",
      "'",
      ImageMetaData2$name,
      "'</a>"
    )
    
    finaltable = dplyr::arrange(ImageMetaData2,desc(match)) %>% 
      dplyr::slice(1:input$input_topN) %>%
      dplyr::select(image, link, type2, match, price)
    
    datatable(
      options = list(
        dom = 't',
        autoWidth = FALSE,
        columnDefs = list(list(width = '200px', targets = c(1, 3)))
      ),
      
      escape = FALSE,
      rownames = FALSE, 
      data = finaltable
    ) %>%   formatPercentage('match', 1) 
  })
  
  observeEvent(input$done, {
    stopApp(TRUE)
  })
}


##### SHINY APP CALL ###########################################################

shinyApp(ui, server)
