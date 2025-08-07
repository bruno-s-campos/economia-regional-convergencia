#install.packages(c("dplyr", "ggplot2", "glue", "geobr", "readr", "rlang", "spdep", "tidyr"))

library(dplyr)
library(ggplot2)
library(glue)
library(geobr)
library(RColorBrewer)
library(readr)
library(rlang)
library(sf)
library(spatialreg)
library(spdep)
library(tidyr)
library(tmap)

source('utils.r')

calcular_convergencia_beta = function(dados, ano_inicial, ano_final) {
    y0 = glue("ppc_{ano_inicial}")
    yt = glue("ppc_{ano_final}")

    df = dados %>%
        select(sigla, estado, !!sym(y0), !!sym(yt)) %>%
        mutate(
            crescimento=(!!sym(yt) - !!sym(y0)) / (ano_final - ano_inicial),
            ln_ppc_inicial=!!sym(y0)
        )

    modelo = lm(crescimento ~ ln_ppc_inicial, data=df)

    grafico = ggplot(df, aes(x=ln_ppc_inicial, y=crescimento, label=sigla)) +
        geom_point(color="steelblue", size=3) +
        geom_smooth(method="lm", se=FALSE, color="darkred") +
        geom_text(vjust=-0.5, size=3.5) +  # ou geom_label() para caixinhas
        labs(
            title=glue("Convergência Beta ({ano_inicial}–{ano_final})"),
            x=glue("Log do PIB per capita em {ano_inicial}"),
            y="Variação do log do PIB per capita"
        ) +
        theme_minimal() +
        theme(panel.grid=element_blank())

    return(list(modelo=modelo, grafico=grafico))
}

calcular_convergencia_sigma = function(dados) {
    dados_long = dados %>%
        pivot_longer(
            cols=starts_with("ppc_"),
            names_to="ano",
            names_prefix="ppc_",
            values_to="ln_ppc"
        ) %>%
        mutate(ano = as.integer(ano))

    df_sigma = dados_long %>%
        group_by(ano) %>%
        summarise(sd_ln_ppc=sd(ln_ppc, na.rm=TRUE))

    modelo = lm(sd_ln_ppc ~ ano, data=df_sigma)

    grafico = ggplot(df_sigma, aes(x=ano, y=sd_ln_ppc)) +
        geom_line(size=1.2, color="darkred") +
        geom_point(size=2) +
        geom_smooth(method="lm", se=FALSE, color="blue", linetype="dashed") +
        labs(
            title="Convergência Sigma",
            x="Ano",
            y="Desvio padrão do log do PIB per capita"
        ) +
        theme_minimal() +
        theme(panel.grid=element_blank())

    return(list(modelo=modelo, grafico=grafico))
}

dados_ppc = read_csv2("input/pib-per-capita-estados-precos-2010.csv")
dados_ppc = converter_para_reais(dados_ppc)
dados_ppc = converter_para_log(dados_ppc)

resultado_beta = calcular_convergencia_beta(dados_ppc, 1996, 2021)
resultado_beta$grafico
summary(resultado_beta$modelo)

resultado_sigma = calcular_convergencia_sigma(dados_ppc)
resultado_sigma$grafico
summary(resultado_sigma$modelo)

dados_ppc$residuos_conv_beta = resid(resultado_beta$modelo)

estados = read_state(year=2020)
mapa_com_residuos = estados %>% left_join(dados_ppc, by=c("code_state"="codigo"))

mapa_com_residuos$residuos_cat = cut(
    mapa_com_residuos$residuos_conv_beta,
    breaks=5,
    include.lowest=TRUE
)

ggplot(mapa_com_residuos) +
    geom_sf(aes(fill=residuos_cat)) +
    scale_fill_brewer(palette="RdBu", name="Resíduos") +
    theme_minimal() +
    theme(
        axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank()
    ) +
    labs(title="Mapa dos resíduos")

viz = poly2nb(mapa_com_residuos, queen=TRUE)
pesos = nb2listw(viz, style="W")
resultado_moran = moran.test(mapa_com_residuos$residuos_conv_beta, pesos)
i_moran = round(resultado_moran$estimate[["Moran I statistic"]], 3)

moran = moran.plot(mapa_com_residuos$residuos_conv_beta, pesos,
    labels=mapa_com_residuos$sigla,
    xlab="Resíduos",
    ylab="Média dos resíduos dos vizinhos",
    main=glue("Diagrama de Dispersão de Moran ({i_moran})"))

lisa = localmoran(mapa_com_residuos$residuos_conv_beta, pesos)
mapa_com_residuos$lisa_I = lisa[, 1]
mapa_com_residuos$lisa_p = lisa[, 5]

media_ppc = mean(mapa_com_residuos$residuos_conv_beta)
media_viz = lag.listw(pesos, mapa_com_residuos$residuos_conv_beta)

mapa_com_residuos$cluster = NA
mapa_com_residuos$cluster[mapa_com_residuos$residuos_conv_beta >= media_ppc & media_viz >= media_ppc & mapa_com_residuos$lisa_p <= 0.1] = "High-High"
mapa_com_residuos$cluster[mapa_com_residuos$residuos_conv_beta <= media_ppc & media_viz <= media_ppc & mapa_com_residuos$lisa_p <= 0.1] = "Low-Low"
mapa_com_residuos$cluster[mapa_com_residuos$residuos_conv_beta >= media_ppc & media_viz <= media_ppc & mapa_com_residuos$lisa_p <= 0.1] = "High-Low"
mapa_com_residuos$cluster[mapa_com_residuos$residuos_conv_beta <= media_ppc & media_viz >= media_ppc & mapa_com_residuos$lisa_p <= 0.1] = "Low-High"
mapa_com_residuos$cluster[is.na(mapa_com_residuos$cluster)] = "Not Significant"

ggplot(mapa_com_residuos) +
    geom_sf(aes(fill = cluster), color = "white") +
    scale_fill_manual(
        values = c(
            "High-High" = "#2166ac",
            "Low-Low" = "#b2182b",
            "High-Low" = "#92c5de",
            "Low-High" = "#f4a582",
            "Not Significant" = "gray80"
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
        title = "LISA: Clusters de PIB per capita dos resíduos",
        subtitle = "Baseado no I de Moran Local (p < 0.1)"
    )

ano_inicial = 1996
ano_final = 2021
tempo = ano_final - ano_inicial
y0 = glue("ppc_{ano_inicial}")
yt = glue("ppc_{ano_final}")

mapa_com_residuos = mapa_com_residuos %>% mutate(
    crescimento=(!!sym(yt) - !!sym(y0)) / tempo,
    ln_ppc_inicial=!!sym(y0)
)

modelo_sar = lagsarlm(crescimento ~ ln_ppc_inicial, data=mapa_com_residuos, listw=pesos)

# Resultado
summary(modelo_sar)
