inspol <- read.csv("~/Coursework/inspol.trunc.csv", header = TRUE)

library(MASS)
library(arm)
library(car)

mmax.glm <- glm(lifeins.amountspent ~ ed.low * ed.med * ed.high * inc.lt30k * inc.30to45k * inc.45to75k * inc.75to122k, family = poisson, data = inspol)

maic.glm <- stepAIC(mmax.glm)

inspol.glm <-  glm(formula = lifeins.amountspent ~ ed.med + ed.high + inc.30to45k + 
                     inc.45to75k + inc.75to122k + lifeins.policiesheld + ed.med:lifeins.policiesheld + 
                     ed.high:lifeins.policiesheld, family = quasipoisson, data = inspol)

summary(inspol.glm)

coefplot(inspol.glm)
