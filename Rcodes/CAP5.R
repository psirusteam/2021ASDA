#section 1 data production
library (sas7bdat)
library (survey)
library(srvyr)
library(haven)
library(statar)
library(TeachingSampling)

dir()

nhanesdata <- read_sas("Data/nhanes_analysis_ex_c1_c10_2011.sas7bdat")
summary(nhanesdata)
#create factor variables
nhanesdata$racec <- factor(nhanesdata$RIDRETH1, 
                           levels = 1:5, 
                           labels =c("Mexican", "Other Hispanic", "White", "Black", "Other"))

nhanesdata$marcatc <- factor(nhanesdata$MARCAT, 
                             levels = 1:3, 
                             labels =c("Married", "Previously Married", "Never Married"))

nhanesdata$edcatc <- factor(nhanesdata$EDCAT, 
                            levels = 1:4, 
                            labels =c("0-11", "12", "13-15","16+"))

nhanesdata$bp_catc <- factor(nhanesdata$BP_CAT, 
                             levels = 1:4, 
                             labels =c("Normal", "Pre-HBP", "Stage 1 HBP","Stage 2 HBP"))

nhanesdata$agecsq <- (nhanesdata$AGE * nhanesdata$AGE)
names(nhanesdata)

nhanessvy2 <- svydesign(strata = ~SDMVSTRA, 
                        id = ~SDMVPSU, 
                        weights = ~WTMEC2YR, 
                        data = nhanesdata, 
                        nest = T)

subnhanes <- subset(nhanessvy2 , AGE >= 18)
names (nhanessvy2)

#ncs-r next
ncsr <- read_dta("Data/ncsr_analysis_examples_c1_c10_2011.dta")
names(ncsr)
#create factor versions with labels
ncsr$racec <- factor(ncsr$racecat, levels = 1: 4, labels =c("Other", "Hispanic", "Black", "White"))
ncsr$mar3catc <- factor(ncsr$mar3cat, levels = 1: 3, labels =c("Married", "Previously Married", "Never Married"))
ncsr$ed4catc <- factor(ncsr$ed4cat, levels = 1: 4, labels =c("0-11", "12", "13-15","16+"))
ncsr$sexc <- factor(ncsr$sex, levels = 1:2, labels=c("Male","Female"))
ncsr$ag4catc <- factor(ncsr$ag4cat, levels = 1:4, labels=c("18-29", "30-44", "45-59", "60+"))
ncsrsvyp1 <- svydesign(strata=~sestrat, id=~seclustr, weights=~ncsrwtsh, data=ncsr, nest=T)
names (ncsrsvyp1)
ncsrp2 <- subset(ncsr, !is.na(ncsrwtlg))
ncsrsvyp2 <- svydesign(strata=~sestrat, id=~seclustr, weights=~ncsrwtsh, data=ncsrp2, nest=T)
names (ncsrsvyp2)
ncsr$popweight <- (ncsr$ncsrwtsh*(209128094/9282))
ncsrsvypop <- svydesign(strata=~sestrat, id=~seclustr, weights=~popweight, data=ncsr, nest=T)
summary(ncsrsvypop)
#hrs, similar needs for ASDA2
#both hh and r weights are needed plus financial respondent for hh level analysis

hrs <- read_sas("Data/hrs_analysis_ex_c1_c9_2011.sas7bdat")
summary(hrs)
hrssvyhh <- svydesign(strata=~STRATUM, id=~SECU, weights=~KWGTHH , data=hrs, nest=T)
summary(hrssvyhh)
hrssvysub <-subset(hrssvyhh, KFINR==1)
summary(hrssvysub)

hrssvyr <- svydesign(strata=~STRATUM, id=~SECU, weights=~KWGTR , data=hrs, nest=T)
summary(hrssvyr)


#section 2 chapter 5 analysis examples replication, ASDA2
# figures 5.1 and 5.2
svyhist(
  ~ LBXTC ,
  subset (nhanessvy2, AGEC >= 18),
  main = "",
  col = "grey80",
  xlab = "Histogram of Total Cholesterol"
)
#CREATE A VARIABLE CALLED GENDER FOR BOXPLOT
nhanessvy2<-update(nhanessvy2, gender=cut(RIAGENDR, c(1, 2, Inf), right=F))
svyboxplot(
  LBXTC ~ gender ,
  subset (nhanessvy2, AGE >= 18),
  col = "grey80",
  ylab = "Total Cholesterol",
  xlab = "1=Male 2=Female"
)

#Example 5.3
svytotal (~mde, ncsrsvypop, deff=T)
confint(svytotal(~mde, ncsrsvypop))
#MDE OVER MARITAL STATUS
ex53 <- svyby (~mde, ~mar3catc, ncsrsvypop, svytotal)
ex53 <- svyby (~mde, ~mar3catc, ncsrsvypop, svytotal, deff=T)
ex53
confint(ex53)
#Example 5.4 HH Level Wealth/Total Assets
svyby (~H8ATOTA, ~I(KFINR==1), hrssvyhh, na.rm=T, svytotal)
confint(svyby (~H8ATOTA, ~I(KFINR==1), hrssvyhh, na.rm=T, ci=T, svytotal))
#Example 5.5 HRS HH Income
svyby (~H8ITOT, ~I(KFINR==1), hrssvyhh, na.rm=T, svymean)
confint(svyby (~H8ITOT, ~I(KFINR==1), hrssvyhh, na.rm=T, ci=T, svymean))
#Example 5.6 Mean Systolic Blood Pressure, NHANES data
a <- svymean(~BPXSY1 , subset (nhanessvy2, AGE >=18), na.rm=TRUE)
coef(a)
SE(a)
confint(a)
#Example 5.7
svyby (~H8ATOTA, ~I(KFINR==1), hrssvyhh, na.rm=T, ci=T, svymean)
confint(svyby(~H8ATOTA, ~I(KFINR==1), hrssvyhh, na.rm=T, ci=T, svymean))
#Example 5.8 Standard Deviation of Cholesterol NHANES data
#Create a data object with weights only but no design variables
nhaneswgt <- svydesign(id=~1, weights=~WTMEC2YR, data=nhanesdata)
summary(nhaneswgt)
#Subset of those with positive weight and age 18plus
subnhaneswgt <- subset(nhaneswgt, AGE >= 18 & WTMEC2YR > 0 )
summary(subnhaneswgt)
#obtain mean
a <- svymean(~LBXTC + LBDHDD, design=subnhaneswgt, na.rm=T, deff="replace")
a
# use sqrt of variance to obtain standard deviation
sd <- sqrt(svyvar(~LBXTC + LBDHDD, design = subnhaneswgt, na.rm=T))
sd
#Example 5.9 Population Percentiles for total HH Wealth HRS data, in subset of KFINR=1
q <- svyquantile(~H8ATOTA, hrssvysub, c(.25,.5,.75), na.rm=T, ci=T)
q
# Obtain SE from confidence intervals, see R documentation for details
SE(q)
#Example 5.10 Lorenz Curve and GINI coefficient not available in R Survey Package, Summer 2017 
#Example 5.10 Now Available as of 16nov2017 with "convey" package, add example here Berglund 
library(convey) 
# linearized design, use hrssvysub created previously 
hrssvyhh_c <- convey_prep(hrssvyhh) 
# now can subset to financial respondents (after convey_prep) 
sub_hrssvyhh_c <- subset( hrssvyhh_c , KFINR==1) 
# run svygini and svylorenz using subset, note that R does not require negative set to 0 as Stata 
svygini( ~H8ATOTA, design = sub_hrssvyhh_c) 
svylorenz( ~H8ATOTA, sub_hrssvyhh_c, seq(0,1,.1), alpha = .01 ) 
#Example 5.11 Relationship between 2 continuous variables, note this is weighted and design based 
svyplot(LBXTC~LBDHDD, subset(subnhanes, AGE>=18),
        style="bubble", ylab="HDL", xlab="Total Cholesterol") 
#EXAMPLE 5.11 Correlation between Total and High Cholesterol, NHANES DATA 
#create standardized versions of variables first, then use in regression 
nhanesdata$stdlbxtc <- (nhanesdata$LBXTC-194.4355)/41.05184 
summary(nhanesdata$LBXTC + nhanesdata$stdlbxtc) 
nhanesdata$stdlbdhdd <- (nhanesdata$LBDHDD-52.83826)/14.93157 
summary(nhanesdata$stdlbxtc) 
#reset survey design and subset 
nhanessvy2 <- svydesign(strata=~SDMVSTRA, id=~SDMVPSU, weights=~WTMEC2YR, data=nhanesdata, nest=T)
subnhanes <- subset(nhanessvy2 , AGE >= 18) 
#Design based linear regression to obtain correlation and correct SE 
summary(Ex5_11_svyglm <- svyglm(stdlbxtc ~ stdlbdhdd, design=subnhanes))
#Example 5.12 Ratio Estimator for HDD to Total Cholesterol 
ex5_12 <- svyby (~LBDHDD, denominator=~LBXTC, by=~I(AGE >= 18), nhanessvy2, na.rm=T, ci=T, svyratio)
confint(ex5_12) 
#Example 5.13 Proportions of DIABETES by Gender in Subpopulation of Age >=70 
subhrs70 <- subset(hrssvyr, KAGE >= 70) 
ex5_13 <- svyby(~DIABETES, ~GENDER, subhrs70, svymean, keep.names=T, na.rm=T)
print(ex5_13) 
confint(ex5_13)
#Example 5.14 Mean Systolic Blood Pressure by Gender, Age 46+ NHANES 
subnhanes46 <-subset(nhanessvy2, AGE >= 46)
#RIAGENDR 1=MALE 2=FEMALE 
ex5_14 <- svyby(~BPXSY1, ~RIAGENDR, subnhanes46, svymean, keep.names=T, na.rm=T)
print(ex5_14)
confint(ex5_14) 
#Example 5.15 Differences in Mean HH Wealth by Educational Attainment, HRS data 
#CODES FOR EDCAT: 1=0-11 2=12 3=13-15 4=16+ YEARS OF EDUCATION 
options(survey.lonely.psu="remove")
ex5_15 <- svyby(~H8ATOTA, ~EDCAT, hrssvysub, svymean, na.rm=T)
print(ex5_15) 
confint(ex5_15) 
svycontrast(ex5_15, list(avg=c(.5,0,0,.5), diff=c(1,0,0,-1)))
#Example 5.16 Differences in Total Wealth over Time 2010 to 2012, HRS data 
#Use 2010 and 2012 data set prepared in SAS 
hrs_2010_2012 <- read_sas("p:/ASDA 2/Data sets/hrs /hrs_2010_2012_c5.sas7bdat") 

hrs_2010_2012 <- read_sas("Data/hrs_analysis_ex5_13_2011.sas7bdat") 
summary(hrs_2010_2012)
names(hrs_2010_2012)
hrs2010_2012 <- svydesign(strata=~STRATUM, id=~SECU, weights=~JWGTHH, data=hrs_2010_2012, nest=T)
subhrs2010 <- subset(hrs2010_2012, FINR0406==1)
ex5_16 <- svyby (~TOTASSETS, ~YEAR, design=subhrs2010, keep.vars=T, svymean)
coef(ex5_16)
SE(ex5_16)
contrast <- svycontrast(ex5_16, list(avg=c(.5,.5), diff=c(1,-1)))
print(contrast)

?svrVar()
