#install.packages("Rcpp")
#install.packages("terra")
#install.packages(c("dplyr", "geobr", "ggplot2", "glue", "RColorBrewer", "readr", "sf", "spdep", "tmap"))

library(dplyr)
library(geobr)
library(ggplot2)
library(glue)
library(RColorBrewer)
library(readr)
library(sf)
library(spdep)
library(tmap)

source('utils.r')

calcular_lisa = function(estados, ano) {
    cat(glue('Calculando o LISA para a coluna "ppc_{ano}"...\n'))
    coluna = glue("ppc_{ano}")

    viz = poly2nb(estados, queen=TRUE)
    lw = nb2listw(viz, style="W")

    lisa = localmoran(estados[[coluna]], lw)

    estados$lisa_I = lisa[, 1]
    estados$lisa_p = lisa[, 5]

    media_ppc = mean(estados[[coluna]])
    media_viz = lag.listw(lw, estados[[coluna]])

    estados$cluster = NA
    estados$cluster[estados[[coluna]] >= media_ppc & media_viz >= media_ppc & estados$lisa_p <= 0.1] = "Alto-Alto"
    estados$cluster[estados[[coluna]] <= media_ppc & media_viz <= media_ppc & estados$lisa_p <= 0.1] = "Baixo-Baixo"
    estados$cluster[estados[[coluna]] >= media_ppc & media_viz <= media_ppc & estados$lisa_p <= 0.1] = "Alto-Baixo"
    estados$cluster[estados[[coluna]] <= media_ppc & media_viz >= media_ppc & estados$lisa_p <= 0.1] = "Baixo-Alto"
    estados$cluster[is.na(estados$cluster)] = "Não significativo"

    return(estados)
}

plotar_lisa = function(estados) {
    ggplot(estados) +
        geom_sf(aes(fill = cluster), color = "white") +
        scale_fill_manual(
            values = c(
                "Alto-Alto" = "#2166ac",
                "Baixo-Baixo" = "#b2182b",
                "Alto-Baixo" = "#92c5de",
                "Baixo-Alto" = "#f4a582",
                "Não significativo" = "gray80"
            ),
            name = "Cluster LISA"
        ) +
        theme_minimal() +
        theme(
            axis.title = element_blank(),
            axis.text = element_blank(),
            axis.ticks = element_blank()
        ) +
        labs(
            title = "LISA: Clusters de PIB per capita dos Estados (2021)",
            subtitle = "Baseado no I de Moran Local (p < 0.1)",
            caption = "Fonte: Dados simulados/exemplo"
        )
}

dados_ppc = read_csv2("input/pib-per-capita-estados-precos-2010.csv")
dados_ppc = converter_para_reais(dados_ppc)

estados = read_state(year=2020)
estados = estados %>% left_join(dados_ppc, by=c("code_state"="codigo"))

lisa_estados = calcular_lisa(estados, 2021)
plotar_lisa(lisa_estados)
