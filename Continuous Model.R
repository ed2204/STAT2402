crimedata <- read.csv("~/Coursework/crimedata.csv", row.names = 8)
head(crimedata)
crimedata$education <- crimedata$education * 100
crimedata$education <- crimedata$education/crimedata$popn * 100
crimedata$spending <- log(crimedata$spending)
crimedata$popdens <- log(crimedata$popdens)
crimedata$popdens <- crimedata$popdens - mean(crimedata$popdens)

head(crimedata)

# Try a complete model
crimedata.lm1 <- lm(Crime ~ popn + metro + popdens + pov + education + spending, data = crimedata)
# add some interactions
crimedata.lm2 <- lm(Crime ~ popn + metro + popdens + pov + education + spending +
                      popn:metro + popn:popdens, data = crimedata)
# add some interactions
crimedata.lm3 <- lm(Crime ~ Crime ~ popn + metro + popdens + pov + education + 
                      spending + popn:metro + popn:popdens + popn:education, data = crimedata)
# remove popn (rule of 2)
crimedata.lm4 <- lm(Crime ~ metro + popdens + pov + education + spending, data = crimedata)
# add some interaction
crimedata.lm5 <- lm(Crime ~ metro + popdens + pov + education + spending + 
                      popdens:education + popdens:pov, data = crimedata)
# more interaction
crimedata.lm6 <- lm(Crime ~ metro + popdens + pov + education + spending + 
                      popdens:education + popdens:pov + metro:popdens, data = crimedata)
# try re-adding in popn
crimedata.lm7 <- lm(Crime ~ metro + popdens + pov + education + spending + 
                      popdens:education + popdens:pov + metro:popdens + metro:education + 
                      popn, data = crimedata)

summary(crimedata.lm6)

require(arm)

coefplot(crimedata.lm6)

par(mfrow = c(2,2))
plot(crimedata.lm6)

AIC(crimedata.lm6)

# Record number 9 is Washington DC

# http://www.census.gov/prod/1/gen/95statab/law.pdf

## Doing some residual checking

# Looking at the Q-Q plot, everything seems to follow the line
par(mfrow = c(1,1))
plot(crimedata.lm6, which = 2)
# Looking at residuals vs fitted, there doesn't seem to be heteroscedasticity

require(car)

influencePlot(crimedata.lm6, id.n=3)

# Washington DC has a large influnce due to hat-values. Its crime rate compared to popn is very high compared to any others, probably due to the location of the capitol of the USA in this state.