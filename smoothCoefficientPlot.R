SmoothCoefficientPlot <- function(models, modelnames = "", removeintercept = FALSE){
  # models must be a list()
  
  Alphas <- seq(1, 99, 2) / 100
  
  Multiplier <- qnorm(1 - Alphas / 2)
  zzTransparency <<- 1/(length(Multiplier)/4)
  CoefficientTables <- lapply(models, function(x){summary(x)$coef})
  TableRows <- unlist(lapply(CoefficientTables, nrow))
  
  if(modelnames[1] == ""){
    ModelNameLabels <- rep(paste("Model", 1:length(TableRows)), TableRows)
  } else {
    ModelNameLabels <- rep(modelnames, TableRows)
  }
  
  MatrixofModels <- cbind(do.call(rbind, CoefficientTables), ModelNameLabels)
  if(removeintercept == TRUE){
    MatrixofModels <- MatrixofModels[!rownames(MatrixofModels) == "(Intercept)", ]
  }
  MatrixofModels <- data.frame(cbind(rownames(MatrixofModels), MatrixofModels))
  
  MatrixofModels <- data.frame(cbind(MatrixofModels, rep(Multiplier, each = nrow(MatrixofModels))))
  
  colnames(MatrixofModels) <- c("IV", "Estimate", "StandardError", "TValue", "PValue", "ModelName", "Scalar")
  MatrixofModels$IV <- factor(MatrixofModels$IV, levels = MatrixofModels$IV)
  MatrixofModels[, -c(1, 6)] <- apply(MatrixofModels[, -c(1, 6)], 2, function(x){as.numeric(as.character(x))})
  MatrixofModels$Emphasis <- by(1 - seq(0, 1, length = length(Multiplier) + 1)[-1], as.character(round(Multiplier, 5)), mean)[as.character(round(MatrixofModels$Scalar, 5))]
  
  OutputPlot <- qplot(data = MatrixofModels, x = IV, y = Estimate,
                      ymin = Estimate - Scalar * StandardError, ymax = Estimate + Scalar * StandardError,
                      ylab = NULL, xlab = NULL, alpha = I(zzTransparency), colour = I(gray(0)), geom = "blank")
  OutputPlot <- OutputPlot + geom_hline(yintercept = 0, lwd = I(7/12), colour = I(hsv(0/12, 7/12, 7/12)), alpha = I(5/12))
  OutputPlot <- OutputPlot + geom_linerange(data = MatrixofModels, aes(size = 1/Emphasis), alpha = I(zzTransparency), colour = I(gray(0)))
  OutputPlot <- OutputPlot + scale_size_continuous(legend = FALSE)
  OutputPlot <- OutputPlot + facet_grid(~ ModelName) + coord_flip() + geom_point(aes(x = IV, y = Estimate), colour = I(gray(0))) + theme_bw()
  return(OutputPlot)
}