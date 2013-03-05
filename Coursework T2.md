

STAT2402 Regression Modelling: Term 2 Coursework
=
Edward Strang
-
***

Continous Dataset (crimedata)
-
The continuous dataset used was the #crimedata# dataset, an abstract of the 1993 US census. There are 51 observations (states) of 7 variables, covering population, population density, metropolitan population, education levels and spending on crime, as well as crime rates. Whilst modelling, I have looked at the relationship between crime rates and the other variables, and tried to see if there is a discernable link between them and crime rates. This analysis could be used to help bring crime rates down. Another application could be to try and predict crime rates in another similar country, but this could be interpolating outside the range of the data, and produce incorrect conclusions. Below is an abstract of the first few lines of the dataset.


```
  Crime  popn  pov metro   popdens education spending
1  4879  4181 17.4  67.4  0.004134     86.10    5.204
2  5568   598  9.1  41.8 -4.313354     93.65    4.905
3  7432  3945 15.4  84.7 -0.864811     77.82    5.844
4  4811  2426 20.0  44.7 -0.567064    104.70    4.779
5  6457 31217 18.2  96.7  0.890153     83.29    8.023
6  5527  3564  9.9  81.8 -0.870608     89.23    5.583
```


During the fitting of the model, I have considered the real-life relationships between variables to try and fit a model which will best fit the actual data I have. For example, we could hypothesise that in metropolitan areas, there is a higher crime rate, as more people live close proximity. Also, the metropolitan population could influence the total population, as we could postulate that if there is a high number of cities in a state, there is a higher population in that state.

I started off modelling applying a fairly full model, with all the variables in:
$$Y_i = \beta_1 + \beta_2x_{2i} + \beta_3x_{3i} + \beta_4x_{4i} + \beta_5x_{5i} + \beta_6x_{6i} + \beta_7x_{7i}$$

where: 
* $x_{2i}$ is the population for the $i^{th}$ state,
* $x_{3i}$ is the log of the population density (mean centered) for the $i*^{th}$ state,
* $x_{4i}$ is the metropolitan population for the $i^{th}$ state,
* $x_{5i}$ is the poverty level for the $i*^{th}$ state,* $x_{2i}$ is the population for the $i^{th}$ state,
* $x_{6i}$ is the education level for the $i*^{th}$ state,
* and $x_{7i}$ is the log of spending on the department of corrections for the $i^{th}$ state.

I checked the model fit using the adjusted $R^2$ statistic. I also looked at the coefplot (Fig. 1), which plots each coefficient and it's standard error (as well as twice the standard error). This is also our 95% Confidence Interval for each coefficient. This allows us to remove coefficients from the model which don't appear to have an effect on the crime rate.

![plot of chunk unnamed-chunk-3](figure/unnamed-chunk-3.png) 


We can view the $R^2$ statistic using display()

```r
display(crimedata.lm.full)
```

```
## lm(formula = Crime ~ popn + metro + popdens + pov + education + 
##     spending, data = crimedata)
##             coef.est coef.se
## (Intercept) 1153.11  2163.18
## popn          -0.12     0.04
## metro         30.24    14.16
## popdens     -428.17   139.09
## pov          122.23    35.21
## education    -34.54    12.73
## spending     726.65   280.78
## ---
## n = 51, k = 7
## residual sd = 979.11, R-Squared = 0.65
```

***
Discrete Dataset (inspol)
-
