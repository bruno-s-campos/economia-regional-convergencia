#install.packages(c("dplyr", "ggplot2", "glue", "readr", "rlang", "tidyr"))

library(dplyr)
library(ggplot2)
library(glue)
library(readr)
library(rlang)
library(tidyr)

source('utils.r')

idade_media_populacao_estados = function() {
    idade_estados = read_csv2("input/idade-populacao-estados.csv")
    # Definir os pontos médios para cada faixa etária
    pontos_medios = c(
        idade_0_4 = 2,
        idade_5_9 = 7,
        idade_10_14 = 12,
        idade_15_19 = 17,
        idade_20_24 = 22,
        idade_25_29 = 27,
        idade_30_34 = 32,
        idade_35_39 = 37,
        idade_40_44 = 42,
        idade_45_49 = 47,
        idade_50_54 = 52,
        idade_55_59 = 57,
        idade_60_64 = 62,
        idade_65_69 = 67,
        idade_70mais = 75
    )

    idade_media_estados = idade_estados %>%
        rowwise() %>%
        mutate(
            soma_ponderada = sum(c_across(names(pontos_medios)) * pontos_medios[names(pontos_medios)], na.rm = TRUE),
            soma_populacao = sum(c_across(names(pontos_medios)), na.rm = TRUE),
            idade_media = soma_ponderada / soma_populacao,
            idade_media2 = (soma_ponderada / soma_populacao)^2
        ) %>%
        ungroup() %>%
        select(sigla, estado, idade_media, idade_media2)

    return(idade_media_estados)
}

taxa_crescimento_populacao_estados = function() {
    pop_estados = read_csv2("input/populacao-estados.csv")
    anos = 2022 - 1996
    pop_estados = pop_estados %>%
        mutate(
            cresc_pop = (log(pop_2022) - log(pop_1996)) / anos
        )

    return(pop_estados)
}

anos_estudo_estados = function(dados, ano_inicial, ano_final) {
    anos_estudo_estados = read_csv2("input/anos-de-estudo-populacao-estados.csv") %>%
        select(sigla, educ_1991=ano_estudo_1991)

    return(anos_estudo_estados)
}

calcular_convergencia_condicional = function(dados) {
    tempo = 2021 - 1996
    dados = dados %>% mutate(
        crescimento=(ppc_2021 - ppc_1996) / tempo,
        ln_ppc_inicial=ppc_1996
    )

    formula_modelo = as.formula("crescimento ~ idade_media + idade_media2 + cresc_pop + educ_1991 + ln_ppc_inicial")
    modelo = lm(formula_modelo, data=dados)

    return(modelo)
}

dados_ppc = read_csv2("input/pib-per-capita-estados-precos-2010.csv")
dados_ppc = converter_para_reais(dados_ppc)
dados_ppc = converter_para_log(dados_ppc)

# Vamos utilizar a idade média da população como proxy da taxa de poupança
idade_media_populacao_1996 = idade_media_populacao_estados()
# Taxa de crescimento da população
tx_crescimento_populacao_1996 = taxa_crescimento_populacao_estados()
# Percentual de pessoas com ensino superior como proxy para capital humano
anos_estudo_estados_1991 = anos_estudo_estados()

dados = dados_ppc %>%
    left_join(idade_media_populacao_1996, by="sigla") %>%
    left_join(tx_crescimento_populacao_1996, by="sigla") %>%
    left_join(anos_estudo_estados_1991, by="sigla")

resultado = calcular_convergencia_condicional(dados)
summary(resultado)
