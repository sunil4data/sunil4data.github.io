suppressWarnings(library(shiny))
suppressWarnings(library(markdown))
shinyUI(navbarPage("Data Science Capstone Final Project",
    tabPanel("Next Word Prediction",
            HTML("<strong>Author: Sunil Kumar</strong>"),
            br(),
            HTML("<strong>Date: 11/Aug/2018</strong>"),
            br(),
            
            # Sidebar
            sidebarLayout(
              sidebarPanel(
                helpText("Enter a partially complete sentence & press \'Predict\' button to begin the next word prediction"),
                br(),
                helpText("NOTE that STOP WORDS are removed from \'training\' as well as \'input sentence\'!"),
                br(),
                textInput("inputString", "Enter a partial sentence here",value = "learning new"),
                br(),
                actionButton("predictButton", "Predict"),
                br(),
                br(),
                br(),
                br()
              ),
              
              mainPanel(
                h2("List of 6 most probable \'next word\' with corresponding \'source ngram\' & \'Stupid Backoff score\'"),
                
                verbatimTextOutput("predictedWords"),
                
                strong("Cleaned Input Sentence:"),
                tags$style(type='text/css', '#text1 {background-color: rgba(255,255,0,0.40); color: blue;}'), 
                textOutput('txtCleanedInputSentence'),
                
                br(),
                
                strong("Elapsed Time (sec):"),
                tags$style(type='text/css', '#text2 {background-color: rgba(255,255,0,0.40); color: black;}'),
                textOutput('txtElapsedTime')
              )
            )
            
    ),
    tabPanel("Instructions",
            mainPanel(
              includeMarkdown("instructions.md")
            )
    ),
    tabPanel("Resources",
             mainPanel(
               includeMarkdown("resources.md")
             )
    )
  )
)
