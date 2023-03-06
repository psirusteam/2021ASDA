

# Análisis de variables categóricas en encuestas de hogares

En ocasiones, no es sencillo distinguir entre las variables denominada cualitativos y cuantitativos puesto que, algunas variables de tipo cuantitativo pueden llegar a considerarse como categóricas si se divide el rango de valores de la variable en intervalos o categorías. Un ejemplo de esto es la variable edad, que en una encuesta de hogares se pregunta como variable cuantitativa y esta se puede dividir, por ejemplo, en Colombia, en las siguientes categorías: Adolescencia (12 - 18 años), Juventud (14 - 26 años), Adultez (27- 59 años), Persona Mayor (60 años o más), envejecimiento y vejez.  

Por otro lado, una variable categórica también se puede convertir en una variable cuantitativa realizando, por ejemplo, un análisis de correspondencias. Esto ocurre en muchas situaciones cuando se requiere construir índices. Por ejemplo, índice de fuerza laboral. En el contexto de encuestas, las preguntas que contienen variables categóricas son uno de los tipos de preguntas más usuales. Estas preguntas suelen representarse en resultados de porcentajes. Por ejemplo, preguntas relacionadas con parentesco, sexo, si es jefe o jefa de hogar, si la vivienda contiene agua potable, etc.


```r
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



```r
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



```r
diseno <- diseno %>% mutate(
                     pobreza = ifelse(Poverty != "NotPoor", 1, 0),
                     desempleo = ifelse(Employment == "Unemployed", 1, 0),
                     edad_18 = case_when(Age < 18 ~ "< 18 anios", TRUE ~ ">= 18 anios")
)
```

Como se pudo observar en el código anterior, se ha introducido la función `case_when` la cual es una extensión del a función `ifelse` que permite crear múltiples categorías a partir de una o varias condiciones. 

Como se ha mostrado anteriormente, en ocasiones se desea realizar estimaciones por sub-grupos de la población, en este caso se extraer 4 sub-grupos de la encuesta y se definen a continuación:


```r
sub_Urbano <- diseno %>%  filter(Zone == "Urban")
sub_Rural  <- diseno %>%  filter(Zone == "Rural")
sub_Mujer  <- diseno %>%  filter(Sex == "Female")
sub_Hombre <- diseno %>%  filter(Sex == "Male")
```

## Estimaciones de totales

En esta sección se realizarán los procesos de estimación de variables categóricas. En primera instancia se presenta cómo se estima los tamaños de la población y subpoblaciones.



```r
tamano_zona <- diseno %>% group_by(Zone) %>% 
               summarise( n = unweighted(n()), 
                          Nd = survey_total(vartype = c("se","ci")))

tamano_zona
```

```
## # A tibble: 2 × 6
##   Zone      n    Nd Nd_se Nd_low Nd_upp
##   <chr> <int> <dbl> <dbl>  <dbl>  <dbl>
## 1 Rural  1297 72102 3062. 66039. 78165.
## 2 Urban  1308 78164 2847. 72526. 83802.
```

En la tabla anterior, *n* denota el número de observaciones en la muestra por Zona y *Nd* denota la estimación del total de observaciones en la población. Adicionalmente, en el código anterior se introdujo la función `unweighted` la cual, calcula resúmenes no ponderados a partir de un conjunto de datos de encuestas.

Para el ejemplo, el tamaño de muestra en la zona rural fue de 1297 personas y para la urbana fue de 1308. Con esta información se logró estimar una población de 72102 con una desviación estándar de 3062.204 en la zona rural y una población de 78164 con desviación estándar de 2847.221 en la zona urbana. Así mismo, con una confianza del 95% se construyeron unos intervalos de confianza para el tamaño poblacional en la zona rural de  (66038.5,	78165.4) y para la urbana de (72526.2,	83801.7).

Ahora bien, empleando una sintaxis similar a la anterior es posible estimar el número de personas en condición de pobreza extrema, pobreza y no pobres como sigue:


```r
tamano_pobreza <- diseno %>% group_by(Poverty) %>% 
                  summarise( Nd = survey_total(vartype = c("se","ci")) )
tamano_pobreza
```

```
## # A tibble: 3 × 5
##   Poverty      Nd Nd_se Nd_low  Nd_upp
##   <fct>     <dbl> <dbl>  <dbl>   <dbl>
## 1 NotPoor  91398. 4395. 82696. 100101.
## 2 Extreme  21519. 4949. 11719.  31319.
## 3 Relative 37349. 3695. 30032.  44666.
```

De la tabla anterior podemos concluir que, la cantidad estimada de personas en estado de no pobreza son 91398.3, en pobreza 37348.9 y pobreza extrema de 21518.7. os demás parámetros estimados se interpretan de la misma manera que para la estimación desagregada por zona. 

En forma similar es posible estimar el número de personas debajo de la línea de pobreza. 


```r
tamano_pobreza <- diseno %>% 
                  group_by(pobreza) %>% 
                  summarise(
                  Nd = survey_total(vartype = c("se","ci")))
tamano_pobreza
```

```
## # A tibble: 2 × 5
##   pobreza     Nd Nd_se Nd_low  Nd_upp
##     <dbl>  <dbl> <dbl>  <dbl>   <dbl>
## 1       0 91398. 4395. 82696. 100101.
## 2       1 58868. 5731. 47519.  70216.
```

Concluyendo para este ejemplo que, 58867.6 personas están por debajo de la línea de pobreza con una desviación estándar de 5731.3 y un intervalo de confianza (47518.9	70216.3).

Otra variable de interés en encuestas de hogares es conocer el estado de ocupación de las personas. A continuación, se muestra el código computacional:


```r
tamano_ocupacion <- diseno %>% 
                    group_by(Employment) %>% 
                    summarise( Nd = survey_total(vartype = c("se","ci")))
tamano_ocupacion
```

```
## # A tibble: 4 × 5
##   Employment     Nd Nd_se Nd_low Nd_upp
##   <fct>       <dbl> <dbl>  <dbl>  <dbl>
## 1 Unemployed  4635.  761.  3129.  6141.
## 2 Inactive   41465. 2163. 37183. 45748.
## 3 Employed   61877. 2540. 56847. 66907.
## 4 <NA>       42289. 2780. 36784. 47794.
```
De los resultados de la estimación se puede concluir que, 4634.8 personas están desempleadas con un intervalo de confianza de (3128.6, 6140.9). 41465.2 personas están inactivas con un intervalo de confianza de (37182.6,	45747.8) y por último, 61877.0 personas empleadas con intervalos de confianza (36784.2, 47793.5).

Utilizando la función `group_by` es posible obtener resultados por más de un nivel de agregación. A continuación, se muestra la estimación ocupación desagregada por niveles de pobreza:


```r
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

Otro parámetro de interés en las encuestas de hogares, particularmente con variables categóricas es la estimación de las proporciones poblacionales. En esta sección se estudiará la estimación de proporciones y sus errores estándares. En términos de notación se define la estimación de proporciones de población como $p$ y proporciones de población como $\pi$. Es normal observar que en muchos paquetes estadísticos optan por generar estimaciones de proporciones y errores estándar en la escala de porcentaje. *R* Genera las estimaciones de proporciones en escala [0,1]. A continuación, se presenta el código computacional para estimar la proporción de personas por zona:


```r
prop_zona <- diseno %>% group_by(Zone) %>% 
             summarise(
             prop = survey_mean(vartype = c("se","ci"), 
                    proportion = TRUE ))
prop_zona
```

```
## # A tibble: 2 × 5
##   Zone   prop prop_se prop_low prop_upp
##   <chr> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Rural 0.480  0.0140    0.452    0.508
## 2 Urban 0.520  0.0140    0.492    0.548
```
Como se pudo observar, se usó la función `survey_mean` para la estimación. Sin embargo, con el parámetro "proportion = TRUE", se le indica a `R` que lo que se desea estimar es una proporción. Para este ejemplo se puede observar que, el 47.9% de las personas viven en zona rural obteniendo un intervalo de confianza comprendido entre (45.2%,	50.7%) y el 52% de las personas viven en la zona urbana con un intervalo de confianza de (49.2%, 54.7%).

La librería `survey` tiene implementado una función específica para estimar proporciones la cual es `survey_prop` que genera los mismos resultados mostrados anteriormente. Le queda al lector la decisión de usar la función con la que más cómodo se sienta. A continuación, se muestra un ejemplo del uso de la función `survey_prop`:



```r
prop_zona2 <- diseno %>% group_by(Zone) %>% 
              summarise( prop = survey_prop(vartype = c("se","ci") ))
prop_zona2
```

```
## # A tibble: 2 × 5
##   Zone   prop prop_se prop_low prop_upp
##   <chr> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Rural 0.480  0.0140    0.452    0.508
## 2 Urban 0.520  0.0140    0.492    0.548
```


Si el interés ahora se centra en estimar  subpoblaciones por ejemplo, proporción de hombres y mujeres que viven en la zona urbana, el código computacional es:


```r
prop_sexoU <- sub_Urbano %>% group_by(Sex) %>% 
              summarise(prop = survey_prop(vartype = c("se","ci")))
prop_sexoU
```

```
## # A tibble: 2 × 5
##   Sex     prop prop_se prop_low prop_upp
##   <chr>  <dbl>   <dbl>    <dbl>    <dbl>
## 1 Female 0.537  0.0130    0.511    0.563
## 2 Male   0.463  0.0130    0.437    0.489
```

Arrojando como resultado que, el 53.6% de las mujeres y 46.4%  de los hombres viven en la zona urbana y con intervalos de confianza (51%, 56.2%) y (43.7%, 48.9%) respectivamente. Los intervalos anteriores nos reflejan que, con una confianza del 95% la cantidad estimada de mujeres que viven en la zona urbana es de56% y de hombres es de 48%.

Realizando el mismo ejercicio anterior, pero ahora en la zona rural se tiene:



```r
prop_sexoR <- sub_Rural %>% group_by(Sex) %>% 
              summarise( n = unweighted(n()),
                         prop = survey_prop(vartype = c("se","ci")))
prop_sexoR
```

```
## # A tibble: 2 × 6
##   Sex        n  prop prop_se prop_low prop_upp
##   <chr>  <int> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Female   679 0.516 0.00824    0.500    0.533
## 2 Male     618 0.484 0.00824    0.467    0.500
```

el 51.6% de las mujeres y el 48.4% de los hombres viven en la zona rural con intervalos de confianza de (49.9%, 53.2%) y (46,7%, 50%) respectivamente. Los intervalos de confianza anteriores nos reflejan que, inclusive, con una confianza del 95%, la cantidad estimada de mujeres en la zona rural es de 53% y de hombres es de 50%. 


Ahora bien, si nos centramos solo en la población de hombres en la base de datos y se desea estimar la proporción de hombres por zona, el código computacional es el siguiente: 



```r
prop_ZonaH <- sub_Hombre %>% group_by(Zone) %>% 
              summarise(prop = survey_prop(vartype = c("se","ci")))
prop_ZonaH
```

```
## # A tibble: 2 × 5
##   Zone   prop prop_se prop_low prop_upp
##   <chr> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Rural 0.491  0.0178    0.455    0.526
## 2 Urban 0.509  0.0178    0.474    0.545
```

En la anterior tabla se puede observar que el 49% de los hombres están en la zona rural y el 51% en la zona urbana. Si se observa el intervalo de confianza se puede concluir que, con una confianza del 95%, la población estimada de hombres que viven en la zona rural puede llegar a ser el 52% y en urbana un 54%.


Si se realiza ahora el mismo ejercicio para la mujeres el código computacional es:


```r
prop_ZonaM <- sub_Mujer %>% group_by(Zone) %>% 
              summarise(prop = survey_prop(vartype = c("se","ci")))
prop_ZonaM
```

```
## # A tibble: 2 × 5
##   Zone   prop prop_se prop_low prop_upp
##   <chr> <dbl>   <dbl>    <dbl>    <dbl>
## 1 Rural 0.470  0.0140    0.443    0.498
## 2 Urban 0.530  0.0140    0.502    0.557
```

De la tabla anterior se puede inferir que, el 47% de las mujeres están en la zona rural y el 52% en la zona urbana. Observando también  intervalos de confianza al 95% de (44%, 49%) y (50%, 55%) para las zonas rural y urbana respectivamente. 

Si se desea estimar por varios niveles de desagregación, con el uso de la función `group_by` es posible estimar un mayor número de niveles de agregación al combinar dos o más variables. Por ejemplo, si se desea estimar la proporción de hombres por zona y en estado de pobreza, se realiza de la siguiente manera:


```r
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



```r
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


```r
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


```r
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


```r
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


```r
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


```r
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



```r
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


```r
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

## Tablas cruzadas. 

Una tabla de contingencia o tablas cruzadas es una herramienta muy utilizada en el análisis de encuestas de hogares puesto que, está conformada por al menos dos filas y dos columnas y representa información de variables categóricos en términos de conteos de frecuencia.  Estas tablas tienen el objetivo de representar de manera resumida, la relación entre diferentes variables categóricas. 

una tabla de contingencia se asume como un arreglo bidimensional de $r=1,\ldots,R$ filas y $c=1,\ldots,C$ columnas. Cabe resaltar que, Las tablas cruzadas o de contingencia no se limitan a dos dimensiones, también se pueden incluir una tercera variable o más, es decir, $l=1,\ldots,L$ subtablas basadas en las categorías de una tercera variable.

Para efectos de ilustración y facilitación de los ejemplos y conceptos teóricos, en esta sección de trabajarán, en su mayoría con tablas $2\times2$. Gráficamente, estas tablas se construyen con frecuencias no estimadas como se muestra a continuación:


| Variable 2        | Variable 1                  | Marginal fila|
|-------------------|-------------|---------------|--------------|
|                   | 0           | 1             |              |
| 0                 | $n_{00}$    |   $n_{01}$    | $n_{0+}$     |
| 1                 |  $n_{10}$   |  $n_{11}$     | $n_{1+}$     |
| Marginal columna  |  $n_{+0}$   |    $n_{+1}$   |  $n_{++}$    |


A continuación, se muestra la tabla de doble entrada con las frecuencias estimadas o ponderadas:



| Variable 2        | Variable 1                  | Marginal fila|
|-------------------|-------------|---------------|--------------|
|                   | 0           | 1             |              |
| 0                 | $\hat{N}_{00}$|   $\hat{N}_{01}$| $\hat{N}_{0+}$|
| 1                 |  $n_{10}$   |  $n_{11}$     | $n_{1+}$     |
| Marginal columna  |  $n_{+0}$   |    $n_{+1}$   |  $n_{++}$    |


donde, por ejemplo, la frecuencia ponderada o estimada en la celda (0, 1) está dada por $\hat{N}_{01}={\displaystyle \sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i\in\left(0,1\right)}^{n_{h\alpha}}}\omega_{h\alpha i}$. Las proporciones estimadas a partir de estas frecuencias muestrales ponderadas, se obtienen de la siguiente manera $p_{rc}=\frac{\hat{N}_{rc}}{\hat{N}_{++}}$.

*Estimación de proporciones para variables binarias*

La estimación de una sola proporción, $\pi$, para una variable de respuesta binaria requiere solo una extensión directa del estimador de razón mostrado en secciones anteriores. Como lo menciona *Heeringa, S. G. (2017)* Al recodificar las categorías de respuesta originales en una sola variable indicadora $y_{i}$ con valores posibles de 1 y 0 (por ejemplo, sí = 1, no = 0), el estimador de la media de la razón estima la proporción o prevalencia, $\pi$, de "1" en la población está dada por:

$$
p =  \frac{{\displaystyle \sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i\in\left(0,1\right)}^{n_{h\alpha}}}\omega_{h\alpha i}I\left(y_{i}=1\right)}{{\displaystyle \sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i\in\left(0,1\right)}^{n_{h\alpha}}}\omega_{h\alpha i}}
 =  \frac{\hat{N}_{1}}{\hat{N}}
$$

Aplicando Linealización de Taylor (TSL) al estimador de razón de $\pi$ genera el siguiente estimador para la varianza:

$$
v\left(p\right) \dot{=} \frac{V\left(\hat{N}_{1}\right)+p^{2}V\left(\hat{N}\right)-2\,p\,cov\left(\hat{N}_{1},\hat{N}\right)}{\hat{N}^{2}}
$$


Como es bien sabido en la literatura especializada, cuando la proporción de interés estimada está cerca de 0 o 1, los límites del intervalo de confianza estándar basados en el diseño de muestreo pueden ser menores que 0 o superiores a 1. Lo cual no tendría interpretación por la naturaleza del parámetro. Es por lo anterior que, para solventar este problema se puede realizar cálculos alternativos de IC basados en el diseño de muestreo para las proporciones como lo proponen *Wilson modificado (Rust y Hsu, 2007; Dean y Pagano, 2015)*. El intervalo de confianza utilizando la transformación $Logit\left(p\right)$
está dado por:

$$
IC\left[logit\left(p\right)\right]  =  \left\{ ln\left(\frac{p}{1-p}\right)\pm\frac{t_{1-\alpha/2,\,gl}se\left(p\right)}{p\left(1-p\right)}\right\} 
$$

Por tanto, el intervalo de confianza para $p$ sería:

$$
IC\left(p\right)  =  \left\{ \frac{exp\left[ln\left(\frac{p}{1-p}\right)\pm\frac{t_{1-\alpha/2,\,gl}se\left(p\right)}{p\left(1-p\right)}\right]}{1+exp\left[ln\left(\frac{p}{1-p}\right)\pm\frac{t_{1-\alpha/2,\,gl}se\left(p\right)}{p\left(1-p\right)}\right]}\right\} 
$$

Ahora bien, si se el interés es estimar proporciones para variables multinomiales. El estimador es el siguiente:


$$
p_{k}  =  \frac{{\displaystyle \sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i=1}^{n_{h\alpha}}}\omega_{h\alpha i}I\left(y_{i}=k\right)}{{\displaystyle \sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_{h}}\sum_{i=1}^{n_{h\alpha}}}\omega_{h\alpha i}}
 =  \frac{\hat{N}_{k}}{\hat{N}}
$$

A continuación, siguiendo con la base de ejemplo, se estima la proporción de hombres y mujeres en pobreza y no pobreza junto con su error estándar e intervalos de confianza.


```r
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


```r
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

```r
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


```r
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


```r
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



```r
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



*Prueba de independencia $\chi^{2}$*

Esta prueba es una de las más utilizadas para determinar si no existe asociación o independencia entre dos variables de tipo cualitativa. En otras palabras, que dos variables sean independientes significa que una no depende de la otra, ni viceversa. 

A modo de ejemplificar la técnica, para una tabla de $2\times2$, la prueba $\chi^{2}$ de personas se define como:

$$
\chi^{2}  =  n_{++}\sum_{r}\sum_{c}\frac{\left(p_{rc}-\hat{\pi}_{rc}\right)^{2}}{\hat{\pi}_{rc}}
$$

donde, $\hat{\pi}_{rc}=\frac{n_{r+}}{n_{++}}\,\frac{n_{+c}}{n_{++}}\,p_{r+}\,p_{+c}$.

Para realizar la prueba de independencia $\chi^{2}$ en `R`, se utilizará la función *svychisq* del paquete *srvyr*. Esta función requiere que se definan las variables de interés (formula) y requiere que se le defina el diseño muestral (desing). Ahora, para ejemplificar el uso de esta función tomaremos la base de datos de ejemplo y se probará si la pobreza es independiente del sexo. A continuación, se presentan los códigos computacionales: 


```r
svychisq(formula = ~Sex + pobreza, design = diseno, statistic="F")
```

```
## 
## 	Pearson's X^2: Rao & Scott adjustment
## 
## data:  NextMethod()
## F = 0.056464, ndf = 1, ddf = 119, p-value = 0.8126
```

Dado que el p-valor es superior al nivel de significancia 5% se puede concluir que, con una confianza del 95% y basado en la muestra, la pobreza no depende del sexo de las personas.

En este mismo sentido, si se desea saber si el desempleo está relacionado con el sexo, se realiza la prueba de hipótesis $\chi^{2}$ como sigue:


```r
svychisq(formula = ~Sex + Employment, 
         design = diseno,  statistic="F")
```

```
## 
## 	Pearson's X^2: Rao & Scott adjustment
## 
## data:  NextMethod()
## F = 62.251, ndf = 1.6865, ddf = 200.6978, p-value < 2.2e-16
```

Concluyendo que, con una confianza del 95% y basado en la muestra se rechaza la hipótesis nula, es decir, no se puede afirmar que las variables sexo y desempleo sean independiente. 

Si en el análisis ahora se quiere verificar que la pobreza de las personas es independiente de las regiones establecidas en la base de datos, se realiza de la siguiente manera:


```r
svychisq(formula = ~Region + pobreza, 
         design = diseno,  statistic="F")
```

```
## 
## 	Pearson's X^2: Rao & Scott adjustment
## 
## data:  NextMethod()
## F = 0.48794, ndf = 3.0082, ddf = 357.9731, p-value = 0.6914
```

Concluyendo que, con una confianza del 95% y basado en la muestra hay independencia entre la pobreza y la región. Lo anterior implica que, no existe relación lineal entre las personas en estado de pobreza por región.

**Razón de odds**

Como lo menciona *Monroy, L. G. D. (2018)* La traducción más aproximada del término odds es “la ventaja”, en términos de probabilidades es la posibilidad de que un evento ocurra con relación a que no ocurra, es decir, es un número que expresa cuánto más probable es que se produzca un evento frente a que no se produzca. También se puede utilizar para cuantificar la asociación entre los niveles de una variable y un factor categórico *(Heeringa, S. G. 2017)*.

Suponga que se desea calcular la siguiente razón de odds. 

$$
 \frac{\frac{P(Sex = Female \mid pobreza = 0 )}{P(Sex = Female \mid pobreza = 1 )}}{
 \frac{P(Sex = Male \mid pobreza = 1 )}{P(Sex = Male \mid pobreza = 0 )}
 }
$$

El procedimiento para realizarlo en `R` sería, primero estimar las proporciones de la tabla cruzada entre las variables sexo y pobreza:


```r
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



```r
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


```r
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

```r
0.3892 - 0.3946			 
```

```
## [1] -0.0054
```


Con la función `vcov` se obtiene la matriz de covarianzas:


```r
library(kableExtra)
vcov(tab_sex_pobreza)%>% data.frame() %>% 
  kable(digits = 10,
        format.args = list(scientific = FALSE))
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> Female </th>
   <th style="text-align:right;"> Male </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Female </td>
   <td style="text-align:right;"> 0.0009982953 </td>
   <td style="text-align:right;"> 0.0009182927 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Male </td>
   <td style="text-align:right;"> 0.0009182927 </td>
   <td style="text-align:right;"> 0.0013415823 </td>
  </tr>
</tbody>
</table>

-   *Paso 2:* El cálculo del error estándar es:   


```r
sqrt(0.0009983 + 0.0013416 - 2*0.0009183)
```

```
## [1] 0.02243435
```


Ahora bien, aplicando la función `svycontrast` se puede obtener la estimación de la diferencia de proporciones anterior: 


```r
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


```r
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

```r
0.02169 - 0.06783 	
```

```
## [1] -0.04614
```

Estimación de la matriz de covarianza: 


```r
vcov(tab_sex_desempleo) %>% data.frame() %>% 
  kable(digits = 10,
        format.args = list(scientific = FALSE))
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> Female </th>
   <th style="text-align:right;"> Male </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Female </td>
   <td style="text-align:right;"> 0.0000311369 </td>
   <td style="text-align:right;"> 0.0000208130 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Male </td>
   <td style="text-align:right;"> 0.0000208130 </td>
   <td style="text-align:right;"> 0.0001478933 </td>
  </tr>
</tbody>
</table>

-   *Paso 2*: Estimación del error estándar. 

```r
sqrt(0.00003114	 + 0.00014789 - 2*0.00002081)
```

```
## [1] 0.0117222
```

Siguiendo el ejemplo anterior, utilizando la función `svycontrast` se tiene que:


```r
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


```r
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


```r
vcov(tab_region_desempleo)%>%
  data.frame() %>% 
  kable(digits = 10,
        format.args = list(scientific = FALSE))
```

Por tanto, la varianza estimada está dada por:


```r
sqrt(0.0002981 + 0.0002884 - 2*0)
```

```
## [1] 0.02421776
```

```r
sqrt(0.0001968 + 0.0002884 - 2*0)
```

```
## [1] 0.02202726
```

```r
sqrt(0.0001267 + 0.0004093 - 2*0)
```

```
## [1] 0.02315167
```


Usando la función `svycontrast`, la estimación de los contrastes sería:


```r
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


```r
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


```r
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





