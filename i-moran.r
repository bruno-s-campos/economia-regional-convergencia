#install.packages(c("dplyr", "geobr", "glue", "readr", "sf", "spdep"))

library(dplyr)
library(geobr)
library(glue)
library(readr)
library(sf)
library(spdep)

source('utils.r')

calcular_i_moran = function(estados, ano) {
    cat(glue('Calculando o índice i-moran para a coluna "ppc_{ano}"...\n'))
    coluna = glue("ppc_{ano}")

    viz = poly2nb(estados, queen=TRUE)
    lw = nb2listw(viz, style="W")
    moran.test(estados[[coluna]], lw)
}

dados_ppc = read_csv2("input/pib-per-capita-estados-precos-2010.csv")
dados_ppc = converter_para_reais(dados_ppc)

estados = read_state(year=2020)
estados = estados %>% left_join(dados_ppc, by=c("code_state"="codigo"))

calcular_i_moran(estados, 2021)
