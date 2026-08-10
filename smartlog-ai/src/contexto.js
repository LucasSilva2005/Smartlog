/**
 * Montagem do contexto operacional enviado à OpenAI.
 *
 * Lógica portada de functions/index.js sem alteração de comportamento.
 * O contexto é SEMPRE construído a partir da identidade validada — nada do
 * que o cliente manda no corpo influencia o que o modelo enxerga.
 */

// Mesmo valor do DashboardController.horasLimiteAtraso, para o assistente
// e o painel AI Insights nunca divergirem sobre o que é "atraso".
export const HORAS_LIMITE_ATRASO = 24;

// Teto de entregas detalhadas no contexto — controla custo de token.
export const MAX_ENTREGAS_CONTEXTO = 40;

/**
 * A base convive com Timestamp (Firestore) e String ISO (cópia do app).
 *
 * @param {*} v Valor bruto do campo de data.
 * @return {?Date} Data convertida, ou null se ausente/ilegível.
 */
function lerData(v) {
  if (!v) return null;
  if (v instanceof Date) return v;
  if (typeof v === "string") {
    const d = new Date(v);
    return isNaN(d.getTime()) ? null : d;
  }
  return null;
}

/**
 * Horas inteiras decorridas desde uma data.
 *
 * @param {?Date} data Data inicial.
 * @param {!Date} agora Instante de referência.
 * @return {?number} Horas, ou null se a data for nula.
 */
function horasDesde(data, agora) {
  if (!data) return null;
  return Math.floor((agora.getTime() - data.getTime()) / 36e5);
}

/**
 * Atrasada = status explícito ou não concluída após o limite.
 *
 * @param {!Object} e Documento da entrega.
 * @param {!Date} agora Instante de referência.
 * @return {boolean} true se está atrasada.
 */
function estaAtrasada(e, agora) {
  const status = (e.status || "Pendente").trim();
  if (status === "Atrasada") return true;
  if (status === "Entregue") return false;
  const h = horasDesde(lerData(e.dataCriacao), agora);
  return h !== null && h >= HORAS_LIMITE_ATRASO;
}

/**
 * Projeção enxuta: sem UIDs nem campos internos como empresaId.
 *
 * @param {!Object} e Documento da entrega.
 * @param {!Date} agora Instante de referência.
 * @return {!Object} Entrega resumida.
 */
function resumir(e, agora) {
  return {
    codigo: e.id || "sem código",
    endereco: e.endereco || "não informado",
    regiao: e.regiao || "não definida",
    status: e.status || "Pendente",
    motorista: e.motorista || "sem motorista",
    cliente: e.cliente || "não informado",
    paradaNaRota: e.ordemEntrega || null,
    horasDesdeCriacao: horasDesde(lerData(e.dataCriacao), agora),
    atrasada: estaAtrasada(e, agora),
    recebidoPor: e.recebedor || null,
  };
}

/**
 * Contexto do Administrador: visão agregada da empresa.
 *
 * @param {!Array<!Object>} entregas Entregas da empresa.
 * @param {number} totalMotoristas Motoristas cadastrados.
 * @param {number} totalClientes Clientes cadastrados.
 * @param {!Date} agora Instante de referência.
 * @return {!Object} Contexto para o modelo.
 */
export function contextoAdministrador(
    entregas,
    totalMotoristas,
    totalClientes,
    agora,
) {
  const porStatus = {};
  const porRegiao = {};
  const cargaAtiva = {};
  let atrasadas = 0;
  let semMotorista = 0;

  for (const e of entregas) {
    const status = (e.status || "Pendente").trim();
    porStatus[status] = (porStatus[status] || 0) + 1;

    const regiao = (e.regiao || "").trim();
    if (regiao) porRegiao[regiao] = (porRegiao[regiao] || 0) + 1;

    const nome = (e.motorista || "").trim();
    const tem = nome && nome !== "Sem motorista";
    if (!tem) {
      semMotorista++;
    } else if (status !== "Entregue") {
      cargaAtiva[nome] = (cargaAtiva[nome] || 0) + 1;
    }

    if (estaAtrasada(e, agora)) atrasadas++;
  }

  const concluidas = porStatus["Entregue"] || 0;
  const ranking = Object.entries(cargaAtiva)
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .map(([motorista, entregasAtivas]) => ({motorista, entregasAtivas}));

  const truncou = entregas.length > MAX_ENTREGAS_CONTEXTO;

  return {
    escopo: "Operação completa da empresa",
    totalEntregas: entregas.length,
    totalMotoristasCadastrados: totalMotoristas,
    totalClientesCadastrados: totalClientes,
    distribuicaoPorStatus: porStatus,
    distribuicaoPorRegiao: porRegiao,
    percentualConcluidas: entregas.length === 0 ?
      0 :
      Math.round((concluidas / entregas.length) * 100),
    entregasAtrasadas: atrasadas,
    criterioDeAtraso: `Não concluída há ${HORAS_LIMITE_ATRASO}h ou mais`,
    entregasSemMotorista: semMotorista,
    cargaAtivaPorMotorista: ranking,
    entregas: entregas
        .slice(0, MAX_ENTREGAS_CONTEXTO)
        .map((e) => resumir(e, agora)),
    observacao: truncou ?
      `Lista truncada nas ${MAX_ENTREGAS_CONTEXTO} primeiras. Os números ` +
        `agregados acima consideram todas as ${entregas.length}.` :
      null,
  };
}

/**
 * Contexto do Motorista: só as entregas atribuídas a ele.
 *
 * @param {!Array<!Object>} entregas Entregas da empresa.
 * @param {string} uid UID autenticado do motorista.
 * @param {!Date} agora Instante de referência.
 * @return {!Object} Contexto para o modelo.
 */
export function contextoMotorista(entregas, uid, agora) {
  const minhas = entregas.filter((e) => (e.motoristaUid || "") === uid);
  const pendentes = minhas
      .filter((e) => (e.status || "Pendente") !== "Entregue")
      .sort((a, b) => (a.ordemEntrega || 0) - (b.ordemEntrega || 0));
  const concluidas = minhas.filter((e) => e.status === "Entregue");

  return {
    escopo: "Somente as entregas atribuídas a este motorista",
    totalAtribuidas: minhas.length,
    entregasRestantes: pendentes.length,
    entregasConcluidas: concluidas.length,
    proximaEntrega: pendentes.length > 0 ? resumir(pendentes[0], agora) : null,
    rotaPendente: pendentes
        .slice(0, MAX_ENTREGAS_CONTEXTO)
        .map((e) => resumir(e, agora)),
    ultimasConcluidas: concluidas.slice(-5).map((e) => resumir(e, agora)),
  };
}

/**
 * Contexto do Cliente: só os pedidos vinculados ao nome cadastrado.
 *
 * @param {!Array<!Object>} entregas Entregas da empresa.
 * @param {string} nomeCliente Nome cadastrado do cliente autenticado.
 * @param {!Date} agora Instante de referência.
 * @return {!Object} Contexto para o modelo.
 */
export function contextoCliente(entregas, nomeCliente, agora) {
  const alvo = (nomeCliente || "").trim().toLowerCase();
  const meus = alvo ?
    entregas.filter((e) => (e.cliente || "").trim().toLowerCase() === alvo) :
    [];

  return {
    escopo: "Somente os pedidos deste cliente",
    nomeCadastrado: nomeCliente || "não informado",
    totalPedidos: meus.length,
    pedidos: meus
        .slice(0, MAX_ENTREGAS_CONTEXTO)
        .map((e) => resumir(e, agora)),
    avisoVinculo: meus.length === 0 ?
      "Nenhum pedido encontrado. As entregas são vinculadas pelo nome " +
        "cadastrado do cliente; divergência de grafia impede o vínculo." :
      null,
  };
}
