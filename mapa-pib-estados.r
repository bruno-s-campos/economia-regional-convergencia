#install.packages(c("dplyr", "geobr", "ggplot2", "glue", "readr", "sf"))

library(dplyr)
library(geobr)
library(ggplot2)
library(glue)
library(readr)
library(sf)

source('utils.r')

plotar_mapa_estados = function(estados, ano) {
    coluna = sym(glue("ppc_{ano}"))

    ggplot(estados) +
        geom_sf(aes(fill=!!coluna)) +
        scale_fill_gradient(
            name = glue("PIB per capita ({ano})"),
            low = "#cce5ff",
            high = "#003366") +
        theme_minimal() +
        theme(
            axis.title = element_blank(),
            axis.text = element_blank(),
            axis.ticks = element_blank()
        ) +
        labs(title = glue("PIB per capita dos Estados Brasileiros em {ano} (R$ a preços de 2010)"))
}

dados_ppc = read_csv2("input/pib-per-capita-estados-precos-2010.csv")
dados_ppc = converter_para_reais(dados_ppc)

estados = read_state(year=2020)

estados = estados %>% left_join(dados_ppc, by=c("code_state"="codigo"))

plotar_mapa_estados(estados, 1996)
