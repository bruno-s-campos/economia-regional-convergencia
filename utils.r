converter_para_reais = function(dados) {
    colunas_pib = paste0("ppc_", 1996:2021)
    dados[colunas_pib] = dados[colunas_pib] * 1000

    return(dados)
}
