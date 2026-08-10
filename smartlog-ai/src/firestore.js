/**
 * Cliente mínimo do Firestore via REST, para uso dentro do Worker.
 *
 * O Admin SDK não roda no runtime dos Workers. Em vez de trazer uma chave de
 * service account (mais um segredo para guardar), reaproveitamos o próprio
 * ID Token do usuário — que já foi verificado criptograficamente — como
 * credencial. Consequência: as Security Rules do Firestore continuam valendo
 * e são a última linha de defesa.
 */

const BASE = "https://firestore.googleapis.com/v1";

/**
 * Converte um Value tipado do Firestore REST para um valor JS simples.
 *
 * @param {Object} v Value no formato REST.
 * @return {*} Valor convertido.
 */
function valor(v) {
  if (!v || typeof v !== "object") return null;
  if ("stringValue" in v) return v.stringValue;
  if ("booleanValue" in v) return v.booleanValue;
  if ("integerValue" in v) return Number(v.integerValue);
  if ("doubleValue" in v) return Number(v.doubleValue);
  if ("timestampValue" in v) return v.timestampValue; // ISO 8601
  if ("nullValue" in v) return null;
  if ("mapValue" in v) return documento(v.mapValue.fields || {});
  if ("arrayValue" in v) {
    return (v.arrayValue.values || []).map(valor);
  }
  return null;
}

/**
 * Converte o mapa de fields de um documento REST para objeto JS.
 *
 * @param {Object} fields Campos no formato REST.
 * @return {Object} Documento em formato simples.
 */
function documento(fields) {
  const saida = {};
  for (const [chave, v] of Object.entries(fields || {})) {
    saida[chave] = valor(v);
  }
  return saida;
}

/**
 * Lê um documento único.
 *
 * @param {string} projectId Projeto Firebase.
 * @param {string} idToken Token já verificado do usuário.
 * @param {string} caminho Caminho relativo, ex.: "usuarios/abc123".
 * @return {Promise<?Object>} Documento, ou null se não existir.
 */
export async function lerDocumento(projectId, idToken, caminho) {
  const url =
    `${BASE}/projects/${projectId}/databases/(default)/documents/${caminho}`;

  const r = await fetch(url, {
    headers: {Authorization: `Bearer ${idToken}`},
  });

  if (r.status === 404) return null;
  if (!r.ok) {
    // Loga só o status — nunca o token nem o corpo
    console.error("Firestore lerDocumento falhou:", r.status);
    throw new Error("FIRESTORE");
  }

  const json = await r.json();
  return documento(json.fields || {});
}

/**
 * Executa uma consulta com um único filtro de igualdade em string.
 *
 * @param {string} projectId Projeto Firebase.
 * @param {string} idToken Token já verificado do usuário.
 * @param {string} colecao Coleção alvo.
 * @param {string} campo Campo do filtro.
 * @param {string} igualA Valor esperado.
 * @param {number} limite Teto de documentos retornados.
 * @return {Promise<Array<Object>>} Documentos convertidos.
 */
export async function consultar(
    projectId,
    idToken,
    colecao,
    campo,
    igualA,
    limite = 200,
) {
  const url =
    `${BASE}/projects/${projectId}/databases/(default)/documents:runQuery`;

  const r = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${idToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{collectionId: colecao}],
        where: {
          fieldFilter: {
            field: {fieldPath: campo},
            op: "EQUAL",
            value: {stringValue: igualA},
          },
        },
        limit: limite,
      },
    }),
  });

  if (!r.ok) {
    console.error("Firestore consultar falhou:", r.status);
    throw new Error("FIRESTORE");
  }

  const linhas = await r.json();
  if (!Array.isArray(linhas)) return [];

  return linhas
      .filter((l) => l && l.document && l.document.fields)
      .map((l) => documento(l.document.fields));
}
