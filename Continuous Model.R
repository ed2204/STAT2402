crimedata <- read.csv("~/Coursework/crimedata.csv", row.names = 8)
head(crimedata)
crimedata$education <- crimedata$education * 100
crimedata$education <- crimedata$education/crimedata$popn * 100
crimedata$spending <- log(crimedata$spending)
crimedata$popdens <- log(crimedata$popdens)
crimedata$popdens <- crimedata$popdens - mean(crimedata$popdens)

head(crimedata)

crimedata.lm1 <- lm(Crime ~ popn + metro + popdens + pov + education + spending, data = crimedata)
crimedata.lm2 <- lm(Crime ~ metro + popdens + pov + education + spending, data = crimedata)
crimedata.lm3 <- lm(Crime ~ popdens + pov + education + spending, data = crimedata)
crimedata.lm4 <- lm(Crime ~ metro + popdens + pov + education + spending, data = crimedata)

summary(crimedata.lm4)

require(arm)

coefplot(crimedata.lm4)

par(mfrow = c(1,1))
plot(crimedata.lm4)

AIC(crimedata.lm3)

# Record number 9 is Washington DC

# http://www.census.gov/prod/1/gen/95statab/law.pdf

## Doing some residual checking

# Looking at the Q-Q plot, everything seems to follow the line
par(mfrow = c(2,2))
plot(crimedata.lm4)
# Looking at residuals vs fitted, there doesn't seem to be heteroscedasticity

require(car)
par(mfrow = c(1,1))
influencePlot(crimedata.lm4, id.n=3)

# Washington DC has a large influnce due to hat-values. Its crime rate compared to popn is very high compared to any others, probably due to the location of the capitol of the USA in this state.
