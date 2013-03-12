logcoefplot.lm <- function(model, title="Coefficient Plot", xlab="Value", ylab="Coefficient", 
                           innerCI=1, outerCI=2, lwdInner=1, lwdOuter=0,  color="blue",
                           cex=.8, textAngle=0, numberAngle=0,
                           zeroColor="grey", zeroLWD=1, zeroType=2,
                           facet=FALSE, scales="free",
                           sort=c("natural", "normal", "magnitude", "size", "alphabetical"), decreasing=FALSE,
                           numeric=FALSE, fillColor="grey", alpha=1/2,
                           horizontal=FALSE, factors=NULL, only=NULL, shorten=TRUE,
                           intercept=TRUE, plot=TRUE, ...)
{
  theDots <- list(...)
  
  # get variables that have multiple options
  sort <- match.arg(sort)
  
  ## if they are treating a factor as numeric, then they must specify exactly one factor
  ## hopefully this will soon expand to listing multiple factors
  if(numeric & length(factors)!=1)
  {
    stop("When treating a factor variable as numeric, the specific factor must be specified using \"factors\"")
  }else if(numeric)
  {
    # if we are treating it as numeric, then the sorting should be numeric
    sort="alpha"
  }
  
  if(length(factors) > 0)
  {
    factors <- subSpecials(factors)
  }
  
  modelCI <- buildModelCI(model, outerCI=outerCI, innerCI=innerCI, intercept=intercept, numeric=numeric, sort=sort, decreasing=decreasing, factors=factors, only=only, shorten=shorten, ...)
  cdplot <- modelCI
  i<-0
  while(i<length(cdplot$LowOuter)) {
    i <- i+1
    if(cdplot$LowOuter[i] <= 0 ) {
      cdplot$LowOuter[i] <- (-1)*log(abs(cdplot$LowOuter[i]))
    } else {
      cdplot$LowOuter[i] <- log(cdplot$LowOuter[i])
    }
  }
  i<-0
  while(i<length(cdplot$HighOuter)) {
    i <- i+1
    if(cdplot$HighOuter[i] <= 0 ) {
      cdplot$HighOuter[i] <- (-1)*log(abs(cdplot$HighOuter[i]))
    } else {
      cdplot$HighOuter[i] <- log(cdplot$HighOuter[i])
    }
  }
  i<-0
  while(i<length(cdplot$LowInner)) {
    i <- i+1
    if(cdplot$LowInner[i] <= 0 ) {
      cdplot$LowInner[i] <- (-1)*log(abs(cdplot$LowInner[i]))
    } else {
      cdplot$LowInner[i] <- log(cdplot$LowInner[i])
    }
  }
  i<-0
  while(i<length(cdplot$HighInner)) {
    i <- i+1
    if(cdplot$HighInner[i] <= 0 ) {
      cdplot$HighInner[i] <- (-1)*log(abs(cdplot$HighInner[i]))
    } else {
      cdplot$HighInner[i] <- log(cdplot$HighInner[i])
    }
  }	
  i<-0
  while(i<length(cdplot$Coef)) {
    i <- i+1
    if(cdplot$Coef[i] <= 0 ) {
      cdplot$Coef[i] <- (-1)*log(abs(cdplot$Coef[i]))
    } else {
      cdplot$Coef[i] <- log(cdplot$Coef[i])
    }
  }
  
  modelCI <- cdplot
  rm(cdplot)
  
  if(numeric)
  {
    modelCI$CoefShort <- as.numeric(as.character(modelCI$CoefShort))
  }
  
  # which columns will be kept in the melted data.frame
  keepCols <- c("LowOuter", "HighOuter", "LowInner", "HighInner", "Coef", "Checkers", "CoefShort")
  
  modelMelting <- meltModelCI(modelCI=modelCI, keepCols=keepCols, id.vars=c("CoefShort", "Checkers"), 
                              variable.name="Type", value.name="value", outerCols=c("LowOuter", "HighOuter"), innerCols=c("LowInner", "HighInner")) 
  
  
  modelMelt <- modelMelting$modelMelt 
  modelMeltInner <- modelMelting$modelMeltInner 
  modelMeltOuter <- modelMelting$modelMeltOuter 
  rm(modelMelting);      # housekeeping
  
  ## if we are to make the plot
  if(plot)
  {
    p <- buildPlotting.lm(modelCI=modelCI,
                          modelMeltInner=modelMeltInner, modelMeltOuter=modelMeltOuter,
                          title=title, xlab=xlab, ylab=ylab,
                          lwdInner=lwdInner, lwdOuter=lwdOuter, color=color, cex=cex, textAngle=textAngle, 
                          numberAngle=numberAngle, zeroColor=zeroColor, zeroLWD=zeroLWD, outerCI=outerCI, innerCI=innerCI, multi=FALSE,
                          zeroType=zeroType, numeric=numeric, fillColor=fillColor, alpha=alpha, 
                          horizontal=horizontal, facet=facet, scales=scales)
    
    rm(modelCI);    	# housekeeping
    return(p)		# return the ggplot object
  }else
  {
    #rm(modelMeltOuter, modelMeltInner); gc()		# housekeeping
    return(modelCI)
  }
}

## Utilities
## Written by Jared P. Lander
## See LISCENSE for copyright information


## @modelFactorVars: (character vector) names of variables that are factors
## @modelModel: (model.matrix) the model.matrix from the model, I would like this to be changed to accept a smaller set of the model.matrix so there is less data being passed arounf
## @modelCoefs: (character vector) the coefficient names that will be matched and shortened
## @shorten:  (logical or character vector) if true all variables will be shortened, if false, none will be (to save computation), if a character vector, only the ones listed will be shortened, the other will remain (this may get VERY complicated
## @factors: (character vector) a list of vectors to work with if we are only interested in a few
## @only: (logical) if factors restricts what we are looking at then decide if we want just that variable or the stuff it interacts with too
## have to finish dealing with only showing some factors while also shortening some, all or none
##      should be done! Yay!
buildFactorDF <- function(modelFactorVars, modelModel, modelCoefs, shorten=TRUE, factors=NULL, only=NULL)
{
  # if we are only looking for some factors, just check those saving time on the rest
  # needs to be changed to work with exclude
  #      if(!is.null(factors))
  #      {
  #          modelFactorVars <- factors
  #      }
  
  # build a data.frame that matches each factor variable with it's levels
  varDFTemp <- adply(modelFactorVars, 1, function(x, modelD) { expand.grid(x, extractLevels(x, modelD), stringsAsFactors=FALSE) }, modelModel)  ## Build a frame of the variables and the coefficient names for the factor variables
  names(varDFTemp)[2:3] <- c("Var", "Pivot")		## give good names to the frame
  
  # match each level to every coefficient (factor or numeric)
  varDF <- expand.grid(varDFTemp$Pivot, modelCoefs, stringsAsFactors=FALSE)
  names(varDF)[1:2] <- c("Pivot", "Coef")		## give good names to the frame
  
  # join the two data.frames so we have variable name, levels name and coefficient names
  varDF <- join(varDF, varDFTemp, by="Pivot")
  
  rm(varDFTemp); # housekeeping
  
  ## create columns to hold altered versions of the variable and pivot, it replaces special characters with their excaped versions
  varDF$PivotAlter <- varDF$Pivot
  varDF$VarAlter <- varDF$Var
  
  ## the special characters and their escaped equivalents
  specials <- c("!", "(", ")", "-", "=", ".")
  
  ## go through and do the replacing
  alterList <- subSpecials(varDF$VarAlter, varDF$PivotAlter, specialChars=specials)
  
  ## put the subbed values back
  varDF$VarAlter <- alterList[[1]]
  varDF$PivotAlter <- alterList[[2]]
  
  rm(alterList); # housekeeping
  
  
  # set up a column to keep track of which combinations are good
  varDF$Valid<- NA
  
  # the short names of the coefficients
  varDF$CoefShort <- NA
  
  # see if the coefficient is equivalent to the variable
  varDF <- ddply(.data=varDF, .variables="PivotAlter", .fun=function(DF) { DF$Valid=regexpr(unique(DF$PivotAlter), DF$Coef, ignore.case=FALSE); return(DF) })
  
  # just take the ones that match
  varDF <- varDF[varDF$Valid > 0, ]
  
  varDF$VarCheck <- varDF$VarAlter
  
  ## if a list of variables to shorten was given, then make sure that the other variable names won't be subbed out
  if(identical(class(shorten), "character"))      # maybe this should be class(shorten) == "character" instead to make things safer?
  {
    # make the ones that aren't listed "" so that they won't be subbed out
    varDF[!varDF$Var %in% shorten, "VarAlter"] <- ""
  }
  
  ## group the variable names to sub out with a "|" between each so any will be subbed out
  ## this now creates two variables like that
  ## Subbers is used for the coefficient shortening
  ## Checkers is used for narrowing down the the variables
  varDF <- ddply(varDF, .(Coef), function(vect, namer, checker, collapse, keepers) { vect$Subbers <- paste(vect[, c(namer)], collapse=collapse); vect$Checkers <- paste(unique(vect[, c(checker)]), collapse=collapse); return(vect[1, keepers]) }, namer="VarAlter", checker="VarCheck", collapse="|", keepers=c("Var", "Coef", "Subbers", "Checkers", "CoefShort"))
  #varDF <- ddply(varDF, .(Coef), function(vect, namer, checker, collapse, keepers) { vect$Subbers <- paste(vect[, c(namer)], collapse=collapse); vect$Checkers <- paste(vect[, c(checker)], collapse=collapse); return(vect[1, keepers]) }, namer="VarAlter", checker="VarCheck", collapse="|", keepers=c("Var", "Coef", "Subbers", "Checkers", "CoefShort"))
  
  ## if only certain factors are to be shown, narrow down the list to them
  if(!is.null(factors))
  {
    theCheckers <- strsplit(x=varDF$Checkers, split="|", fixed=TRUE)
    
    ## if they only want that variable and not it's interactions
    if(identical(only, TRUE))
    {
      varDF <- varDF[varDF$Checkers %in% factors, ]
    }else
    {
      ## if any of the variables are in the factors to keep then keep it
      ######################
      ## need to adjust it so the user can specify just the interaction of factors, and not the factors themselves
      theKeepers <- laply(theCheckers, function(x, toCheck) { any(x %in% toCheck) }, toCheck=factors)
      varDF <- varDF[theKeepers, ]
      rm(theKeepers);
    }
    
    rm(theCheckers);
  }
  
  # if we are not supposed to shorten the coefficients at all (shorten==FALSE) then just swap Coef into CoefShort
  # this can be done so that the caller function just grabs Coef instead of CoefShort
  # would be nice if this can be done higher up so not as much processing needs to be done
  if(identical(shorten, FALSE))
  {
    varDF$CoefShort <- varDF$Coef
    return(varDF[, c("Var", "Checkers", "Coef", "CoefShort")])
  }
  
  # now sub out the subbers from the coef to make coef short
  varDF <- ddply(varDF, .(Subbers), function(DF) { DF$CoefShort <- gsub(paste("(^|:)", "(", unique(DF$Subbers), ")", sep=""), "\\1", DF$Coef); return(DF) } )
  
  # return the results
  return(varDF[, c("Var", "Checkers", "Coef", "CoefShort")])
}


## get the levels of factor variables
## @varName:  the variable to pay attention to
## @modelModel:  the model of interest
extractLevels <- function(varName, modelModel)
{
  # put the variable name in front of the level
  paste(varName, levels(factor(modelModel[[varName]])), sep="")
}

# have to get the levels from the coef names
# factors and only not needed because that is already taken care of previously
## ALMOST IDENTICAL to buildFactorDF except in the way it does expand.grid
##          would be awesome to combine the two
rxVarMatcher <- function(modelFactorVars, modelCoefNames, modelCoefs, shorten=TRUE, factors=NULL, only=NULL)
{
  ## match a factor var to those that are just that var or interaction with a numeric
  ## do it for each factor var
  # then will find combinations
  # put each factor var with each coefficient
  varDF <- expand.grid(modelFactorVars, modelCoefNames, stringsAsFactors=FALSE)
  names(varDF) <- c("Var", "Coef")
  
  ## check if the variable matches the coef it is paired with
  # create columns to hold altered versions of the variable and pivot, it replaces special characters with their excaped versions
  varDF$VarAlter <- varDF$Var
  
  ## the special characters and their escaped equivalents
  specials <- c("!", "(", ")", "-", "=", ".")
  
  # go through and do the replacing
  alterList <- subSpecials(varDF$VarAlter, specialChars=specials)
  
  # put the subbed values back
  varDF$VarAlter <- alterList[[1]]
  varDF$VarCheck <- varDF$VarAlter
  varDF$CoefShort <- NA
  
  rm(alterList);   # housekeeping
  
  # now check VarAlter against coef
  varDF <- ddply(varDF, .variables="Var", .fun=function(DF) { DF$Valid <- regexpr(pattern=paste("(^| for |, )(", unique(DF$VarAlter), ")=", sep=""), text=DF$Coef); return(DF) })
  
  # only keep the valid ones
  varDF <- varDF[varDF$Valid != -1, ]
  
  ## if a list of variables to shorten was given, then make sure that the other variable names won't be subbed out
  if(identical(class(shorten), "character"))      # maybe this should be class(shorten) == "character" instead to make things safer?
  {
    # make the ones that aren't listed "" so that they won't be subbed out
    varDF[!varDF$Var %in% shorten, "VarAlter"] <- ""
  }
  
  ## group the variable names to sub out with a "|" between each so any will be subbed out
  ## this now creates two variables like that
  ## Subbers is used for the coefficient shortening
  ## Checkers is used for narrowing down the the variables
  varDF <- ddply(varDF, .(Coef), function(vect, namer, checker, collapse, keepers) { vect$Subbers <- paste(vect[, c(namer)], collapse=collapse); vect$Checkers <- paste(vect[, c(checker)], collapse=collapse); return(vect[1, keepers]) }, namer="VarAlter", checker="VarCheck", collapse="|", keepers=c("Var", "Coef", "Subbers", "Checkers", "CoefShort"))
  
  # if we are not supposed to shorten the coefficients at all (shorten==FALSE) then just swap Coef into CoefShort
  # this can be done so that the caller function just grabs Coef instead of CoefShort
  # would be nice if this can be done higher up so not as much processing needs to be done
  if(identical(shorten, FALSE))
  {
    varDF$CoefShort <- varDF$Coef
    return(varDF[, c("Var", "Checkers", "Coef", "CoefShort")])
  }
  
  # do the shortening
  varDF <- ddply(varDF, .(Subbers), function(DF) { DF$CoefShort <- gsub(paste("(^|, | for )", "(", unique(DF$Subbers), ")=", sep=""), "\\1", DF$Coef); return(DF) } )
  
  # return the results
  return(varDF[, c("Var", "Checkers", "Coef", "CoefShort")])
  
  #return(varDF)
}

#' Build data.frame for plotting
#'
#' Builds a data.frame that is appropriate for plotting coefficients
#'
#' This is the workhorse for coefplot, it get's the data all prepared
#'
#' \code{factors} Vector of factor variables that will be the only ones shown
#'
#' \code{only} logical; If factors has a value this determines how interactions are treated.  True means just that variable will be shown and not its interactions.  False means interactions will be included.
#'
#' \code{shorten} logical or character; If \code{FALSE} then coefficients for factor levels will include their variable name.  If \code{TRUE} coefficients for factor levels will be stripped of their variable names.  If a character vector of variables only coefficients for factor levels associated with those variables will the variable names stripped.
#'
#' @aliases buildModelCI
#' @author Jared P. Lander www.jaredlander.com
#' @param model The fitted model to build information on
#' @param innerCI How wide the inner confidence interval should be, normally 1 standard deviation.  If 0, then there will be no inner confidence interval.
#' @param outerCI How wide the outer confidence interval should be, normally 2 standard deviations.  If 0, then there will be no outer confidence interval.
#' @param sort Determines the sort order of the coefficients.  Possible values are c("natural", "normal", "magnitude", "size", "alphabetical")
#' @param decreasing logical; Whether the coefficients should be ascending or descending
#' @param numeric logical; If true and factors has exactly one value, then it is displayed in a horizontal graph with constinuous confidence bounds.
#' @param intercept logical; Whether the Intercept coefficient should be plotted
#' @param \dots See Details for information on \code{factors}, \code{only} and \code{shorten}
#' @param name A name for the model, if NULL the call will be used
## @param multi logical, If \code{TRUE} a column is added denoting which model the modelCI is for
## @param factors Vector of factor variables that will be the only ones shown
## @param only logical; If factors has a value this determines how interactions are treated.  True means just that variable will be shown and not its interactions.  False means interactions will be included.
## @param shorten logical or character; If \code{FALSE} then coefficients for factor levels will include their variable name.  If \code{TRUE} coefficients for factor levels will be stripped of their variable names.  If a character vector of variables only coefficients for factor levels associated with those variables will the variable names stripped.
#' @return Otherwise a \code{\link{data.frame}} listing coeffcients and confidence bands is returned.
#' @seealso \code{\link{coefplot}} \code{\link{multiplot}}
#' @examples
#'
#' data(diamonds)
#' model1 <- lm(price ~ carat + cut, data=diamonds)
#' model2 <- lm(price ~ carat, data=diamonds)
#' model3 <- lm(price ~ carat + cut + color, data=diamonds)
#' coefplot:::buildModelCI(model1)
#' #coefplot(model1)
#' #coefplot(model2)
#' #coefplot(model3)
#' #coefplot(model3, factors="cut")
#' #coefplot(model3, factors="cut", numeric=T)
#' #coefplot(model3, shorten="cut")
#'
buildModelCI <- function(model, outerCI=2, innerCI=1, intercept=TRUE, numeric=FALSE, sort=c("natural", "normal", "magnitude", "size", "alphabetical"), decreasing=TRUE, name=NULL, ...)
{
  # get variables that have multiple options
  sort <- match.arg(sort)
  
  # get the information on the model
  modelInfo <- getModelInfo(model, ...)
  
  # get the coef and SE from modelInfo
  modelCoef <- modelInfo$coef             # the coefficients
  modelSE <- modelInfo$SE                 # the standard errors
  modelMatched <- modelInfo$matchedVars   # the data.frame matching coefficients to variables
  
  # all the info about the coefficients
  modelCI <- data.frame(LowOuter=modelCoef - outerCI*modelSE, HighOuter=modelCoef + outerCI*modelSE, LowInner=modelCoef - innerCI*modelSE, HighInner=modelCoef + innerCI*modelSE, Coef=modelCoef) # build a data.frame of the confidence bounds and original coefficients
  names(modelCI) <- c("LowOuter", "HighOuter", "LowInner", "HighInner", "Coef")
  
  modelCI$Name <- rownames(modelCI)	## grab the coefficient names into the data.frame
  
  ## join the factor coefficient info to the data.frame holding the coefficient info
  modelMatcher <- modelMatched[, c("Checkers", "Coef", "CoefShort")]
  names(modelMatcher)[2] <- "Name"
  modelMatcher$Name <- as.character(modelMatcher$Name)
  modelCI <- join(modelCI, modelMatcher, by="Name")
  
  rm(modelMatcher);		# housekeeping
  
  # since we will be using coef short for the coefficient labels the numeric variables need to be given CoefShort elements which will be taken from the Name column
  modelCI$CoefShort <- ifelse(is.na(modelCI$CoefShort), modelCI$Name, modelCI$CoefShort)
  
  # Similar for the Checkers column
  
  modelCI$Checkers <- ifelse(is.na(modelCI$Checkers), "Numeric", modelCI$Checkers)
  
  ## if the intercept is not to be shown, then remove it
  if(intercept == FALSE | numeric)		## remove the intercept if so desired
  {
    theIntercept <- which(modelCI$Name == "(Intercept)")	# find the variable that is the intercept
    # make sure the intercept is actually present, if so, remove it
    if(length(theIntercept) > 0)
    {
      # remove the intercept
      modelCI <- modelCI[-theIntercept, ]
    }
    rm(theIntercept);		# housekeeping
  }
  
  # if there are no good coefficients, then stop
  if(nrow(modelCI) == 0)
  {
    stop("There are no valid coeficients to plot", call.=FALSE)
  }
  
  ## possible orderings of the coefficients
  ordering <- switch(sort,
                     natural=order(1:nrow(modelCI), decreasing=decreasing), 	# the way the data came in
                     normal=order(1:nrow(modelCI), decreasing=decreasing),	# the way the data came in
                     nat=order(1:nrow(modelCI), decreasing=decreasing), 			# the way the data came in
                     magnitude=order(modelCI$Coef, decreasing=decreasing), 		#  size order
                     mag=order(modelCI$Coef, decreasing=decreasing), 			# size order
                     size=order(modelCI$Coef, decreasing=decreasing),			# size order
                     alphabetical=order(modelCI$Name, decreasing=decreasing), 	# alphabetical order
                     alpha=order(modelCI$Name, decreasing=decreasing),			# alphabetical order
                     order(1:nrow(modelCI))		# default, the way it came in
  )
  
  # implement the ordering
  modelCI <- modelCI[ordering, ]
  #return(modelCI)
  #return(modelCI$Name)
  modelCI$CoefShort <- factor(modelCI$CoefShort, levels=modelCI$CoefShort)
  
  # if a name for the model is provided, use it, otherwise use the call
  if(is.null(name))
  {
    modelCI$Model <- as.character(paste(model$call, collapse="_"))
  }else
  {
    modelCI$Model <- name
  }
  
  # convert the pipe in Checkers to a * for better display
  modelCI$Checkers <- gsub("\\|", ":", modelCI$Checkers)
  
  # return the data.frame
  return(modelCI)
}


#' Melt the modelCI
#'
#' Melt a modelCI into a form suitable for plotting
#'
#' \code{\link{buildModelCI}} builds a data.frame for plotting.  This function melts it into plottable form and seperates the coefficient data from the SE data into seprate data.frames
#'
#' @author Jared P. Lander www.jaredlander.com
#' @aliases meltModelCI
#' @seealso \code{\link{coefplot}} \code{\link{buildModelCI}}
#' @param modelCI A \code{\link{data.frame}} as built by \code{\link{buildModelCI}}
#' @param keepCols The columns in modelCI that should be kept as there can be extras
#' @param id.vars The columns to use as ID variables in \code{\link{melt}}
#' @param variable.name Used in \code{\link{melt}} for naming the column that stores the melted variables
#' @param value.name Used in \code{\link{melt}} for naming the column that stores the melted values
#' @param innerCols The columns to be included in the \code{\link{data.frame}} of inner standard errors
#' @param outerCols The columns to be included in the \code{\link{data.frame}} of outer standard errors
#' @return A list consisting of
#' \item{modelMelt}{Melted modelCI with all values}
#' \item{modelMeltOuter}{modelMelt with only values associated with the outer standard errors}
#' \item{modelMeltInner}{modelMelt with only values associated with the inner standard errors}
#' @examples
#'
#' data(diamonds)
#' model1 <- lm(price ~ carat + cut, data=diamonds)
#' modeled <- coefplot:::buildModelCI(model1)
#' coefplot:::meltModelCI(modeled)
#'
meltModelCI <- function(modelCI, keepCols=c("LowOuter", "HighOuter", "LowInner", "HighInner", "Coef", "Checkers", "CoefShort"), 
                        id.vars=c("CoefShort", "Checkers"), variable.name="Type", value.name="value", outerCols=c("LowOuter", "HighOuter"), 
                        innerCols=c("LowInner", "HighInner"))
{
  # melt the data frame so it is suitable for ggplot
  #modelMelt <- reshape2::melt(data=modelCI[ ,keepCols], id.vars=id.vars, variable.name=variable.name, value.name=value.name)
  # change to above line when ggplot2 0.9.0 is released
  modelMelt <- reshape2:::melt.data.frame(data=modelCI[ ,keepCols], id.vars=id.vars, variable.name=variable.name, value.name=value.name)
  
  # just the outerCI info
  modelMeltOuter <- modelMelt[modelMelt$Type %in% outerCols, ]	# pull out the outer (95% default) CI
  
  # just the innerCI info
  modelMeltInner <- modelMelt[modelMelt$Type %in% innerCols, ]	# pull out the inner (68% default) CI
  
  # return the data.frames
  return(list(modelMelt=modelMelt, modelMeltOuter=modelMeltOuter, modelMeltInner=modelMeltInner))
}

#buildPlotting <-function()

#' Coefplot plotting
#'
#' Build ggplot object for coefplot
#'
#' This function builds up the ggplot layer by layer for \code{\link{coefplot.lm}}
#'
#' @author Jared P. Lander www.jaredlander.com
#' @seealso \code{\link{coefplot.lm}} \code{\link{coefplot}} \code{\link{multiplot}}
#' @aliases buildPlotting.lm
#' @param modelCI An object created by \code{\link{buildModelCI}}
#' @param modelMeltInner The inner SE part of the object built by \code{\link{meltModelCI}}
#' @param modelMeltOuter The outer SE part of the object built by \code{\link{meltModelCI}}
#' @param title The name of the plot, if NULL then no name is given
#' @param xlab The x label
#' @param ylab The y label
#' @param innerCI How wide the inner confidence interval should be, normally 1 standard deviation.  If 0, then there will be no inner confidence interval.
#' @param outerCI How wide the outer confidence interval should be, normally 2 standard deviations.  If 0, then there will be no outer confidence interval.
#' @param multi logical; If this is for \code{\link{multiplot}} then dodge the geoms
#' @param lwdInner The thickness of the inner confidence interval
#' @param lwdOuter The thickness of the outer confidence interval
#' @param color The color of the points and lines
#' @param cex The text size multiplier, currently not used
#' @param textAngle The angle for the coefficient labels, 0 is horizontal
#' @param numberAngle The angle for the value labels, 0 is horizontal
#' @param zeroColor The color of the line indicating 0
#' @param zeroLWD The thickness of the 0 line
#' @param zeroType The type of 0 line, 0 will mean no line
#' @param facet logical; If the coefficients should be faceted by the variables, numeric coefficients (including the intercept) will be one facet
#' @param scales The way the axes should be treated in a faceted plot.  Can be c("fixed", "free", "free_x", "free_y")
#' @param numeric logical; If true and factors has exactly one value, then it is displayed in a horizontal graph with constinuous confidence bounds.
#' @param fillColor The color of the confidence bounds for a numeric factor
#' @param alpha The transparency level of the numeric factor's confidence bound
#' @param horizontal logical; If the plot should be displayed horizontally
#' @return a ggplot graph object
#' @examples
#'
#' data(diamonds)
#' model1 <- lm(price ~ carat + cut, data=diamonds)
#' theCI <- coefplot:::buildModelCI(model1)
#' theCIMelt <- coefplot:::meltModelCI(theCI)
#' coefplot:::buildPlotting.lm(theCI, theCIMelt$modelMeltInner, theCIMelt$modelMeltInner)
#'
buildPlotting.lm <- function(modelCI, 
                             modelMeltInner=NULL, modelMeltOuter=NULL, 
                             title="Coefficient Plot", xlab="Value", ylab="Coefficient",
                             lwdInner=1, lwdOuter=0, color="blue",
                             cex=.8, textAngle=0, numberAngle=0, outerCI=2, innerCI=1, multi=FALSE,
                             zeroColor="grey", zeroLWD=1, zeroType=2, numeric=FALSE, fillColor="grey", alpha=1/2,
                             horizontal=FALSE, facet=FALSE, scales="free")
{
  ## build the layer infos
  # outerCI layer
  # first is for a normal coefplot or a faceted multiplot
  # the second is for a single-pane multiplot
  
  outerCIGeom <- list(DisplayOne=geom_line(aes(y=CoefShort, x=value, group=CoefShort), data=modelMeltOuter, colour=color, lwd=lwdOuter),
                      DisplayMany=geom_linerange(aes(ymin=LowOuter, ymax=HighOuter, colour=as.factor(Model)), data=modelCI, lwd=lwdOuter, position=position_dodge(width=1)),
                      None=NULL)
  # innerCI layer
  # first is for a normal coefplot or a faceted multiplot
  # the second is for a single-pane multiplot
  innerCIGeom <- list(DisplayOne=geom_line(aes(y=CoefShort, x=value, group=CoefShort), data=modelMeltInner, colour=color, lwd=lwdInner),
                      DisplayMany=geom_linerange(aes(ymin=LowInner, ymax=HighInner, colour=as.factor(Model)), data=modelCI, lwd=lwdInner, position=position_dodge(width=1)),
                      None=NULL)
  # ribbon layer
  ribbonGeom <- list(None=NULL, geom_ribbon(aes(ymin=LowOuter, ymax=HighOuter, group=Checkers), data=modelCI, fill=fillColor, alpha=alpha, lwd=lwdOuter))
  
  # point layer
  # first is for a normal coefplot or a faceted multiplot
  # the second is for a single-pane multiplot
  pointGeom <- list(DisplayOne=geom_point(colour=color),
                    DisplayMany=geom_point(position=position_dodge(width=1), aes(ymax=Coef, colour=as.factor(Model))),
                    None=NULL)
  
  # faceting info
  faceting <- list(None=NULL, Display=facet_wrap(~Checkers, scales=scales))
  
  if(numeric)
  {
    # numeric (sideways) plot
    p <- ggplot(data=modelCI, aes(y=Coef, x=CoefShort))			# the basics of the plot
    p <- p + geom_hline(yintercept=0, colour=zeroColor, linetype=zeroType, lwd=zeroLWD)		# the zero line
    p <- p + ribbonGeom[[numeric + 1]]		# the ribbon
    p <- p + geom_point(colour=color)						# the points
    p <- p + geom_line(data=modelCI, aes(y=HighOuter, x=CoefShort, group=Checkers), colour=color) +
      geom_line(data=modelCI, aes(y=LowOuter, x=CoefShort, group=Checkers), colour=color)
  }else if(multi)
  {
    # for a multiplot that plots everything in one panel with dodged geoms
    p <- ggplot(data=modelCI, aes(y=Coef, x=CoefShort))			# the basics of the plot
    p <- p + geom_hline(yintercept=0, colour=zeroColor, linetype=zeroType, lwd=zeroLWD)		# the zero line
    p <- p + outerCIGeom[[(outerCI/outerCI) + multi]] +					# the outer CI bars
      innerCIGeom[[innerCI/innerCI + multi]]						# the inner CI bars
    p <- p + pointGeom[[1 + multi]]						# the points
    p <- p + scale_x_discrete()
    p <- p + theme(axis.text.y=element_text(angle=textAngle), axis.text.x=element_text(angle=numberAngle)) + labs(title=title, y=xlab, x=ylab)	# labeling and text info
    p <- p + faceting[[facet + 1]]		# faceting
    p <- p + if(!horizontal) coord_flip()
  }else
  {
    # for a regular coefplot or a multiplot in seperate facets
    p <- ggplot(data=modelCI, aes(x=Coef, y=CoefShort))    		# the basics of the plot
    p <- p + geom_vline(xintercept=0, colour=zeroColor, linetype=zeroType, lwd=zeroLWD)		# the zero line
    p <- p + outerCIGeom[[(outerCI/outerCI)]] +    				# the outer CI bars
      innerCIGeom[[innerCI/innerCI]]						# the inner CI bars
    p <- p + pointGeom[[1]]						# the points
    p <- p + theme(axis.text.y=element_text(angle=textAngle), axis.text.x=element_text(angle=numberAngle)) + labs(title=title, x=xlab, y=ylab)    # labeling and text info
    p <- p + faceting[[facet + 1]]    	# faceting
    p <- p + if(horizontal) coord_flip()
  }
  rm(modelCI);		# housekeeping
  
  return(p)		# return the ggplot object
}

getModelInfo <- function(model, ...)
{
  UseMethod("getModelInfo", model)
}


## Builds all of the info necessary for building the graph
# param model (lm object) the model to be plotted
# param shorten (logical or character vector) logical if all or none of the factors should be shortened, if character then only the variables listed will be shortened
# param factors (character vector) a list of factors to include, if NULL all of them will be included
# param only (logical) if TRUE then only the specified factors will be computed, otherwise the included factors and their interactions will be computed
# param \dots other options
# return Information on the model
#' Model Information
#'
#' Extracts and builds extensive information from lm and glm models
#'
#' Helper function for \code{\link{coefplot}}
#' @author Jared P. Lander
#' @seealso \code{\link{coefplot.lm}}
#' @param model The fitted model with coefficients to be plotted
#' @param factors Vector of factor variables that will be the only ones shown
#' @param only logical; If factors has a value this determines how interactions are treated.  True means just that variable will be shown and not its interactions.  False means interactions will be included.
#' @param shorten logical or character; If \code{FALSE} then coefficients for factor levels will include their variable name.  If \code{TRUE} coefficients for factor levels will be stripped of their variable names.  If a character vector of variables only coefficients for factor levels associated with those variables will the variable names stripped.
#' @param \dots Further arguments
#' @import stringr
#' @rdname getModelInfo.lm
## @method getModelInfo lm
#' @S3method getModelInfo lm
#' @return Information on the model
#' @examples
#'
#' data(diamonds)
#' model1 <- lm(price ~ carat + cut*color, data=diamonds)
#' coefplot(model1)
#'
getModelInfo.lm <- function(model, shorten=TRUE, factors=NULL, only=NULL, ...)
{
  # get the model summary to easily get info out of it
  modelSummary <- summary(model)
  
  ## extract coefficients and standard errors
  coef <- modelSummary$coefficients[, 1]
  SE <- modelSummary$coefficients[, 2]		# gets standard error from summary
  
  varTypes <- attr(model$terms, "dataClasses")			## These are the types of the different variables
  factorVars <- names(varTypes[varTypes %in% c("factor", "other")])    	## The variables that are factor
  
  # store the names of the coefficients
  newList <- names(coef)    	## names of the coefficients
  
  ## if there are some factor variables
  if(length(factorVars) > 0)
  {
    # figure out which variable belongs to each coefficient
    # passing just one row doesn't work
    matchedVars <- buildFactorDF(modelFactorVars=factorVars, modelModel=model$model, modelCoefs=newList, shorten=shorten, factors=factors, only=only)
    
    if(!is.null(factors))
    {
      ## since some factors are not included they must also be removed from coef's and SE's
      remainingFactors <- which(names(coef) %in% matchedVars$Coef)
      coef <- coef[remainingFactors]
      SE <- SE[remainingFactors]
      newList <- newList[remainingFactors]
      rm(remainingFactors); gc()
    }
  }else
  {
    newList <- NA
    matchedVars <- data.frame(Var=NA, Checkers=NA, Coef=NA, CoefShort=NA)
  }
  
  rm(varTypes); gc()		# do some memory cleanup
  
  list(coef=coef, SE=SE, factorVars=factorVars, factorVarsHuman=factorVars, factorCoefs=newList, matchedVars=matchedVars)				## return the coefs and SEs as a named list
}

library(plyr)
library(string)
library(reshape2)
library(useful)