Código em R para calcular convergência absoluta e condicional dos estados brasileiros, bem como calcular o índice I de Moran e teste LISA para fazer uma análise de aglomeração espacial.

## Requisitos

- R (versão 3.6.0 ou superior)
- R Studio Desktop
- Pacotes do R: "dplyr", "geobr", "ggplot2", "glue", "readr", "rlang", "sf", "tidyr"

## Dados

Dados do PIB per capita foram obtidos do [ipeadata](www.ipeadata.gov.br). Para obtê-los, busque pela palavra "pib" na caixa de pesquisa e acesse a opção `PIB Estadual per capita - preços de mercado (preços de 2010)`. Em seguida, no nível geográfico selecione `Estados`, na abrangência escolha `Brasil` e no período selecione entre 1996 e 2021.

Dados da idade da população dos estados em 1996 foi extraído do SIDRA, na [tabela 475](https://sidra.ibge.gov.br/tabela/475).

Para calcular a taxa de crescimento da população, utilizamos a população residente total entre os anos de 1996 a 2022, obtido do IPEAData, na aba "Regional" -> "Temas" -> "População".

Os anos de estudo foram estimados por meio de uma proxy, que é o percentual de pessoas de 25 ou mais anos de idade que completaram pelo menos um ano de curso universitário. Esse dado também foi extraído no IPEAData. Na barra de pesquisa, pesquisar por "Média de anos de estudo - mais de 11 - pessoas 25 anos e mais".

