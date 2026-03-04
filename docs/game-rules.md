## Objetivo
- Coletar mais BTCs ao longo de 4 turnos ou fim do tempo máximo de partida
- Os jogadores ganham BTCs construindo mineradoras e recebem dividendos.
- Caso um jogador obtenha 20 BTCs antes de 4 turnos, o jogo se encerra.

## Gerais
- Jogo para 2 a 6 jogadores
- Tabuleiro hexagonal com 3 tamanhos (pequeno, médio e grande)
- As bordas do hexágono são peças especiais, enquanto que as arestas são propriedades
- O movimento dos jogadores é dado pela soma de dois dados d6
- Há dois decks de eventos (Bear and Bull) sobre a mesa
- Tempo ideal de partida: 30 minutos

## Tabuleiro
- A partir do tile inicial, formam-se as linhas de cada cidade, sempre intercaladas com um tile de incidente. Sendo `n` a quantidade de tiles iguais, temos:
  - Caracas x n,
  - Bear,
  - Asuncion x n,
  - Bear,
  - Ciudad del Este x n,
  - Inspection,
  - Minsk x n,
  - Bear,
  - Irkutsk x n,
  - Bear,
  - Rockdale x n.
- O valor de `n` é definido por:
  - Tabuleiro pequeno (24 peças) = 3
  - Tabuleiro médio (30 peças) = 4
  - Tabuleiro grande (36 peças) = 5

## Lobby
O criador da sala envia os convites e espera os jogadores entrarem. Quem estiver no lobby precisa apertar o botão de ready para informar que pode ser iniciada a partida, porém o criador da sala é quem tem o botão de começar.

## Início da partida
Todos os jogadores começam no tile inicial, com 20 EVAs, 0 BTCs e sem nenhuma propriedade.
A ordem do turno é sorteada e o primeiro jogador inicia sua jogada.

## Ponto inicial (tile de partida)
Ao passar por esse ponto e completar uma volta no tabuleiro, o jogador não recebe nenhum tipo de bônus.
Caso seja necessário injetar dinheiro na economia do jogo, podemos adicionar a mecânica de bonificação com EVAs.

## Ações possíveis
### Propriedade
- Adquirir usando EVAs
- Adicionar mineradoras à sua propriedade
- Hipotecar
### Gerais
- Checar inventário
- Observar o mapa
- Converter EVA <> BTC
### Incidentes
- Retirar uma carta Bear ou Bull
- Ir para a cadeia
- Sair da cadeia (pagando ou rolando dois dados iguais)

## Turno
- No fluxo headless/text-client v0, antes da rolagem o jogador pode comprar e instalar lotes de mineradoras em propriedades próprias elegíveis.
- Após essa etapa opcional, a rolagem de dados é obrigatória.
- Ao cair numa propriedade vazia, o jogador pode adquiri-la ou ignorá-la
- Caso seja uma propriedade de outro jogador, é obrigatório o pagamento da taxa de energia
- Caso seja uma propriedade sua, nenhuma ação é executada
- Demais ações descritas abaixo podem ser executadas antes do fim do turno

## Valores
Os valores do jogo são proporcionais ao ticket da sala. Como referência, uma sala com o ticket de 20 EVA terá os valores a seguir.
Caso 1 EVA seja um valor muito elevado (US$ 29,00 / R$ 153,00 em 03/2026), podemos trabalhar com mili EVA
### Propriedades
- Caracas = 3 EVA
- Asuncion = 4 EVA
- Ciudad del Este = 5 EVA
- Minsk = 6 EVA
- Irkutsk = 7 EVA
- Rockdale = 8 EVA
### Mineradoras
- Adquirir 1 lote de mineradoras = 8 EVA
- No v0 headless, compra/instalação ocorre no turno do próprio jogador, antes da rolagem.
- No v0 headless, cada propriedade aceita até 4 lotes de mineradoras.
- Pagar conta de luz (energy toll) = 10% do valor da propriedade + 2,5% por lote de mineradoras
- Receber dividendos de mineração: 2 BTCs * número de mineradoras
### EVA <> BTC
- Cotação base:     20 EVA = 1 BTC
- 1 ponto acima:     22 EVA = 1 BTC
- 2 pontos acima:   24 EVA = 1 BTC
- 1 ponto abaixo:    18 EVA = 1 BTC
- 2 pontos abaixo:  16 EVA = 1 BTC

## Comprando uma propriedade
Caso esteja vazia, a propriedade pode ser adquirida pelo seu preço em EVAs.
- Se o jogador tiver o dinheiro disponível, pode efetuar a compra
- Se não tiver, ele tem a opção de vender BTCs na cotação atual e fazer a aquisição
- Caso não tenha interesse, pode apenas ignorar a ação

## Caindo numa propriedade adquirida
Ao cair numa propriedade que foi comprada, o jogador deve pagar uma taxa de energia elétrica em EVAs. Essa taxa segue uma tabela progressiva de mineradoras instaladas:
- Valor base: X EVAs (varia de acordo com a propriedade)
- 1 a 4 mineradoras: valor_base + valor_por_mineradora * número_de_mineradoras
O proprietário recebe esse valor, acrescido de uma taxa de mineração pago pelo banco / rede BTC:
- Taxa Base: 2 BTCs
- 1 a 4 mineradoras: taxa_base + valor_por_mineradora * número_de_mineradoras
Caso o jogador não tenha dinheiro para pagar a taxa de energia, ele é movido para a prisão e o proprietário não recebe o valor da taxa.

## Compra e venda de BTC
Em qualquer momento o jogador pode converter seus recursos EVA <> BTC. O valor da operação é dado pela cotação do BTC no momento da operação
A régua da cotação pode se mover em algumas condições:
- Carta de sorte / revés
- Algum tile específico de alteração do mercado
- Alteração a cada rodada completa
Podem ser escolhidas uma ou mais condições de alteração da cotação, acrescidas de uma rolagem de dado para ver quanto sobe ou desce o valor do BTC.

## Hipoteca
A qualquer momento é possível selecionar uma carta de seu inventário e clicar na opção de hipoteca. O valor recebido é 80% do valor da carta e a reversão da hipoteca é 120%. Caso seja fora de seu turno, essa ação é concretizada no fim do turno.
Cartas hipotecadas não geram valor para o proprietário até que sejam reintegradas ao seu patrimônio.

## Cadeia / Inspeção
Ao ser preso, o peão é movido para lá até que o jogador consiga sair. Isso pode acontecer caso:
- o jogador caia numa propriedade que o prenda;
- tire uma carta de sorte / revés (Inspeção Legal Rigorosa)
- não tenha dinheiro para pagar a taxa de luz de uma propriedade

Para sair da cadeia, ele pode:
- Pagar 5 EVA e sair no próximo turno
- Rodar dois dados e tirar números iguais. Após 3 turnos ele é obrigado a pagar e sair

### Escopo v0 (implementado no headless)
- Ao entrar em inspeção, o jogador fica bloqueado para `roll` normal até resolver a inspeção.
- Resoluções disponíveis no turno do jogador:
- usar saída livre de inspeção (se tiver),
- tentar sair com dados iguais,
- pagar a taxa de inspeção.
- Se a tentativa de dados não resultar em números iguais, o turno termina e o jogador permanece em inspeção.
- A regra de "3 tentativas e pagamento obrigatório" permanece pendente para implementação completa.

Durante esse período:
- Dividendos das mineradoras não são coletados
- Taxa de energia paga por outros jogadores são recebidos normalmente

*Importante*: o jogador não poderá ganhar o jogo estando preso.

## Cartas bear / bull
São dois decks separados em cima da mesa. Uma carta é retirada do deck respectivo ao cair num tile bear / bull.
Cada tile tem duas faces e deverá ser virado após retirar uma carta do deck, afetando o próximo a cair no tile.

Para manter o escopo executável no v0, usaremos um conjunto reduzido de cartas com efeitos imediatos.
O catálogo de cartas e evolução pós-v0 fica em `docs/incident-cards.md`.

### Bear (v0)
Cartas bear afetam o próprio jogador:
- `bear_fine_eva_2`: pague 2 EVA.
- `bear_lost_btc_0_5`: perca 0.5 BTC.
- `bear_legal_inspection`: vá para inspeção.

### Bull (v0)
Cartas bull afetam apenas o próprio jogador:
- `bull_gain_eva_2`: receba 2 EVA.
- `bull_gain_btc_0_2`: receba 0.2 BTC.
- `bull_free_inspection_exit`: ganhe 1 saída livre da inspeção.

### Fora do v0
- Efeitos de pular turno.
- Efeitos com duração por ciclo.
- Alterações da régua de cotação por carta.
- Efeitos que exigem escolhas complexas (ex.: escolher propriedade/mineradora alvo).

## Condições de fim do jogo
O criador da sala pode configurar as condições de vitória, porém com valores pré-estabelecidos:
- Número de rodadas = 4
- Valor acumulado de BTC = 20

## Derrota
O jogador que não tiver mais EVAs para pagar as taxas de outras propriedades é preso e permanece lá até conseguir sair. Ainda é possível se recuperar através dos dividendos de suas propriedades, mas é remota a sua chance de vitória.
O jogador permanecerá no jogo até o fim da partida.

## Premiação
Os valores precisam ser definidos de acordo com a quantidade de pessoas na sala e a remuneração da exchange. Como um exemplo:
- 1o colocado: 70% do valor do pote
- 2o colocado: 20% do valor do pote
- 3o colocado: 10% do valor do pote

## Problemas de conexão
### Jogador ausente
Se o jogador não fizer nenhuma ação durante seu turno, ele será preso por "atividade suspeita" e obrigatoriamente terá que pagar a fiança para sair (quando retornar). Suas propriedades continuam rendendo frutos caso sejam visitadas pelos outros jogadores.
Caso o jogador já tenha iniciado seu turno e fique idle, o jogo termina suas ações ao acabar o tempo:
- Se ele tiver caído numa propriedade já adquirida, o pagamento é feito automaticamente
- Se for uma propriedade vazia, a compra é negada
- Se for uma carta de bear / bull, a carta é sorteada e sua ação é executada

### Desconexão
Caso um jogador se desconecte durante a partida, o servidor irá tentar reconectá-lo automaticamente. Durante esse processo, uma tela deve informar a perda de conexão e o processo em andamento. Também deve ser possível abandonar a partida.
- Se for seu turno, ficam decididas as regras descritas na seção `Idle` acima.
- Se for fora de seu turno, o jogador fica no aguardo da reconexão sem nenhum prejuízo, recebendo normalmente os valores devidos durante a partida.

## Postergados / Retirados
- Inflação dos preços EVA
- Trade com outros jogadores
- Bonificação do jogador ao passar pelo ponto inicial
- Leilão das cartas não adquiridas (auction)
- Ações entre turno (jogadores precisam esperar sua vez para realizar qualquer ação)

## Ideias
### Chat
- Reações com emotes
- Mensagens prontas

### Evento para aumentar o ticket inical
- Para injetar mais dinheiro na economia do jogo, um evento poderia acontecer pedindo um depósito de um valor X em EVAs.
- Todos os jogadores precisariam concordar
- A premiação final seria maior
