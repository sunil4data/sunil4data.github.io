suppressWarnings(library(tm))
suppressWarnings(require(plyr))
suppressWarnings(require(dplyr))
suppressWarnings(require(data.table))
suppressWarnings(require(quanteda))
suppressWarnings(require(stringr))
suppressWarnings(require(tidyr))

suppressWarnings(library(shiny))

options(shiny.fullstacktrace = TRUE)

##########################################################################################
## Assumption: 
##          ngrams & their probabilities upto to 3-gram are available
##          Input sentence after data cleaning (stopwords, uri, email, twitter tags/handles, etc) should contain at least 2 tokens
##
## Input:
##          data: Input sentence whose completing next word is to be predicted
##          dfProbs.all: Load dfProbs.1g, .2g & .3g data from .rds files and feed in list(dfProbs.1g, .2g & .3g)
##          reRemoveWords: To remove stopwords or not (CAUTION: not removing stopwords has always shown discouraging predictions)
##
## Output: List of ordered Add1Laplace probabilities & SBO scores predicting completing next word
##
## Step 1: Clean input 'data'
## Step 2: Extract P (2nd last word) & Q (last word)
## Step 3: Goal is to form P_Q_Rcandidates trigrams and...
##          find probabilities for each of the Rcandidates...
##              in probs.3g if observed -else- 
##              find backed-off bigram(s) Q_Rcandidates in probs.2g -else-
##              further back-off till unigram(s) Rcandidates in dfProbs.1g
##########################################################################################
calcProbsCompletingNgrams <- function(data, dfProbs.all, rmStopWords) {
  
  if (rmStopWords == TRUE){
    data <- tolower(data) %>% cleanUri %>% cleanTwitterTagsHandles %>% cleanAlphaNumerics %>% removeWords(stopwords()) %>% removePunctuation
  } else
  {
    data <- tolower(data) %>% cleanUri %>% cleanTwitterTagsHandles %>% cleanAlphaNumerics %>% removePunctuation
  }
  
  ## This is to show in the UI
  cleanedInput <<- data
  
  toks <- tokens(data, remove_numbers=TRUE, remove_url = TRUE)
  toks <- unlist(toks[[1]])
  
  ## "UNK" to account for missing tokens...
  ## ... due to either
  ## 1. removed stop words -or- 
  ## 2. pruned low-freq tokens -or-
  ## 3. unseen tokens in input sentence whose next word is being predicted
  toks[!(toks %in% rownames(dfProbs.all[[1]]))] <- "UNK"
  nToks <- length(toks)
  
  ## P: 2nd last word
  ## Q: Last word
  ## R: All vocabulary words including UNK
  if(nToks == 0) { P <- "UNK"; Q <- "UNK"}
  if(nToks == 1) { P <- "UNK"; Q <- toks[nToks] }
  if(nToks > 1) { P <- toks[nToks-1]; Q <- toks[nToks] }
  R <- rownames(dfProbs.all[[1]])
  R <- R[-length(R)]
  
  PQR <- paste(P, Q, R, sep="_")
  QR <- paste(Q, R, sep="_")
  
  ## P_Q_predCandidates seen in 3-gram
  id.PQR <- (PQR %in% rownames(dfProbs.all[[3]]))
  
  ## P_Q_predCandidates NOT present; Q_predCandidates present
  id.QR <- (!id.PQR) & (QR %in% rownames(dfProbs.all[[2]]))
  
  ## P_Q_predCandidates NOT present; Q_predCandidates NOT present; NOTE that predCandidates are always present
  id.R <- (!id.PQR) & (!(QR %in% rownames(dfProbs.all[[2]]))) & (R %in% rownames(dfProbs.all[[1]]))
  
  matchedMle <- matrix(NA,length(PQR),1)
  matchedProbAdd1Laplace <- matrix(NA,length(PQR),1)
  
  ## Fill the probabilities corresponding to available/seen P_Q_predCandidates => hence no "backoff weight"
  ## x0.4 for one backoff & x*2*0.4 for two backoff
  if(sum(id.PQR)>0) { 
    matchedMle[id.PQR] <- dfProbs.all[[3]][PQR[id.PQR], "mle"] 
    rownames(matchedMle)[id.PQR] <- PQR[id.PQR]
    
    matchedProbAdd1Laplace[id.PQR] <- dfProbs.all[[3]][PQR[id.PQR], "probAdd1Laplace"] 
    rownames(matchedProbAdd1Laplace)[id.PQR] <- PQR[id.PQR]
  }
  if(sum(id.QR)>0) { 
    matchedMle[id.QR] <- dfProbs.all[[2]][QR[id.QR], "mle"] * 0.4 
    rownames(matchedMle)[id.QR] <- QR[id.QR]
    
    matchedProbAdd1Laplace[id.QR] <- dfProbs.all[[2]][QR[id.QR], "probAdd1Laplace"]
    rownames(matchedProbAdd1Laplace)[id.QR] <- QR[id.QR]
  }
  if(sum(id.R)>0) { 
    matchedMle[id.R] <- dfProbs.all[[1]][R[id.R], "mle"] * 0.4 * 0.4 
    rownames(matchedMle)[id.R] <- R[id.R]
    
    matchedProbAdd1Laplace[id.R] <- dfProbs.all[[1]][R[id.R], "probAdd1Laplace"]
    rownames(matchedProbAdd1Laplace)[id.R] <- R[id.R]
  }
  
  dfPredWords <- data.frame(rownames(matchedMle), R, matchedMle, matchedProbAdd1Laplace, stringsAsFactors=FALSE)
  colnames(dfPredWords) <- c("ngram", "predictedWord", "scoreStupidBackOff", "probsAdd1Laplace")
  
  dfPredWordsSBO <- dfPredWords[order(dfPredWords[,"scoreStupidBackOff"], decreasing=TRUE), ]
  dfPredWordsAdd1Lapce <- dfPredWords[order(dfPredWords[,"probsAdd1Laplace"], decreasing=TRUE), ]
  
  rownames(dfPredWordsSBO) <- NULL
  #head(dfPredWordsSBO, 6)
  
  rownames(dfPredWordsAdd1Lapce) <- NULL
  #head(dfPredWordsAdd1Lapce, 6)
  
  list(dfPredWordsSBO, dfPredWordsAdd1Lapce)
}


##########################################################################################
## Assumption: 'data' as-isread from files
## Input: 'text' read as-is from source
## output: cleaned non-empty sentences
##########################################################################################
inputToCleanedSetences = function(text, removeStopWords) {
  
  # Split each document into sentences list
  text <- tokens(text, what = "sentence")
  
  #Split multi-sentence list document into single-sentence document(s)
  text <- unlist(text)
  
  # Punctuation removal should happen after splitting multi-sentences document into single-sentence documents
  if (removeStopWords == TRUE) {
    text <- tolower(text) %>% cleanUri %>% cleanTwitterTagsHandles %>% cleanAlphaNumerics %>% removeWords(stopwords()) %>% removePunctuation
  }
  else {    
    text <- tolower(text) %>% cleanUri %>% cleanTwitterTagsHandles %>% cleanAlphaNumerics %>% removePunctuation
  }
  
  # Remove blank lines
  emptyIndices <- grep("^$", text)
  if(length(emptyIndices)) { text <- text[-emptyIndices] }
  
  text
}

cleanUri <- function(text){
  ## remove html/ftp url (NOTE that Quanteda removeUrl takes care of this during tokens or dfm creation)
  #text <- gsub("?(f|ht)tp(s?)://(.*)[.][a-z]+", "", text) 
  ## remove e-mail adresses
  text <- gsub("[[:alnum:].-]+@[[:alnum:].-]+", "", text) 
  return(text)
}

cleanTwitterTagsHandles <- function(text){
  ## remove twitter handles (NOTE that Quanteda removeTwitter removes only '#@' char)
  text <- gsub("@\\S+", "", text)
  ## remove twitter hashtags
  text <- gsub("#\\S+", "", text)
  return(text)
}

cleanAlphaNumerics <- function(text){
  ## split "hello-world" or "hello_world" into "hello world"
  ## CAUTION: Perform this before below cleanup
  text <- gsub("[_-]", " ", text) 
  
  ## Remove alpha-num words like 1sr 2nd 100A word2
  ## NOTE that Quanteda removeNumber removes just the num from alpha-num
  text <- gsub("[a-zA-Z0-9]*[0-9][a-zA-Z0-9]*", "", text) 
  
  return(text)
}

dfProbs.1g <- readRDS("1gramPreLearnedModel.rds")
dfProbs.2g <- readRDS("2gramPreLearnedModel.rds")
dfProbs.3g <- readRDS("3gramPreLearnedModel.rds")
dfProbs.all <- list(dfProbs.1g, dfProbs.2g, dfProbs.3g)

cleanedInput <<- ""

shinyServer(function(input, output) {
  output$txtElapsedTime <- renderText({

    ## To force dependency on 'Predict' button
    input$predictButton

    ## To isolate REACTIVE processing from any changes in 'inputString' until user presses 'Predict' button
    strInputSentence <- isolate(input$inputString)

    ## To ensure that app launch does not process empty 'inputString'
    #req(input$inputString)   #isolate feature is defeated
    
    rmStopWords <- TRUE
    tPredict <- system.time(probsCompletingNgrams <- calcProbsCompletingNgrams(strInputSentence, dfProbs.all, rmStopWords))

    dfShowWordsNgrams <- data.frame(ngram = probsCompletingNgrams[[1]][1:6, "ngram"],  scoreSBO= probsCompletingNgrams[[1]][1:6, "scoreStupidBackOff"])
    colnames(dfShowWordsNgrams) <- c("Source Ngram", "SBO Score")
    rownames(dfShowWordsNgrams) <- probsCompletingNgrams[[1]][1:6, "predictedWord"]
    
    
    output$predictedWords <- renderPrint(dfShowWordsNgrams)

    output$txtCleanedInputSentence <- renderText({cleanedInput})

    #result
    as.double(tPredict["elapsed"])
  });
}
)