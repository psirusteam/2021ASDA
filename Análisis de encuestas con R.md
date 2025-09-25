--- 
title: "Análisis de encuestas con R"
author: "Andrés Gutiérrez^[Experto Regional en Estadísticas Sociales - Comisión Económica para América Latina y el Caribe (CEPAL) -  andres.gutierrez@cepal.org],Stalyn Guerrero^[Consultor - Comisión Económica para América Latina y el Caribe (CEPAL), guerrerostalyn@gmail.com], Cristian Téllez^[Consultor - Comisión Económica para América Latina y el Caribe (CEPAL), cftellezp@unal.edu.co], Giovany Babativa^[Consultor - Comisión Económica para América Latina y el Caribe (CEPAL), gbabativam@gmail.com] "
date: "2025-09-25"
lang: es
documentclass: book
# bibliography: [CEPAL.bib]
biblio-style: apalike
link-citations: yes
colorlinks: yes
lot: yes
lof: yes
fontsize: 12pt
geometry: margin = 3cm
header-includes:
  - \usepackage{amsmath}
  - \usepackage[ruled,vlined,linesnumbered]{algorithm2e}
  - \usepackage{tabularray}
github-repo: psirusteam/2021ASDA
description: "Este es el repositorio del libro *Análisis de encuestas con R*."
knit: "bookdown::render_book"
linkcolor: blue
output:
  pdf_document:
    toc: true
    toc_depth: 3
    keep_tex: true
    latex_engine: xelatex
  gitbook:
    df_print: kable
    css: "style.css"
# Compilar así:
# bookdown::render_book("index.Rmd", "bookdown::pdf_book")
# bookdown::render_book("index.Rmd", "bookdown::epub_book")
# bookdown::render_book("index.Rmd", "bookdown::word_document2")
# bookdown::preview_chapter("01.Rmd", "bookdown::word_document2")
---



# Prefacio {-}




La versión online de este libro está licenciada bajo una [Licencia Internacional de Creative Commons para compartir con atribución no comercial 4.0](http://creativecommons.org/licenses/by-nc-sa/4.0/). 

Este libro es el resultado de un compendio de las experiencias internacionales prácticas adquiridas por el autor como Experto Regional en Estadísticas Sociales de la CEPAL.

<!--chapter:end:index.Rmd-->



# Análisis de variables categóricas en encuestas de hogares

Al analizar datos de encuestas de hogares, uno de los productos más habituales son los parámetros descriptivos, cuyo propósito es sintetizar las principales características de la población. Estas estimaciones permiten ofrecer una representación clara y comprensible de la realidad poblacional a partir de la información obtenida en una muestra representativa.

En ocasiones, no es sencillo distinguir entre las variables denominadas cualitativas y cuantitativas, puesto que algunas variables de tipo cuantitativo pueden considerarse categóricas si se divide el rango de valores en intervalos o categorías. Un ejemplo clásico es la variable edad, que en una encuesta de hogares se registra como cuantitativa, pero puede agruparse en categorías. Por ejemplo, en Colombia, las categorías podrían ser: Adolescencia (12–18 años), Juventud (14–26 años), Adultez (27–59 años) y Persona Mayor (60 años o más), incorporando también conceptos de envejecimiento y vejez.

De manera inversa, una variable categórica también puede transformarse en cuantitativa mediante análisis específicos, como un análisis de correspondencias. Esto es frecuente cuando se construyen índices compuestos, como el índice de fuerza laboral. En el contexto de encuestas, las preguntas que contienen variables categóricas son muy comunes y sus resultados suelen presentarse en porcentajes, por ejemplo: parentesco, sexo, jefe o jefa del hogar, acceso a agua potable, entre otros.

Entre los resultados más comunes de este tipo de análisis se encuentran frecuencias, proporciones, medias y totales. Las medias proporcionan información sobre el valor promedio de una variable, mientras que los totales reflejan su acumulado en toda la población. Las frecuencias cuentan cuántos hogares o individuos pertenecen a una categoría determinada —por ejemplo, el número de personas en situación de pobreza—, y las proporciones expresan la participación relativa de quienes presentan una característica específica, como el porcentaje de población pobre.

Actualmente, el análisis descriptivo va más allá de los parámetros básicos, incorporando métricas más complejas. Se estiman cuantiles de variables numéricas, como la mediana del ingreso de los hogares, para describir la distribución de los datos con mayor detalle. Además, se aplican indicadores especializados para evaluar fenómenos concretos, como los índices FGT para la medición de pobreza, los indicadores de desigualdad (Gini, Theil, Atkinson) y de polarización (Wolfson, DER), entre otros (Jacob, Damico y Pessoa, 2024).




``` r
library(tidyverse)

encuesta <- readRDS("Data/encuesta.rds")
head(encuesta)
```

```
##        HHID   Stratum NIh nIh  dI PersonID     PSU  Zone    Sex Age MaritalST
## 1 idHH00031 idStrt001   9   2 4.5  idPer01 PSU0003 Rural   Male  68   Married
## 2 idHH00031 idStrt001   9   2 4.5  idPer02 PSU0003 Rural Female  56   Married
## 3 idHH00031 idStrt001   9   2 4.5  idPer03 PSU0003 Rural Female  24   Married
## 4 idHH00031 idStrt001   9   2 4.5  idPer04 PSU0003 Rural   Male  26   Married
## 5 idHH00031 idStrt001   9   2 4.5  idPer05 PSU0003 Rural Female   3      <NA>
## 6 idHH00041 idStrt001   9   2 4.5  idPer01 PSU0003 Rural Female  61   Widowed
##   Income Expenditure Employment Poverty dki dk       wk Region    CatAge
## 1 409.87      346.34   Employed NotPoor   8 36 34.50371  Norte Más de 60
## 2 409.87      346.34   Employed NotPoor   8 36 33.63761  Norte     46-60
## 3 409.87      346.34   Employed NotPoor   8 36 33.63761  Norte     16-30
## 4 409.87      346.34   Employed NotPoor   8 36 34.50371  Norte     16-30
## 5 409.87      346.34       <NA> NotPoor   8 36 33.63761  Norte       0-5
## 6 823.75      392.24   Employed NotPoor   8 36 33.63761  Norte Más de 60
```

**Definición del diseño y creación de variables categóricas**

Se inicia este capítulo haciendo el ajuste del diseño muestral (como se mostró en capítulos anteriores) usando como ejemplo la misma base de datos del capítulo anterior. Luego, para efectos del ejemplo, se genera una variable categórica la cual indica si la persona encuestada está en estado de pobreza o no como sigue:



``` r
library(survey)
library(srvyr)
options(survey.lonely.psu = "adjust")

diseno <- encuesta %>% 
          as_survey_design(
                           strata = Stratum,  
                           ids = PSU,         
                           weights = wk,      
                           nest = TRUE)
```

A continuación, se define una variable categórica que nace de variables propias de la encuesta,



``` r
diseno <- diseno %>% mutate(
                     pobreza = ifelse(Poverty != "NotPoor", 1, 0),
                     desempleo = ifelse(Employment == "Unemployed", 1, 0),
                     edad_18 = case_when(Age < 18 ~ "< 18 anios", TRUE ~ ">= 18 anios")
)
```

Como se pudo observar en el código anterior, se ha introducido la función `case_when` la cual es una extensión del a función `ifelse` que permite crear múltiples categorías a partir de una o varias condiciones. 

Como se ha mostrado anteriormente, en ocasiones se desea realizar estimaciones por sub-grupos de la población, en este caso se extraer 4 sub-grupos de la encuesta y se definen a continuación:


``` r
sub_Urbano <- diseno %>%  filter(Zone == "Urban")
sub_Rural  <- diseno %>%  filter(Zone == "Rural")
sub_Mujer  <- diseno %>%  filter(Sex == "Female")
sub_Hombre <- diseno %>%  filter(Sex == "Male")
```

## Tamaño de población y subpoblaciones en encuestas de hogares

En el análisis de encuestas de hogares, resulta esencial determinar el tamaño de las subpoblaciones, es decir, identificar cuántas personas u hogares pertenecen a categorías específicas y qué proporción representan dentro del total poblacional. Este tipo de estimaciones permite caracterizar el perfil demográfico y socioeconómico de la población, información clave para orientar la asignación de recursos, el diseño de políticas públicas y la formulación de programas sociales.

Así, es de gran utilidad conocer cuántas personas se encuentran por debajo de la línea de pobreza, cuántas no tienen empleo o cuántas han alcanzado determinado nivel educativo. Analizar cómo se distribuyen los individuos entre distintas categorías ofrece información indispensable para reducir brechas y avanzar hacia un desarrollo inclusivo.

La estimación del tamaño de una población o subpoblación se realiza a partir de variables categóricas, que segmentan a la población en grupos mutuamente excluyentes. Estas categorías pueden corresponder, por ejemplo, a quintiles de ingreso, estados de ocupación o niveles educativos alcanzados. El tamaño poblacional hace referencia al número total de individuos u hogares que, en la base de datos de la encuesta, pertenecen a una categoría determinada. Para obtener estas estimaciones, se combinan las respuestas de los encuestados con los pesos muestrales, que indican cuántas personas u hogares representa cada unidad de la muestra dentro de la población total.

El estimador del tamaño de la población se define como:

$$\hat{N} = \sum_{h=1}^{H} \sum_{i \in s_{1h}} \sum_{k \in s_{hi}} w_{hik}$$

donde $s_{hi}$ corresponde a la muestra de hogares o individuos en la UPM $i$ del estrato $h$; $s_{1h}$ representa la muestra de UPM seleccionadas en el estrato $h$; y $w_{hik}$ es el peso o factor de expansión de la unidad $k$ en la UPM $i$ del estrato $h$.

La estimación del tamaño de una subpoblación sigue el mismo principio que el cálculo del tamaño poblacional total, pero se enfoca en un subconjunto definido por una característica específica. Para determinar cuántas personas pertenecen a una categoría particular, se identifica dicho grupo en la base de datos y se suman sus pesos muestrales. Esto permite cuantificar grupos de interés específicos y conocer su tamaño dentro de la población:

$$\hat{N}_d = \sum_{h=1}^{H} \sum_{i \in s_{1h}} \sum_{k \in s_{hi}} w_{hik} I(y_{hik}=d)$$

donde $I(y_{hik}=d)$ es una variable binaria que toma el valor de 1 si la unidad $k$ de la UPM $i$ en el estrato $h$ pertenece a la categoría $d$ de la variable discreta $y$, y 0 en caso contrario. Si $d$ fue utilizada en la calibración de los pesos, el valor de $\hat{N}_d$ coincidirá con el control externo aplicado.


### Estimaciones de totales en `R` {-}

En esta sección se presentan los procedimientos para estimar tamaños de población y subpoblaciones usando R, con el diseño muestral definido previamente. Por ejemplo, para estimar el tamaño de la población por zona:


``` r
tamano_zona <- diseno %>% group_by(Zone) %>% 
               summarise( n = unweighted(n()), 
                          Nd = survey_total(vartype = c("se","ci")))

tamano_zona
```

```
## # A tibble: 2 x 6
##   Zone      n    Nd Nd_se Nd_low Nd_upp
##   <chr> <int> <dbl> <dbl>  <dbl>  <dbl>
## 1 Rural  1297 72102 3062. 66039. 78165.
## 2 Urban  1308 78164 2847. 72526. 83802.
```

En la tabla resultante, *n* indica el número de observaciones en la muestra por zona y *Nd* representa la estimación del total de observaciones en la población. La función `unweighted()` calcula resúmenes no ponderados a partir de los datos muestrales.

Por ejemplo, el tamaño de muestra en la zona rural fue de 1297 personas y en la urbana de 1308. Esto permitió estimar una población de 72,102 (desviación estándar 3,062) en la zona rural y 78,164 (desviación estándar 2,847) en la zona urbana. Con un nivel de confianza del 95%, los intervalos de confianza fueron:

* Zona rural: (66,038.5, 78,165.4)
* Zona urbana: (72,526.2, 83,801.7)

De manera similar, es posible estimar el número de personas en condición de pobreza extrema, pobreza y no pobres:


``` r
tamano_pobreza <- diseno %>% group_by(Poverty) %>% 
                  summarise(Nd = survey_total(vartype = c("se","ci")))
tamano_pobreza
```

```
## # A tibble: 3 x 5
##   Poverty      Nd Nd_se Nd_low  Nd_upp
##   <fct>     <dbl> <dbl>  <dbl>   <dbl>
## 1 NotPoor  91398. 4395. 82696. 100101.
## 2 Extreme  21519. 4949. 11719.  31319.
## 3 Relative 37349. 3695. 30032.  44666.
```

Estos cálculos permiten obtener estimaciones precisas y sus intervalos de confianza para cada subpoblación, facilitando el análisis socioeconómico y la toma de decisiones basadas en evidencia.


Otra variable de interés en encuestas de hogares es conocer el estado de ocupación de las personas. A continuación, se muestra el código computacional:


``` r
tamano_ocupacion <- diseno %>% 
                    group_by(Employment) %>% 
                    summarise( Nd = survey_total(vartype = c("se","ci")))
tamano_ocupacion
```

```
## # A tibble: 4 x 5
##   Employment     Nd Nd_se Nd_low Nd_upp
##   <fct>       <dbl> <dbl>  <dbl>  <dbl>
## 1 Unemployed  4635.  761.  3129.  6141.
## 2 Inactive   41465. 2163. 37183. 45748.
## 3 Employed   61877. 2540. 56847. 66907.
## 4 <NA>       42289. 2780. 36784. 47794.
```
De los resultados de la estimación se puede concluir que, 4634.8 personas están desempleadas con un intervalo de confianza de (3128.6, 6140.9). 41465.2 personas están inactivas con un intervalo de confianza de (37182.6,	45747.8) y por último, 61877.0 personas empleadas con intervalos de confianza (36784.2, 47793.5).

Utilizando la función `group_by` es posible obtener resultados por más de un nivel de agregación. A continuación, se muestra la estimación ocupación desagregada por niveles de pobreza:


``` r
tamano_ocupacion_pobreza <- diseno %>% 
                            group_by(Employment, Poverty) %>% 
                            cascade( Nd = survey_total(vartype =                                     c("se","ci")), .fill = "Total") %>%
                            data.frame()
tamano_ocupacion_pobreza
```

```
##    Employment  Poverty         Nd     Nd_se      Nd_low     Nd_upp
## 1  Unemployed  NotPoor   1768.375  405.3765    965.6891   2571.061
## 2  Unemployed  Extreme   1169.201  348.1340    479.8603   1858.541
## 3  Unemployed Relative   1697.231  457.8077    790.7262   2603.736
## 4  Unemployed    Total   4634.807  760.6242   3128.6948   6140.919
## 5    Inactive  NotPoor  24346.008 1736.2770  20908.0064  27784.010
## 6    Inactive  Extreme   6421.825 1320.7349   3806.6383   9037.012
## 7    Inactive Relative  10697.414 1460.2792   7805.9155  13588.913
## 8    Inactive    Total  41465.248 2162.8040  37182.6798  45747.816
## 9    Employed  NotPoor  44600.347 2596.1915  39459.6282  49741.065
## 10   Employed  Extreme   5127.531 1121.6461   2906.5601   7348.503
## 11   Employed Relative  12149.142 1346.6159   9482.7078  14815.576
## 12   Employed    Total  61877.020 2540.0762  56847.4153  66906.624
## 13      Total    Total 150266.000 4181.3587 141986.4921 158545.508
## 14       <NA>  NotPoor  20683.603 1256.6158  18195.3777  23171.827
## 15       <NA>  Extreme   8800.209 2979.9150   2899.6792  14700.738
## 16       <NA> Relative  12805.115 1551.0291   9733.9220  15876.307
## 17       <NA>    Total  42288.926 2779.9913  36784.2652  47793.586
```
De lo cual se puede concluir, entre otros que, 44600.3 personas que trabajan no son pobres con un intervalo de confianza (39459.6, 49741.0) y 6421.8  inactivas están en pobreza extrema con un intervalo de confianza de (3806.6,	9037.0).

## Estimación de proporciones

En las encuestas de hogares, **las proporciones** permiten expresar el peso relativo que tienen determinados grupos dentro de la población. Por ejemplo, conocer el porcentaje de hogares que se encuentran por debajo de la línea de pobreza es esencial para evaluar desigualdades socioeconómicas. Para obtener este indicador, se calcula el promedio ponderado de una variable dicotómica, lo que asegura que la estimación represente adecuadamente la distribución poblacional.

De acuerdo con Heeringa, West y Berglund (2017), al transformar las categorías de respuesta originales en variables indicadoras $y$ con valores de 1 y 0 (por ejemplo, 1 = Sí y 0 = No), la proporción estimada se obtiene mediante:

$$\hat{p}_d = \frac{\hat{N}_d}{\hat{N}} = \frac{\displaystyle\sum_{h=1}^{H} \sum_{i \in s_{1h}} \sum_{k \in s_{hi}} w_{hik} I(y_{hik}=d)} {\displaystyle\sum_{h=1}^{H} \sum_{i \in s_{1h}} \sum_{k \in s_{hi}} w_{hik}}$$

Dado que se trata de un estimador no lineal, su varianza puede aproximarse mediante la **técnica de linealización de Taylor**, utilizando como función de estimación $z_{hik}=I(y_{hik}=d)-\hat{p}_d$. Actualmente, la mayoría de los programas estadísticos generan estas proporciones junto con sus errores estándar, generalmente presentados en forma de porcentajes.

En situaciones donde las proporciones se aproximan a 0 o 1, puede ser necesario aumentar el tamaño de la muestra para garantizar resultados sólidos. También es recomendable aplicar métodos que aseguren que los intervalos de confianza permanezcan dentro del rango \[0,1], ya que los intervalos convencionales basados en la normal pueden desbordar estos límites y perder su utilidad interpretativa. Una alternativa es la **transformación logit** de la proporción estimada:

$$CI(\hat{p}_d; 1-\alpha) = \frac{\exp \left[\ln\left(\frac{\hat{p}_d}{1-\hat{p}_d}\right) \pm \frac{me(\hat{p}_d)}{\hat{p}_d(1-\hat{p}_d)}\right]}{1 + \exp \left[\ln\left(\frac{\hat{p}_d}{1-\hat{p}_d}\right) \pm \frac{me(\hat{p}_d)}{\hat{p}_d(1-\hat{p}_d)}\right]}$$

donde $me(\hat{p}_d) = t_{1-\alpha/2, df} \times se(\hat{p}_d)$, siendo $t_{1-\alpha/2, df}$ el cuantil de la distribución t de Student con $df = n - H$ grados de libertad, dejando un área $\alpha/2$ a su derecha. Este procedimiento asegura resultados interpretables incluso para proporciones extremas (0 o 1).


### Estimación de proporciones en `R`

Otro parámetro de interés en las encuestas de hogares, particularmente con variables categóricas, es la estimación de **proporciones poblacionales** y sus errores estándar. En términos de notación, la estimación de proporciones de población se define como $p$ y las proporciones muestrales como $\pi$. Es común que muchos paquetes estadísticos generen estas estimaciones en **escala de porcentaje**, mientras que `R` las produce en la escala [0,1].

A continuación, se muestra cómo estimar la proporción de personas por **zona** usando `srvyr` y el diseño muestral previamente definido:


``` r
prop_zona <- diseno %>% group_by(Zone) %>% 
             summarise(
               prop = survey_mean(vartype = c("se","ci"), 
                                  proportion = TRUE))
prop_zona
```

```
## # A tibble: 2 x 5
##   Zone   prop prop_se prop_low prop_upp
##   <chr> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Rural 0.480  0.0140    0.452    0.508
## 2 Urban 0.520  0.0140    0.492    0.548
```

En este ejemplo, la función `survey_mean` calcula la proporción y, con el parámetro `proportion = TRUE`, se indica que se desea estimar una **proporción poblacional**. Los resultados muestran que aproximadamente el 47.9% de las personas viven en zona rural (IC 95%: 45.2% - 50.7%) y el 52% en zona urbana (IC 95%: 49.2% - 54.7%).

La librería `survey` también cuenta con la función `survey_prop`, diseñada específicamente para estimar proporciones, generando resultados equivalentes:


``` r
prop_zona2 <- diseno %>% group_by(Zone) %>% 
               summarise(prop = survey_prop(vartype = c("se","ci")))
prop_zona2
```

```
## # A tibble: 2 x 5
##   Zone   prop prop_se prop_low prop_upp
##   <chr> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Rural 0.480  0.0140    0.452    0.508
## 2 Urban 0.520  0.0140    0.492    0.548
```

El lector puede elegir la función que le resulte más cómoda, ya que ambas permiten obtener estimaciones precisas y sus intervalos de confianza, facilitando la interpretación de los resultados para variables categóricas.



Si el interés ahora se centra en estimar  subpoblaciones por ejemplo, proporción de hombres y mujeres que viven en la zona urbana, el código computacional es:


``` r
prop_sexoU <- sub_Urbano %>% group_by(Sex) %>% 
              summarise(prop = survey_prop(vartype = c("se","ci")))
prop_sexoU
```

```
## # A tibble: 2 x 5
##   Sex     prop prop_se prop_low prop_upp
##   <chr>  <dbl>   <dbl>    <dbl>    <dbl>
## 1 Female 0.537  0.0130    0.511    0.563
## 2 Male   0.463  0.0130    0.437    0.489
```

Arrojando como resultado que, el 53.6% de las mujeres y 46.4%  de los hombres viven en la zona urbana y con intervalos de confianza (51%, 56.2%) y (43.7%, 48.9%) respectivamente. Los intervalos anteriores nos reflejan que, con una confianza del 95% la cantidad estimada de mujeres que viven en la zona urbana es de56% y de hombres es de 48%.

Realizando el mismo ejercicio anterior, pero ahora en la zona rural se tiene:



``` r
prop_sexoR <- sub_Rural %>% group_by(Sex) %>% 
              summarise( n = unweighted(n()),
                         prop = survey_prop(vartype = c("se","ci")))
prop_sexoR
```

```
## # A tibble: 2 x 6
##   Sex        n  prop prop_se prop_low prop_upp
##   <chr>  <int> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Female   679 0.516 0.00824    0.500    0.533
## 2 Male     618 0.484 0.00824    0.467    0.500
```

el 51.6% de las mujeres y el 48.4% de los hombres viven en la zona rural con intervalos de confianza de (49.9%, 53.2%) y (46,7%, 50%) respectivamente. Los intervalos de confianza anteriores nos reflejan que, inclusive, con una confianza del 95%, la cantidad estimada de mujeres en la zona rural es de 53% y de hombres es de 50%. 


Ahora bien, si nos centramos solo en la población de hombres en la base de datos y se desea estimar la proporción de hombres por zona, el código computacional es el siguiente: 



``` r
prop_ZonaH <- sub_Hombre %>% group_by(Zone) %>% 
              summarise(prop = survey_prop(vartype = c("se","ci")))
prop_ZonaH
```

```
## # A tibble: 2 x 5
##   Zone   prop prop_se prop_low prop_upp
##   <chr> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Rural 0.491  0.0178    0.455    0.526
## 2 Urban 0.509  0.0178    0.474    0.545
```

En la anterior tabla se puede observar que el 49% de los hombres están en la zona rural y el 51% en la zona urbana. Si se observa el intervalo de confianza se puede concluir que, con una confianza del 95%, la población estimada de hombres que viven en la zona rural puede llegar a ser el 52% y en urbana un 54%.


Si se realiza ahora el mismo ejercicio para la mujeres el código computacional es:


``` r
prop_ZonaM <- sub_Mujer %>% group_by(Zone) %>% 
              summarise(prop = survey_prop(vartype = c("se","ci")))
prop_ZonaM
```

```
## # A tibble: 2 x 5
##   Zone   prop prop_se prop_low prop_upp
##   <chr> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Rural 0.470  0.0140    0.443    0.498
## 2 Urban 0.530  0.0140    0.502    0.557
```

De la tabla anterior se puede inferir que, el 47% de las mujeres están en la zona rural y el 52% en la zona urbana. Observando también  intervalos de confianza al 95% de (44%, 49%) y (50%, 55%) para las zonas rural y urbana respectivamente. 

Si se desea estimar por varios niveles de desagregación, con el uso de la función `group_by` es posible estimar un mayor número de niveles de agregación al combinar dos o más variables. Por ejemplo, si se desea estimar la proporción de hombres por zona y en estado de pobreza, se realiza de la siguiente manera:


``` r
prop_ZonaH_Pobreza <- sub_Hombre %>%
                      group_by(Zone, Poverty) %>% 
                      summarise(
                      prop = survey_prop(vartype = c("se","ci")))%>%
                      data.frame()
prop_ZonaH_Pobreza
```

```
##    Zone  Poverty      prop    prop_se   prop_low  prop_upp
## 1 Rural  NotPoor 0.5488453 0.06264753 0.42434340 0.6675180
## 2 Rural  Extreme 0.1975254 0.06745258 0.09582905 0.3637294
## 3 Rural Relative 0.2536293 0.03724070 0.18711180 0.3340755
## 4 Urban  NotPoor 0.6599255 0.03662268 0.58415144 0.7283141
## 5 Urban  Extreme 0.1128564 0.02451869 0.07264146 0.1712240
## 6 Urban Relative 0.2272181 0.02604053 0.17979436 0.2828371
```

De la salida anterior se puede observar que, en la ruralidad, el 19% de los hombres están en pobreza extrema mientras que en la zona urbana el 11% también están en pobreza extrema. Por otro lado, el 54% de los hombres que viven en la zona rural no están en pobreza mientras que, en la zona urbana el 65% no está en esta condición.

El mismo ejercicio anterior para la población de mujeres sería:



``` r
prop_ZonaM_Pobreza <- sub_Mujer %>% 
                      group_by(Zone, Poverty) %>% 
                      summarise( prop = survey_prop(vartype = c("se","ci"))) %>%
                      data.frame()
prop_ZonaM_Pobreza
```

```
##    Zone  Poverty      prop    prop_se   prop_low  prop_upp
## 1 Rural  NotPoor 0.5539176 0.05568825 0.44281376 0.6598834
## 2 Rural  Extreme 0.1599702 0.05574533 0.07728197 0.3021593
## 3 Rural Relative 0.2861122 0.04357612 0.20803909 0.3794466
## 4 Urban  NotPoor 0.6612172 0.03224726 0.59475977 0.7218725
## 5 Urban  Extreme 0.1093753 0.02209821 0.07267359 0.1613865
## 6 Urban Relative 0.2294075 0.02655874 0.18106582 0.2861459
```

De la salida anterior se puede observar que, en la ruralidad, el 16% de las mujeres están en pobreza extrema mientras que en la zona urbana el 10% también están en pobreza extrema. Por otro lado, el 55% de las mujeres que viven en la zona rural no están en pobreza mientras que, en la zona urbana el 66% no está en esta condición.

Si lo que se desea ahora es estimar la proporción de hombres empleados o no por zona, se realiza de la siguiente manera:


``` r
prop_ZonaH_Ocupacion <- sub_Hombre %>%
                        group_by(Zone, Employment) %>% 
                        summarise(prop = survey_prop(vartype = c("se","ci")))%>%
                        data.frame()
prop_ZonaH_Ocupacion
```

```
##    Zone Employment       prop     prop_se   prop_low   prop_upp
## 1 Rural Unemployed 0.05125186 0.015733138 0.02767737 0.09298588
## 2 Rural   Inactive 0.10351629 0.020267044 0.06970747 0.15106011
## 3 Rural   Employed 0.52251375 0.026522751 0.46994089 0.57459249
## 4 Rural       <NA> 0.32271810 0.034987840 0.25763953 0.39547790
## 5 Urban Unemployed 0.04374724 0.008492664 0.02969659 0.06400729
## 6 Urban   Inactive 0.16331307 0.018093938 0.13056379 0.20236490
## 7 Urban   Employed 0.51337023 0.023637331 0.46658553 0.55992181
## 8 Urban       <NA> 0.27956945 0.022085422 0.23799131 0.32531045
```

De la salida anterior se puede observar que, el 5% de los hombres que viven en la ruralidad están desempleados mientras que el 4% de los que viven en la zona urbana están en esta misma condición. Ahora bien, el 52% de los hombres que viven en la ruralidad trabajan mientras que el 51% de los que viven en la zona rural también están empleados.

Si se hace este mismo ejercicio para las mujeres se obtiene:


``` r
prop_ZonaM_Ocupacion <- sub_Mujer %>% 
                        group_by(Zone, Employment) %>% 
                        summarise(prop = survey_prop(vartype = c("se","ci"))) %>%
                        data.frame()
prop_ZonaM_Ocupacion
```

```
##    Zone Employment       prop     prop_se    prop_low   prop_upp
## 1 Rural Unemployed 0.01017065 0.005540256 0.003443802 0.02964628
## 2 Rural   Inactive 0.44719272 0.035247218 0.378871481 0.51756811
## 3 Rural   Employed 0.23999716 0.039151859 0.171118101 0.32570701
## 4 Rural       <NA> 0.30263948 0.030765644 0.245379430 0.36676711
## 5 Urban Unemployed 0.02109678 0.005964137 0.012019202 0.03677508
## 6 Urban   Inactive 0.36445938 0.021442387 0.323143427 0.40787461
## 7 Urban   Employed 0.38455672 0.019452094 0.346831628 0.42372325
## 8 Urban       <NA> 0.22988711 0.013850398 0.203613820 0.25845036
```

Para las mujeres se puede observar que, el 1% de las mujeres que viven en la ruralidad están desempleados mientras que el 2% de las que viven en la zona urbana están en esta misma condición. Ahora bien, el 24% de las mujeres que viven en la ruralidad trabajan mientras que el 38% de las que viven en la zona rural también están empleados.

Otro parámetro que es de interés es estimar en encuestas de hogares la cantidad de personas menores y mayores de edad en los hogares. A continuación, ejemplificamos la estimación de menores y mayores a 18 años cruzado por pobreza:


``` r
diseno %>% group_by(edad_18, pobreza) %>% 
           summarise(Prop = survey_prop(vartype =  c("se", "ci"))) %>%
           data.frame()
```

```
##       edad_18 pobreza      Prop    Prop_se  Prop_low  Prop_upp
## 1  < 18 anios       0 0.4984504 0.03729355 0.4251710 0.5717964
## 2  < 18 anios       1 0.5015496 0.03729355 0.4282036 0.5748290
## 3 >= 18 anios       0 0.6646140 0.02978353 0.6033275 0.7208132
## 4 >= 18 anios       1 0.3353860 0.02978353 0.2791868 0.3966725
```
De la anterior salida se puede observar que, el 50% de los menores de edad y el 33% de los mayores de edad están en estado de pobreza. Al observar los intervalos de confianza para los menores de edad en estado de pobreza se puede observar que, dicha estimación puede llegar, con una confianza del 95% a 57% mientras que a los mayores de edad puede llegar a 39%.

Ahora, si se hace este mismo ejercicio, pero esta vez cruzando con la variable que indica empleo se obtiene:


``` r
diseno %>% group_by(edad_18, desempleo) %>% 
           summarise(Prop = survey_prop(vartype =  c("se", "ci"))) %>%
           data.frame()
```

```
##       edad_18 desempleo        Prop     Prop_se    Prop_low   Prop_upp
## 1  < 18 anios         0 0.166704172 0.014856561 0.139321648 0.19822898
## 2  < 18 anios         1 0.003729693 0.001969183 0.001309174 0.01057808
## 3  < 18 anios        NA 0.829566135 0.015009188 0.797760089 0.85726505
## 4 >= 18 anios         0 0.955234872 0.007552778 0.937660285 0.96802386
## 5 >= 18 anios         1 0.044765128 0.007552778 0.031976144 0.06233972
```

De la tabla anterior se puede observar que, el 0.3% de los menores de edad y el 4% de los mayores de edad están desempleados. Adicionalmente, con una confianza del 95% y basados en la muestra se puede observar que el desempleo en menores de edad puede llegar a 0.7% y para los mayores llega a un 5%.

Por otro lado, si el objetivo ahora es estimar la cantidad de menores de edad en la zona rural se realiza de la siguiente manera:


``` r
sub_Rural %>% group_by(edad_18) %>% 
              summarise(Prop = survey_prop(vartype =  c("se", "ci"))) %>%
              data.frame()
```

```
##       edad_18      Prop    Prop_se  Prop_low  Prop_upp
## 1  < 18 anios 0.3711613 0.03021982 0.3128746 0.4334566
## 2 >= 18 anios 0.6288387 0.03021982 0.5665434 0.6871254
```

De la anterior tabla se puede observar que, el 37% de las personas que viven en la zona rural de la base de ejemplo son menores de edad con un intervalo de confianza al 95% comprendido entre 31% y 43%.

Como se mencionó al inicio del capítulo, es posible categorizar una variable de tipo cuantitativo como por ejemplo la edad y cruzarla con la variable que categoriza la empleabilidad. A continuación, se estima la edad de las mujeres por rango.



``` r
sub_Mujer %>% mutate(edad_rango = case_when(
                     Age>= 18 & Age <=35  ~ "18 - 35", TRUE ~ "Otro")) %>%
                     group_by(edad_rango, Employment) %>% 
                     summarise(Prop = survey_prop(vartype =  c("se", "ci"))) %>% 
                     data.frame()
```

```
##   edad_rango Employment       Prop     Prop_se    Prop_low   Prop_upp
## 1    18 - 35 Unemployed 0.02893412 0.009142347 0.015403014 0.05370358
## 2    18 - 35   Inactive 0.51653851 0.037905184 0.441673039 0.59066889
## 3    18 - 35   Employed 0.45452737 0.035685710 0.385232560 0.52562948
## 4       Otro Unemployed 0.01015164 0.004026104 0.004617517 0.02217073
## 5       Otro   Inactive 0.35271022 0.020725430 0.312834830 0.39474850
## 6       Otro   Employed 0.25483870 0.021700305 0.214292062 0.30012671
## 7       Otro       <NA> 0.38229944 0.022313379 0.339191706 0.42734277
```

De la anterior tabla se puede observar, entre otros que, las mujeres con edades entre 18 y 35 años el 2% están desempleadas y el 45% están empleadas. Análisis similares se pueden hacer para los demás rangos de edades. 

Este mismo ejercicio se puede realizar para los hombres y hacer los mismos análisis. A continuación, se muestra el código computacional:


``` r
sub_Hombre %>% mutate(edad_rango = case_when(
                      Age>= 18 & Age <=35  ~ "18 - 35",TRUE ~ "Otro")) %>%
                      group_by(edad_rango, Employment) %>% 
                      summarise(Prop = survey_prop(vartype =  c("se", "ci"))) %>% 
                      data.frame()
```

```
##   edad_rango Employment       Prop     Prop_se   Prop_low   Prop_upp
## 1    18 - 35 Unemployed 0.09637042 0.018215667 0.06584071 0.13895080
## 2    18 - 35   Inactive 0.08939940 0.016438321 0.06175556 0.12773290
## 3    18 - 35   Employed 0.81423018 0.022991735 0.76436394 0.85553799
## 4       Otro Unemployed 0.02606667 0.007175709 0.01506262 0.04474457
## 5       Otro   Inactive 0.15344056 0.019883462 0.11805657 0.19706023
## 6       Otro   Employed 0.38849664 0.020270309 0.34919327 0.42930563
## 7       Otro       <NA> 0.43199614 0.021111842 0.39076987 0.47418649
```

## Tablas cruzadas

En los levantamientos de encuestas de hogares, es habitual recopilar información sobre variables categóricas, que permiten clasificar a la población en grupos mutuamente excluyentes. Ejemplos comunes son el estado laboral (*ocupado*, *desempleado*, *inactivo*), el nivel educativo alcanzado (*primaria*, *secundaria*, *terciaria*) o el acceso a determinados servicios (*sí*, *no*). Explorar si dos de estas variables están asociadas constituye un elemento central del análisis, pues ofrece información valiosa en distintos ámbitos:

* En política pública, al relacionar educación y empleo para diseñar estrategias laborales.
* En evaluación de programas, al detectar variaciones en el acceso a salud según el nivel de ingresos.
* En investigación social, al estudiar vínculos entre factores demográficos y servicios para comprender dinámicas y tendencias sociales.

### Definición y notación

El estudio de la asociación entre dos variables categóricas implica verificar si la distribución de una depende de la otra. Para ello se comparan las frecuencias de todas las combinaciones posibles de categorías. Por ejemplo, puede contabilizarse cuántos individuos corresponden simultáneamente a cada nivel educativo y estado laboral. Estas frecuencias pueden transformarse en proporciones, que muestran la participación relativa de cada combinación en la población.

La herramienta más común para organizar esta información es la tabla de contingencia, también conocida como tabla cruzada. En su forma más simple, corresponde a una matriz de doble entrada en la que las filas representan las categorías de una variable y las columnas las de otra. Cada celda contiene la frecuencia o proporción de casos que presentan simultáneamente la combinación $(r,c)$.

Formalmente, sean $x$ y $y$ dos variables categóricas con $R$ y $C$ categorías, respectivamente. Bajo un modelo de superpoblación, la distribución conjunta puede expresarse como:

$$
P_{rc} = Pr(X=r, Y=c), \quad r=1,\dots,R;\, c=1,\dots,C
\tag{9-24}
$$

con la restricción $\sum\_{r=1}^{R}\sum\_{c=1}^{C} P\_{rc}=1$.

Si se dispusiera de un censo, el número de unidades en cada celda $(r,c)$ se calcularía como:

$$
N_{rc} = \sum_{h=1}^{H} \sum_{i \in U_{1h}} \sum_{k \in U_{hi}} I(x_{hik}=r, y_{hik}=c) 
\tag{9-25}
$$

y las proporciones poblacionales se definirían como $p\_{rc} = N\_{rc}/N\_{(++)}$, donde $N\_{(++)}$ es el tamaño total de la población. En la práctica, al trabajar con encuestas, estas proporciones se estiman mediante los estimadores ponderados explicados en secciones previas.

### Tablas de doble entrada

Una tabla de contingencia puede representarse en forma general como:

| Variable 2        | Variable 1                  | Marginal fila|
|-------------------|-------------|---------------|--------------|
|                   | 0           | 1             |              |
| 0                 | $n_{00}$    |   $n_{01}$    | $n_{0+}$     |
| 1                 | $n_{10}$    |   $n_{11}$    | $n_{1+}$     |
| Marginal columna  | $n_{+0}$    |   $n_{+1}$    | $n_{++}$     |

Cuando se aplican los pesos muestrales, se obtienen las frecuencias ponderadas:

| Variable 2        | Variable 1                  | Marginal fila|
|-------------------|-------------|---------------|--------------|
|                   | 0           | 1             |              |
| 0                 | $\hat{N}_{00}$| $\hat{N}_{01}$| $\hat{N}_{0+}$|
| 1                 | $\hat{N}_{10}$| $\hat{N}_{11}$| $\hat{N}_{1+}$|
| Marginal columna  | $\hat{N}_{+0}$| $\hat{N}_{+1}$| $\hat{N}_{++}$|

donde, por ejemplo, la frecuencia ponderada en la celda $(0,1)$ está dada por:

$$
\hat{N}_{01} = \sum_{h=1}^{H} \sum_{\alpha=1}^{a_{h}} \sum_{i \in (0,1)}^{n_{h\alpha}} \omega_{h\alpha i}
$$

y las proporciones estimadas se calculan como:

$$
\hat{p}_{rc}=\frac{\hat{N}_{rc}}{\hat{N}_{++}}.
$$

### Extensiones y aplicaciones

Aunque comúnmente se presentan como tablas bidimensionales ($R \times C$), las tablas de contingencia pueden extenderse a más dimensiones, incorporando una tercera variable o más ($L$ subtablas), lo que permite explorar relaciones más complejas.

Gracias a su simplicidad y potencia descriptiva, las tablas cruzadas son ampliamente utilizadas en la investigación aplicada y en el diseño de políticas públicas, pues permiten identificar patrones y asociaciones que no serían evidentes a simple vista. Su interpretación también puede reforzarse mediante representaciones gráficas, como los diagramas de barras apiladas, que facilitan la visualización de tendencias y diferencias (véase la Sección 9.8 para un análisis más detallado).


## Estimación de proporciones y tablas cruzadas

En el análisis de encuestas de hogares, una de las tareas más comunes consiste en estimar proporciones poblacionales a partir de variables categóricas. Estas estimaciones permiten cuantificar la prevalencia de una característica en la población, por ejemplo, el porcentaje de hogares con acceso a internet o la proporción de individuos ocupados.

### Proporciones para variables binarias

La estimación de una sola proporción, $\pi$, para una variable de respuesta binaria requiere únicamente una extensión directa del estimador de razón. Al recodificar las categorías de respuesta originales en una variable indicadora $y\_{i}$ con valores $1$ (presencia) y $0$ (ausencia), el estimador de la media de la razón estima la proporción o prevalencia $\pi$ en la población de la siguiente manera (*Heeringa, S. G., 2017*):

$$
\hat{p} = \frac{\sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i=1}^{n_{h\alpha}} \omega_{h\alpha i}I(y_{i}=1)}{\sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i=1}^{n_{h\alpha}} \omega_{h\alpha i}}
= \frac{\hat{N}_{1}}{\hat{N}}.
$$

La varianza de este estimador puede aproximarse mediante la linealización de Taylor:

$$
v(\hat{p}) \dot{=} \frac{V(\hat{N}_{1})+\hat{p}^{2}V(\hat{N})-2\hat{p}\,cov(\hat{N}_{1},\hat{N})}{\hat{N}^{2}}.
$$

Cuando la proporción estimada se aproxima a 0 o 1, los intervalos de confianza estándar pueden producir límites fuera del rango $\[0,1]$. Para solventar este problema, se proponen intervalos de confianza basados en transformaciones, como el *Wilson modificado* o el uso del *logit* de $\hat{p}$:

$$
IC[\text{logit}(\hat{p})] = \left\{ \ln\left(\frac{\hat{p}}{1-\hat{p}}\right) \pm \frac{t_{1-\alpha/2,gl}\,se(\hat{p})}{\hat{p}(1-\hat{p})}\right\},
$$

cuyo resultado puede transformarse de nuevo a la escala original de proporciones.

### Proporciones para variables multinomiales

En encuestas, es común que las variables categóricas tengan más de dos categorías (multinomiales). En este caso, la estimación de la proporción para cada categoría $k$ sigue un esquema análogo:

$$
\hat{p}_{k} = \frac{\sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i=1}^{n_{h\alpha}} \omega_{h\alpha i}I(y_{i}=k)}{\sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i=1}^{n_{h\alpha}} \omega_{h\alpha i}}
= \frac{\hat{N}_{k}}{\hat{N}}.
$$

### Tablas cruzadas o de contingencia

Cuando se analizan dos variables categóricas de manera conjunta, el objetivo es estudiar si existe asociación entre ellas. Para ello, se construyen tablas cruzadas (o tablas de contingencia), que organizan los datos en una matriz de $R \times C$, donde $R$ son las categorías de la variable $x$ y $C$ las de la variable $y$.

A diferencia de un simple conteo de casos, en encuestas se utilizan **frecuencias ponderadas** que reflejan la población total representada. Cada celda $(r,c)$ contiene la frecuencia estimada:

$$
\hat{N}_{rc} = \sum_{h=1}^{H}\sum_{i \in s_{1h}}\sum_{k \in s_{hi}} w_{hik}\,I(x_{hik}=r; y_{hik}=c).
$$

Los totales marginales se obtienen como:

$$
\hat{N}_{(r+)} = \sum_{c} \hat{N}_{rc}, \quad \hat{N}_{(+c)} = \sum_{r} \hat{N}_{rc}, \quad \hat{N}_{(++)} = \sum_{r}\sum_{c} \hat{N}_{rc}.
$$

De estas frecuencias ponderadas se derivan **proporciones conjuntas y marginales**, que permiten analizar la distribución relativa de cada cruce:

$$
\hat{p}_{rc} = \frac{\hat{N}_{rc}}{\hat{N}_{++}}, \qquad 
\hat{p}_{r+} = \frac{\hat{N}_{r+}}{\hat{N}_{++}}, \qquad 
\hat{p}_{+c} = \frac{\hat{N}_{+c}}{\hat{N}_{++}}.
$$

Este enfoque ofrece una visión más completa de la relación entre categorías, ya que combina la estimación de proporciones simples con el análisis conjunto de distribuciones. Por ejemplo, se puede explorar cómo se distribuye el nivel educativo (filas) según la condición laboral (columnas), identificando patrones de desigualdad o brechas estructurales.




A continuación, siguiendo con la base de ejemplo, se estima la proporción de hombres y mujeres en pobreza y no pobreza junto con su error estándar e intervalos de confianza.



``` r
prop_sexo_zona <- diseno %>% 
                  group_by(pobreza,Sex) %>%
                  summarise(prop = survey_prop(vartype = c("se", "ci"))) %>% 
                  data.frame()

prop_sexo_zona
```

```
##   pobreza    Sex      prop    prop_se  prop_low  prop_upp
## 1       0 Female 0.5291800 0.01242026 0.5045356 0.5536829
## 2       0   Male 0.4708200 0.01242026 0.4463171 0.4954644
## 3       1 Female 0.5236123 0.01586237 0.4921512 0.5548870
## 4       1   Male 0.4763877 0.01586237 0.4451130 0.5078488
```
Como se puede observar, el 52.3% de las mujeres y el 47.6% son pobres. Generando intervalos de confianza al 95% de  (49.2%,	55.5%) para las mujeres y (44.5%,	50.7%) para los hombres.

En la librería survey existe una alternativa para estimar tablas de contingencias y es utilizando la función `svyby` como se muestra a continuación:


``` r
tab_Sex_Pobr <- svyby(formula = ~Sex, by =  ~pobreza, design = diseno, FUN = svymean)
tab_Sex_Pobr
```

```
##   pobreza SexFemale   SexMale se.SexFemale se.SexMale
## 0       0 0.5291800 0.4708200   0.01242026 0.01242026
## 1       1 0.5236123 0.4763877   0.01586237 0.01586237
```

Como se pudo observar, los argumentos que requiere la función son definir la variable a la cual se desea estimar (formula), las categorías por la cual se desea estimar (by), el diseño muestral (desing) y el parámetro que se desea estimar (FUN). Para la estimación de los intervalos de confianza se utiliza la función *confint* como sigue:


Para la estimación de los intervalos de confianza utilizar la función `confint`.

``` r
confint(tab_Sex_Pobr) %>% as.data.frame()
```

```
##                 2.5 %    97.5 %
## 0:SexFemale 0.5048367 0.5535232
## 1:SexFemale 0.4925226 0.5547019
## 0:SexMale   0.4464768 0.4951633
## 1:SexMale   0.4452981 0.5074774
```
Los cuales coinciden con los generados anteriormente usando la funicón *group_by*.

Otro análisis de interés relacionado con tablas de doble entrada en encuestas de hogares es estimar el porcentaje de desempleados por sexo.


``` r
tab_Sex_Ocupa <- svyby(formula = ~Sex,  by = ~Employment,
                       design = diseno, FUN = svymean)
tab_Sex_Ocupa
```

```
##            Employment SexFemale   SexMale se.SexFemale se.SexMale
## Unemployed Unemployed 0.2726730 0.7273270   0.05351318 0.05351318
## Inactive     Inactive 0.7703406 0.2296594   0.02340005 0.02340005
## Employed     Employed 0.4051575 0.5948425   0.01851986 0.01851986
```

De la anterior salida se puede observar que, el 27.2% de las mujeres y el 72.7% de los hombres están desempleados con errores estándares para estas estimaciones de 5.3% para mujeres y hombres. cuyos intervalos de confianza se calculan a continuación:


``` r
confint(tab_Sex_Ocupa) %>% as.data.frame()
```

```
##                          2.5 %    97.5 %
## Unemployed:SexFemale 0.1677891 0.3775570
## Inactive:SexFemale   0.7244773 0.8162038
## Employed:SexFemale   0.3688592 0.4414557
## Unemployed:SexMale   0.6224430 0.8322109
## Inactive:SexMale     0.1837962 0.2755227
## Employed:SexMale     0.5585443 0.6311408
```


Si ahora el objetivo es estimar la pobreza, pero por las distintas regiones que se tienen en la base de datos. Primero, dado que la variable *pobreza* es de tipo numérica, es necesario convertirla en factor y luego realizar la estimación con la función `svyby`.



``` r
tab_region_pobreza <- svyby(formula = ~as.factor(pobreza),  by = ~Region, 
                            design =  diseno, FUN = svymean)
tab_region_pobreza
```

```
##              Region as.factor(pobreza)0 as.factor(pobreza)1
## Norte         Norte           0.6410318           0.3589682
## Sur             Sur           0.6561536           0.3438464
## Centro       Centro           0.6346152           0.3653848
## Occidente Occidente           0.5991839           0.4008161
## Oriente     Oriente           0.5482079           0.4517921
##           se.as.factor(pobreza)0 se.as.factor(pobreza)1
## Norte                 0.05547660             0.05547660
## Sur                   0.04348901             0.04348901
## Centro                0.07858599             0.07858599
## Occidente             0.04670473             0.04670473
## Oriente               0.08849644             0.08849644
```
De lo anterior se puede concluir que, en la región Norte, el 35% de las personas están en estado de pobreza mientras que en el sur es el 34%. La pobreza más alta se tiene en la región oriente con un 45% de pobres. Los errores estándares de las estimaciones.



### Prueba de independencia $\chi^{2}$

Una **prueba de hipótesis** es un procedimiento estadístico que permite evaluar la validez de una afirmación sobre una población, comparando la evidencia empírica de una muestra con lo que se esperaría si dicha afirmación fuera cierta. En el caso de las **pruebas de independencia**, se plantea como hipótesis nula ($H_{0}$) que dos variables categóricas son independientes, es decir, que la distribución de una no depende de las categorías de la otra. Matemáticamente, esta hipótesis puede expresarse como:

$$
H_0: P_{rc}^0 = P_{r+} \times P_{+c}, \quad \text{para todo } r = 1,\ldots,R \text{ y } c = 1,\ldots,C
$$

donde $P_{rc}^0$ representa la proporción esperada en la celda $(r,c)$ bajo independencia, y $P_{r+}$ y $P_{+c}$ las proporciones marginales de las filas y columnas, respectivamente.

En consecuencia, la prueba consiste en contrastar las proporciones estimadas $\hat{p}*{rc}$ con las esperadas $P*{rc}^0$. Cuando las diferencias son pequeñas, los datos respaldan la hipótesis nula; en cambio, discrepancias significativas conducen al rechazo de $H_0$.



#### Prueba $\chi^{2}$ clásica

Para una tabla de $2 \times 2$, la estadística de Pearson se define como:

$$
\chi^{2}  =  n_{++}\sum_{r}\sum_{c}\frac{\left(p_{rc}-\hat{\pi}_{rc}\right)^{2}}{\hat{\pi}_{rc}}
$$

donde $\hat{\pi}*{rc}=\frac{n*{r+}}{n_{++}} \cdot \frac{n_{+c}}{n_{++}}$ corresponde a las proporciones esperadas bajo independencia.

En términos prácticos, las **tablas de contingencia ponderadas** constituyen el insumo de la prueba, ya que cada celda $\hat{N}_{rc}$ estima el número de personas en la población en esa combinación de categorías. A partir de ellas se calculan frecuencias relativas y se evalúa la independencia de las variables.


#### Ajustes para encuestas: prueba de Rao-Scott

En encuestas de hogares, el análisis es más complejo porque el diseño muestral (estratificación, conglomerados y ponderación) altera la varianza de los estimadores. Por ello, la prueba $\chi^{2}$ debe ajustarse para reflejar estas particularidades.

El **ajuste de Rao-Scott** (Rao y Scott, 1984; Thomas y Rao, 1987) corrige la prueba clásica mediante el **efecto de diseño generalizado (GDEFF)**, lo que produce un estadístico robusto:

$$
X_{RS}^2 = \frac{n_{++}}{GDEFF} \sum_r \sum_c \frac{(\hat{p}_{rc} - \hat{P}_{rc}^0)^2}{\hat{P}_{rc}^0}
$$

Bajo $H_0$, $X_{RS}^2$ sigue aproximadamente una distribución $\chi^2$ con $(R-1)(C-1)$ grados de libertad. En casos de **muestras pequeñas**, es común aplicar ajustes basados en la distribución F, que mejoran la precisión de los resultados. Actualmente, las pruebas de Rao-Scott constituyen el estándar en el análisis de datos categóricos en encuestas complejas (Heeringa, West y Berglund, 2017).



#### Ejemplo en R

El paquete **`survey`** en R implementa estas pruebas a través de la función `svychisq()`, que aplica automáticamente las correcciones de Rao-Scott. A modo de ejemplo, para evaluar si la pobreza es independiente del sexo, se ejecuta:


``` r
svychisq(formula = ~Sex + pobreza, design = diseno, statistic="F")
```

```
## 
## 	Pearson's X^2: Rao & Scott adjustment
## 
## data:  NextMethod()
## F = 0.056464, ndf = 1, ddf = 119, p-value = 0.8126
```

* Si el **p-valor** es superior al 5%, no se rechaza $H_0$, concluyendo que no existe evidencia de asociación entre pobreza y sexo.
* Si el **p-valor** es inferior al 5%, se rechaza $H_0$, lo que sugiere dependencia entre las variables.

De manera similar, se pueden evaluar otras relaciones, como desempleo y sexo o pobreza y región:


``` r
svychisq(formula = ~Sex + Employment, design = diseno, statistic = "F")
```

```
## 
## 	Pearson's X^2: Rao & Scott adjustment
## 
## data:  NextMethod()
## F = 62.251, ndf = 1.6865, ddf = 200.6978, p-value < 2.2e-16
```

``` r
svychisq(formula = ~Region + pobreza, design = diseno, statistic = "F")
```

```
## 
## 	Pearson's X^2: Rao & Scott adjustment
## 
## data:  NextMethod()
## F = 0.48794, ndf = 3.0082, ddf = 357.9731, p-value = 0.6914
```


Para realizar la prueba de independencia $\chi^{2}$ en `R`, se utilizará la función *svychisq* del paquete *srvyr*. Esta función requiere que se definan las variables de interés (formula) y requiere que se le defina el diseño muestral (desing). Ahora, para ejemplificar el uso de esta función tomaremos la base de datos de ejemplo y se probará si la pobreza es independiente del sexo. 


**Razón de odds**

Como lo menciona *Monroy, L. G. D. (2018)* La traducción más aproximada del término odds es “la ventaja”, en términos de probabilidades es la posibilidad de que un evento ocurra con relación a que no ocurra, es decir, es un número que expresa cuánto más probable es que se produzca un evento frente a que no se produzca. También se puede utilizar para cuantificar la asociación entre los niveles de una variable y un factor categórico *(Heeringa, S. G. 2017)*.

Suponga que se desea calcular la siguiente razón de odds. 

$$
 \frac{\frac{P(Sex = Female \mid pobreza = 0 )}{P(Sex = Female \mid pobreza = 1 )}}{
 \frac{P(Sex = Male \mid pobreza = 1 )}{P(Sex = Male \mid pobreza = 0 )}
 }
$$

El procedimiento para realizarlo en `R` sería, primero estimar las proporciones de la tabla cruzada entre las variables sexo y pobreza:


``` r
tab_Sex_Pobr <- svymean(x = ~interaction (Sex, pobreza), design = diseno, 
                        se=T, na.rm=T, ci=T, keep.vars=T)

tab_Sex_Pobr %>%  as.data.frame()
```

```
##                                        mean         SE
## interaction(Sex, pobreza)Female.0 0.3218703 0.01782709
## interaction(Sex, pobreza)Male.0   0.2863733 0.01768068
## interaction(Sex, pobreza)Female.1 0.2051285 0.01659697
## interaction(Sex, pobreza)Male.1   0.1866279 0.01778801
```

Luego, se realiza el contraste dividiendo cada uno de los elementos de la expresión mostrada anteriormente:



``` r
svycontrast(stat = tab_Sex_Pobr, 
contrasts = quote((`interaction(Sex, pobreza)Female.0`/`interaction(Sex, pobreza)Female.1`) /(`interaction(Sex, pobreza)Male.0`/ `interaction(Sex, pobreza)Male.1`)))
```

```
##           nlcon     SE
## contrast 1.0226 0.0961
```

Obtiendo que, se estima que el odds de las mujeres que no están en estado de pobreza es 1.02 comparandolo con el odds de los hombres. En otras palabras, se estima que las probabilidades de que las mujeres no estén en estado de pobreza sin tener en cuenta ninguna otra variable de la encuesta es cera de 2% mayor que las probabilidades de los hombres.

**Diferencia de proporciones en tablas de contingencias**

Como lo menciona *Heeringa, S. G. (2017)* las estimaciones de las proporciones de las filas en las tablas de doble entrada son, de hecho, estimaciones de subpoblaciones en las que la subpoblación se define por los niveles de la variable factorial. Ahora bien, si el interés se centra en estimar diferencias de las proporciones de las categorías entre dos niveles de una variable factorial, se pueden utilizando contrastes. 

A manera de ejemplo, se requiere estimar ahora, el contraste de proporciones de mujeres en estado de pobreza versus los hombres en esta misma condición  ($\hat{p}_F - \hat{p}_M$). Para ellos, primero, estimemos la proporción de hombres y mujeres en estado de pobreza como se ha mostrado en capítulos anteriores:


``` r
(tab_sex_pobreza <- svyby(formula = ~pobreza, by = ~Sex, 
                          design = diseno , svymean, na.rm=T,
                          covmat = TRUE, vartype = c("se", "ci")))
```

```
##           Sex   pobreza         se      ci_l      ci_u
## Female Female 0.3892389 0.03159581 0.3273123 0.4511656
## Male     Male 0.3945612 0.03662762 0.3227724 0.4663501
```

Ahora bien, para calcular la estimación de la diferencia de proporciones junto con sus errores estándares, se realizarán los siguientes pasos:

-   *Paso 1:* Calcular la diferencia de estimaciones 

``` r
0.3892 - 0.3946			 
```

```
## [1] -0.0054
```


Con la función `vcov` se obtiene la matriz de covarianzas:


``` r
library(kableExtra)
vcov(tab_sex_pobreza)%>% data.frame() %>% 
  kable(digits = 10,
        format.args = list(scientific = FALSE))
```


\begin{tabular}{l|r|r}
\hline
  & Female & Male\\
\hline
Female & 0.0009982953 & 0.0009182927\\
\hline
Male & 0.0009182927 & 0.0013415823\\
\hline
\end{tabular}

-   *Paso 2:* El cálculo del error estándar es:   


``` r
sqrt(0.0009983 + 0.0013416 - 2*0.0009183)
```

```
## [1] 0.02243435
```


Ahora bien, aplicando la función `svycontrast` se puede obtener la estimación de la diferencia de proporciones anterior: 


``` r
svycontrast(tab_sex_pobreza,
            list(diff_Sex = c(1, -1))) %>%
  data.frame()
```

```
##              contrast   diff_Sex
## diff_Sex -0.005322297 0.02243418
```

De lo que se concluye que, la diferencia entre las proporciones de mujeres y hombres en estado de pobreza es -0.005 (-0.5%) con una desviación estándar de 0.022.

Otro ejercicio de interés en un análisis de encuestas de hogares es verificar la diferencia del desempleo por sexo. Al igual que el ejemplo anterior, se inicia con la estimación del porcentaje de desempleados por sexo:


``` r
tab_sex_desempleo <- svyby(formula = ~desempleo, by = ~Sex, 
                           design  = diseno %>% filter(!is.na(desempleo)) , 
                           FUN     = svymean, na.rm=T, covmat = TRUE,
                           vartype = c("se", "ci"))
tab_sex_desempleo
```

```
##           Sex  desempleo          se       ci_l       ci_u
## Female Female 0.02168620 0.005580042 0.01074952 0.03262288
## Male     Male 0.06782601 0.012161141 0.04399062 0.09166141
```

Para calcular la estimación de la diferencia de proporciones junto con sus errores estándares, se realizarán los siguientes pasos:

-   *Paso 1*: Diferencia de las estimaciones 

``` r
0.02169 - 0.06783 	
```

```
## [1] -0.04614
```

Estimación de la matriz de covarianza: 


``` r
vcov(tab_sex_desempleo) %>% data.frame() %>% 
  kable(digits = 10,
        format.args = list(scientific = FALSE))
```


\begin{tabular}{l|r|r}
\hline
  & Female & Male\\
\hline
Female & 0.0000311369 & 0.0000208130\\
\hline
Male & 0.0000208130 & 0.0001478933\\
\hline
\end{tabular}

-   *Paso 2*: Estimación del error estándar. 

``` r
sqrt(0.00003114	 + 0.00014789 - 2*0.00002081)
```

```
## [1] 0.0117222
```

Siguiendo el ejemplo anterior, utilizando la función `svycontrast` se tiene que:


``` r
svycontrast(tab_sex_desempleo,
            list(diff_Sex = c(-1, 1))) %>%
  data.frame()
```

```
##            contrast   diff_Sex
## diff_Sex 0.04613982 0.01172195
```

de lo que se concluye que, la estimación del contraste es 0.04 (4%) con un error estándar de 0.011.

Otro ejercicio que se puede realizar en una encuesta de hogares es ahora estimar la proporción de desempleados por región. Para la realización de este ejercicio, se seguirán los pasos de los dos ejemplos anteriores:


``` r
tab_region_desempleo <- svyby(formula =  ~desempleo, by = ~Region, 
                              design  = diseno %>% filter(!is.na(desempleo)) , 
                              FUN     = svymean, na.rm=T, covmat = TRUE,
                              vartype = c("se", "ci"))
tab_region_desempleo
```

```
##              Region  desempleo         se        ci_l       ci_u
## Norte         Norte 0.04877722 0.02002293 0.009532997 0.08802144
## Sur             Sur 0.06563877 0.02375124 0.019087202 0.11219034
## Centro       Centro 0.03873259 0.01240317 0.014422832 0.06304235
## Occidente Occidente 0.03996523 0.01229650 0.015864529 0.06406592
## Oriente     Oriente 0.02950231 0.01256905 0.004867428 0.05413719
```

Ahora, el interés es realizar los contrastes siguientes para desempleo: 

$\hat{p}_{Norte} - \hat{p}_{Centro} = 0.01004$, 
$\hat{p}_{Sur} - \hat{p}_{Centro} = 0.02691$ 	
$\hat{p}_{Occidente} - \hat{p}_{Oriente} = 0.01046$	

Escrita de forma matricial sería: 

$$
\left[\begin{array}{ccccc}
1 & 0 & -1 & 0 & 0\\
0 & 1 & -1 & 0 & 0\\
0 & 0 & 0 & 1 & -1
\end{array}\right]
$$

La matriz de varianzas y covarianzas es:


``` r
vcov(tab_region_desempleo)%>%
  data.frame() %>% 
  kable(digits = 10,
        format.args = list(scientific = FALSE))
```

Por tanto, la varianza estimada está dada por:


``` r
sqrt(0.0002981 + 0.0002884 - 2*0)
```

```
## [1] 0.02421776
```

``` r
sqrt(0.0001968 + 0.0002884 - 2*0)
```

```
## [1] 0.02202726
```

``` r
sqrt(0.0001267 + 0.0004093 - 2*0)
```

```
## [1] 0.02315167
```


Usando la función `svycontrast`, la estimación de los contrastes sería:


``` r
svycontrast(tab_region_desempleo, list(
                             Norte_sur = c(1, 0, -1, 0, 0),
                             Sur_centro = c(0, 1, -1, 0, 0),
                             Occidente_Oriente = c(0, 0, 0, 1, -1))) %>% data.frame()
```

```
##                     contrast         SE
## Norte_sur         0.01004463 0.02355327
## Sur_centro        0.02690618 0.02679477
## Occidente_Oriente 0.01046292 0.01758365
```

Por último, repitiendo el contraste anterior y los pasos para resolverlo, pero ahora utilizando la variable pobreza se tiene:


``` r
tab_region_pobreza <- svyby(formula = ~pobreza, by = ~Region, 
                            design = diseno %>% filter(!is.na(desempleo)) , 
                            FUN = svymean, na.rm=T, covmat = TRUE,
                            vartype = c("se", "ci"))
tab_region_pobreza
```

```
##              Region   pobreza         se      ci_l      ci_u
## Norte         Norte 0.3262813 0.04800361 0.2321959 0.4203666
## Sur             Sur 0.2946736 0.04794292 0.2007072 0.3886400
## Centro       Centro 0.3233923 0.07211854 0.1820426 0.4647421
## Occidente Occidente 0.3673286 0.04400234 0.2810856 0.4535716
## Oriente     Oriente 0.3870632 0.09160150 0.2075276 0.5665989
```

El interés se centra en realizar los contrastes siguientes para pobreza: 

$\hat{p}_{Norte} - \hat{p}_{Centro}$, 
$\hat{p}_{Sur}-\hat{p}_{Centro}$ 	
$\hat{p}_{Occidente}-\hat{p}_{Oriente}$	

Escrita de forma matricial es: 

$$
\left[\begin{array}{ccccc}
1 & 0 & -1 & 0 & 0\\
0 & 1 & -1 & 0 & 0\\
0 & 0 & 0 & 1 & -1
\end{array}\right]
$$

Y, utilizando la función `svycontrast` se obtiene:


``` r
svycontrast(tab_region_pobreza, list(
                Norte_sur = c(1, 0, -1, 0, 0),
                Sur_centro = c(0, 1, -1, 0, 0),
                Occidente_Oriente = c(0, 0, 0, 1, -1))) %>% data.frame()
```

```
##                       contrast         SE
## Norte_sur          0.002888908 0.08663389
## Sur_centro        -0.028718759 0.08660027
## Occidente_Oriente -0.019734641 0.10162205
```






<!--chapter:end:05-Categóricas.Rmd-->



# Referencias 

-   Asparouhov, T., & Muthen, B. (2006, August). Multilevel modeling of complex survey data. In Proceedings of the joint statistical meeting in Seattle (pp. 2718-2726).

-   Asparouhov, T. (2006). General multi-level modeling with sampling weights. Communications in Statistics—Theory and Methods, 35(3), 439-460.

-   Pfeffermann, D., Skinner, C. J., Holmes, D. J., Goldstein, H., & Rasbash, J. (1998). Weighting for unequal selection probabilities in multilevel models. Journal of the Royal Statistical Society: series B (statistical methodology), 60(1), 23-40.

-   Cai, T. (2013). Investigation of ways to handle sampling weights for multilevel model analyses. Sociological Methodology, 43(1), 178-219.

-   Finch, W. H., Bolin, J. E., & Kelley, K. (2019). Multilevel modeling using R. Crc Press.

-   Merlo, J., Chaix, B., Ohlsson, H., Beckman, A., Johnell, K., Hjerpe, P., ... & Larsen, K. (2006). A brief conceptual tutorial of multilevel analysis in social epidemiology: using measures of clustering in multilevel logistic regression to investigate contextual phenomena. Journal of Epidemiology & Community Health, 60(4), 290-297.

-   Sarndal, C., Swensson, B. &Wretman, J. (1992), Model Assisted Survey Sampling, Springer, New York.

-   Rojas, H. A. G. (2016). Estrategias de muestreo: diseño de encuestas y estimación de parámetros. Ediciones de la U.

-   Santana Sepúlveda, S., & Mateos Farfán, E. (2014). El arte de programar en R: un lenguaje para la estadística.

- Lumley, T. (2011). Complex surveys: a guide to analysis using R. John Wiley & Sons.

- Bache, S. M., Wickham, H., Henry, L., & Henry, M. L. (2022). Package ‘magrittr’.

-   Tellez Piñerez, C. F., & Lemus Polanía, D. F. (2015). Estadística Descriptiva y Probabilidad con aplicaciones en R. Fundación Universitaria Los Libertadore.

-   Groves, R. M., Fowler Jr, F. J., Couper, M. P., Lepkowski, J. M., Singer, E., & Tourangeau, R. (2011). Survey methodology. John Wiley & Sons.

-   Tille, Y. & Ardilly, P. (2006), Sampling Methods: Exercises and Solutions, Springer.

-   Gambino, J. G., & do Nascimento Silva, P. L. (2009). Sampling and estimation in household surveys. In Handbook of Statistics (Vol. 29, pp. 407-439). Elsevier.

-   Cochran, W. G. (1977) *Sampling Techniques*. John Wiley and Sons. 

-   Gutiérrez, H. A. (2017)  `TeachingSampling`. *R package*.

-   Wickham, H., Chang, W., & Wickham, M. H. (2016). Package ‘ggplot2’. Create elegant data visualisations using the grammar of graphics. Version, 2(1), 1-189.

-   Lumley, T. (2020). Package ‘survey’. Available at the following link: https://cran. r-project. org.

-   Hansen, M. H., & Steinberg, J. (1956). Control of errors in surveys. Biometrics, 12(4), 462-474.

- Heeringa, S. G., West, B. T., & Berglund, P. A. (2017). Applied survey data analysis. chapman and hall/CRC.

-   Valliant, R., Dever, J.A., and Kreuter, F., Practical Tools for Designing and Weighting Survey Samples, Springer, New York, 2013.

-   Valliant, R., Dorfman, A.H., and Royall, R.M., Finite Population Sampling and Inference: A Prediction Approach, John Wiley & Sons, New York, 2000.

-   Loomis, D., Richardson, D.B., and Elliott, L., Poisson regression analysis of ungrouped data, Occupational and Environmental Medicine, 62, 325–329, 2005.

-   Kovar, J.G., Rao, J.N.K., and Wu, C.F.J., Bootstrap and other methods to measure errors in survey estimates, Canadian Journal of Statistics, 16(Suppl.), 25–45, 1988.

-   Binder, D.A. and Kovacevic, M.S., Estimating some measures of income inequality from survey data: An application of the estimating equations approach, Survey Methodology, 21(2), 137–145, 1995.

-   Kovacevic, M. S., & Binder, D. A. (1997). Variance estimation for measures of income inequality and polarization-the estimating equations approach. Journal of Official Statistics, 13(1), 41.

-   Bautista, J. (1998), Diseños de muestreo estadístico, Universidad Nacional de Colombia.

-   Monroy, L. G. D., Rivera, M. A. M., & Dávila, L. R. L. (2018). Análisis estadístico de datos categóricos. Universidad Nacional de Colombia.

-   Kish, L. and Frankel, M.R., Inference from complex samples, Journal of the Royal Statistical Society, Series B, 36, 1–37, 1974.

-   Fuller, W.A., Regression analysis for sample survey, Sankyha, Series C, 37, 117–132, 1975.

-   Shah, B.V., Holt, M.M., and Folsom, R.F., Inference about regression models from sample survey data, Bulletin of the International Statistical Institute, 41(3), 43–57, 1977.

-   Skinner, C.J., Holt, D., and Smith, T.M.F., Analysis of Complex Surveys, John Wiley & Sons, New York, 1989.

-   Binder, D.A., On the variances of asymptotically normal estimators from complex surveys, International Statistical Review, 51, 279–292, 1983.

-   Fuller, W.A., Regression estimation for survey samples (with discussion), Survey Methodology, 28(1), 5–23, 2002.

-   Pfeffermann, D., Modelling of complex survey data: Why model? Why is it a problem? How can we approach it? Survey Methodology, 37(2), 115–136, 2011.

-   Wolter, K.M., Introduction to Variance Estimation (2nd ed.), Springer-Verlag, New York, 2007.

-   Tellez, C. F., & Morales, M. A. (2016). Modelos Estadísticos lineales con aplicaciones en R. Ediciones de la U.

- Fay, R.E., On adjusting the Pearson Chi-square statistic for cluster sampling, In Proceedings of the Social Statistics Section, American Statistical Association, Washington, DC, 402–405, 1979.

- Fay, R.E., A jack-knifed chi-squared test for complex samples, Journal of the American Statistical Association, 80, 148–157, 1985.

- Fellegi, I.P., Approximate tests of independence and goodness of fit based on stratified multistage samples, Journal of the American Statistical Association, 75, 261–268, 1980.

- Thomas, D.R. and Rao, J.N.K., Small-sample comparisons of level and power for simple goodness-of-fit statistics under cluster sampling, Journal of the American Statistical Association, 82, 630–636, 1987.

- Rao, J.N.K. and Scott, A.J., On chi-squared test for multiway contingency tables with cell proportions estimated from survey data, The Annals of Statistics, 12, 46–60, 1984.

- Van Buuren, S., Flexible Imputation of Missing Data, Chapman & Hall, Boca Raton, FL, 2012.

- Carpenter, J.R. and Kenward, M.G., Multiple Imputation and Its Application, John Wiley & Sons, Chichester, West Sussex, UK, 2013.

- Berglund, P.A. and Heeringa, S.G., Multiple Imputation of Missing Data Using SAS®, SAS Institute Inc., Cary, NC, 2014.

- Chambers, R.L., Steel, D.G., Wang, S., and Welsh, A.H., Maximum Likelihood Estimation for Sample Surveys, Chapman & Hall, Boca Raton, FL, 2012.

- Zhou, H., Elliott, M.R., and Raghunathan, T.E., Multiple imputation in two-stage cluster samples using the weighted finite population Bayesian Bootstrap, Journal of Survey Statistics and Methodology, 4, 139–170, 2016a.

- Zhou, H., Elliott, M.R., and Raghunathan, T.E., Synthetic multiple-imputation procedure for multistage complex samples, Journal of Official Statistics, 32(1), 231–256, 2016b.

- Kim, J.K. and Shao, J., Statistical Methods for Handling Incomplete Data, Chapman & Hall, Boca Raton, FL, 2014.

- Kim, J.K. and Fuller, W.A., Fractional Hotdeck imputation, Biometrika, 89, 470–477, 2004.

- StataCorp., Release 14, P Manual, STATA Survey Data Manual, Stata Press, College Station, TX, 2015.

- Raghunathan, T.E., Missing Data Analysis in Practice, Chapman & Hall/CRC Interdisciplinary Statistics, Boca Raton, FL, 2016.

- Rubin, D. B. (1987). Multiple imputation for survey nonresponse.

- Goldstein, H. (2011). Multilevel statistical models (Vol. 922). John Wiley & Sons.

- Data analysis using regression and multilevel/hierarchical models" de Andrew Gelman y Jennifer Hill (2006)

-   Sophia, R. H., & Skrondal, A. (2012). Multilevel and longitudinal modeling using Stata. STATA press.

-   Browne, W. J., & Draper, D. (2006). A comparison of Bayesian and likelihood-based methods for fitting multilevel models.



<!--chapter:end:99-Referencias.Rmd-->

