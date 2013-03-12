inspol <- read.csv("inspol.trunc.csv", header = TRUE)

library(MASS)
library(arm)
library(car)

mmax.glm <- glm(lifeins.amountspent ~ ed.low * ed.med * ed.high * inc.lt30k * inc.30to45k * inc.45to75k * inc.75to122k, family = poisson, data = inspol)

maic.glm <- stepAIC(mmax.glm, direction = "both")

inspol.glm <-  glm(formula = lifeins.amountspent ~ avg.age + ed.low * ed.med * ed.high * inc.lt30k * inc.30to45k *
                     inc.45to75k + inc.75to122k + inc.mt123k, family = poisson, data = inspol)

summary(inspol.glm)

coefplot::coefplot(inspol.glm, intercept = FALSE, innerCI = 2, outerCI = 0)

stepAIC(inspol.glm, direction = "both")

inspol.glm1 <- glm(formula = lifeins.amountspent ~ ed.low + ed.med + ed.high + 
                     inc.lt30k + inc.30to45k + inc.45to75k + inc.75to122k + inc.mt123k + ed.low:ed.high + 
                     ed.med:ed.high + ed.low:inc.lt30k + ed.med:inc.lt30k + ed.high:inc.lt30k + 
                     ed.low:inc.30to45k + ed.med:inc.30to45k + inc.lt30k:inc.30to45k + 
                     ed.low:inc.45to75k + ed.med:inc.45to75k + ed.high:inc.45to75k + 
                     inc.lt30k:inc.45to75k + inc.30to45k:inc.45to75k + ed.low:ed.high:inc.lt30k + 
                     ed.med:ed.high:inc.lt30k + ed.med:inc.lt30k:inc.30to45k + 
                     ed.low:ed.high:inc.45to75k + ed.med:inc.lt30k:inc.45to75k + 
                     ed.med:inc.30to45k:inc.45to75k + inc.lt30k:inc.30to45k:inc.45to75k + 
                     ed.med:inc.lt30k:inc.30to45k:inc.45to75k, family = poisson, 
                   data = inspol)

pairs(inspol)

coefplot::coefplot(inspol.glm1, intercept = FALSE, outerCI = 0)