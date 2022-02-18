#section 1 data production
library (sas7bdat)
library (survey)
library(srvyr)
library(haven)
library(statar)

#R Analysis Example Replication C6
# Note: all data management and survey design setup code included in Chapter 5 document
# ASDA2 Chapter 6 analysis examples replication
# Example 6.1

nhanesdata <- read_sas("Data/nhanes_analysis_ex_c1_c10_2011.sas7bdat")
nhanessvy2 <- svydesign(strata = ~SDMVSTRA, 
                        id = ~SDMVPSU, 
                        weights = ~WTMEC2YR, 
                        data = nhanesdata, 
                        nest = T)

subnhanes <- subset(nhanessvy2 , AGE >= 18) 
(ex61 <- svymean(~factor(IRREGULAR), subnhanes, se=T, na.rm=T, deff=T, ci=T, keep.vars=T))
confint(ex61)
ex61p <- svyciprop(~factor(IRREGULAR), subnhanes, se=T, na.rm=T, deff=T, ci=T, keep.vars=T)
ex61p
# Example 6.2 NHANES ADULT DATA
ex62 <- svymean(~factor(racec), design=subnhanes, se=T, na.rm=T, deff=T, ci=T, keep.vars=T)
ex62
confint(ex62)
# Example 6.3 NHANES ADULT DATA
ex63 <- svymean(~factor(bp_catc), subnhanes, se=T, na.rm=T, deff=T, ci=T, keep.vars=T)
ex63
confint(ex63)

# EXAMPLE 6.4 ESS6 Russian Federation Data, Proportions of Russian 15+ by Marital Status
# GOF TOOL WITH PRE-SET PROPORTIONS (NOT AVAILABLE IN R)
purrr::map(
  list.files(pattern = "sas7bdat", all.files = TRUE,recursive = TRUE),
  ~read_sas(.x) %>% select_all(toupper) %>% select(matches("MARCART"))
)
rfdata <- read_sas("Data/ess6_russia_20aug2016.sas7bdat")
summary(rfdata)
#create factor variables
rfdata$marcatc <- factor(rfdata$marcat, levels = 1:3, labels =c("Married", "Previous", "Never"))
rfsvy <- svydesign(strata=~stratify, id=~psu, weights=~PSPWGHT, data=rfdata, nest=T)
ex6_4 <- svymean(~factor(marcatc), design=rfsvy, na.rm=T, se=T, deff=T, ci=T, keep.vars=T)
print(ex6_4)
# Analysis Example 6.5 PIE AND BAR CHARTS
# Pie of Marital Status Russian Federation Data
ex6_5 <- svymean(~factor(marcatc), rfsvy, se=T, na.rm=T, deff=T, ci=T, keep.vars=T)
pie(ex6_5, col=c("black", "grey60", "blue", "red"), c("Married", "Previously Married", "Never Married"))
# Bar chart of marital status
barplot(ex6_5, legend=c("Married", "Previously Married", "Never Married"), 
        col=c("black","blue", "red"))
# Analysis Example 6.6, NCS-R DATA
(ex6_6 <- svymean(~interaction (SEX, mde), ncsrsvyp1, se=T, na.rm=T, ci=T, keep.vars=T))
# obtain confidence intervals
confint(ex6_6)
# svyby analysis gives mean of mde by sex
(ex6_6a <- svyby(~mde, ~SEX, ncsrsvyp1, svymean, se=T, na.rm=T, ci=T, keep.vars=T))
#CODES FOR SEX 1=MALE 2=FEMALE
#svychisq provides a 2 by 2 chisq test (F)
svychisq(~SEX+mde, ncsrsvyp1, statistic="F")