/**
 * Verificação de Firebase ID Token compatível com Cloudflare Workers.
 *
 * O Firebase Admin SDK depende de APIs do Node que não existem no runtime
 * dos Workers, então a validação é feita com WebCrypto, que é padrão aqui.
 *
 * A assinatura é verificada CRIPTOGRAFICAMENTE contra as chaves públicas
 * oficiais do Secure Token Service. Decodificar o payload nunca é suficiente:
 * qualquer pessoa consegue forjar um payload, mas não a assinatura.
 */

const JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/" +
  "securetoken@system.gserviceaccount.com";

// Tolerância para diferença de relógio entre o emissor e a edge (segundos)
const FOLGA_RELOGIO = 60;

/**
 * Cache das chaves públicas no escopo do módulo. O isolate do Worker é
 * reaproveitado entre requisições, então isso evita ir à rede a cada chamada.
 * @type {{chaves: Map<string, CryptoKey>, expiraEm: number}}
 */
let cacheJwks = {chaves: new Map(), expiraEm: 0};

/** Erro de autenticação com motivo curto, seguro para log. */
export class ErroAuth extends Error {
  /**
   * @param {string} motivo Código curto do motivo (não vai para o cliente).
   */
  constructor(motivo) {
    super(motivo);
    this.name = "ErroAuth";
    this.motivo = motivo;
  }
}

/**
 * Decodifica base64url para bytes.
 *
 * @param {string} texto Trecho em base64url.
 * @return {Uint8Array} Bytes decodificados.
 */
function base64UrlParaBytes(texto) {
  const b64 = texto.replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4 === 0 ? "" : "=".repeat(4 - (b64.length % 4));
  const bin = atob(b64 + pad);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

/**
 * Decodifica base64url para objeto JSON.
 *
 * @param {string} texto Trecho em base64url.
 * @return {Object} Objeto decodificado.
 */
function base64UrlParaJson(texto) {
  return JSON.parse(new TextDecoder().decode(base64UrlParaBytes(texto)));
}

/**
 * Carrega as chaves públicas do Firebase, com cache respeitando o max-age
 * devolvido pelo Google.
 *
 * @param {boolean} forcar Ignora o cache (usado quando o kid não é achado).
 * @return {Promise<Map<string, CryptoKey>>} Chaves indexadas por kid.
 */
async function obterChaves(forcar = false) {
  const agora = Date.now();
  if (!forcar && cacheJwks.expiraEm > agora && cacheJwks.chaves.size > 0) {
    return cacheJwks.chaves;
  }

  const r = await fetch(JWKS_URL);
  if (!r.ok) throw new ErroAuth("jwks-indisponivel");

  const {keys} = await r.json();
  if (!Array.isArray(keys)) throw new ErroAuth("jwks-invalido");

  const chaves = new Map();
  for (const jwk of keys) {
    if (!jwk.kid || jwk.kty !== "RSA") continue;
    const chave = await crypto.subtle.importKey(
        "jwk",
        {kty: jwk.kty, n: jwk.n, e: jwk.e, alg: "RS256", ext: true},
        {name: "RSASSA-PKCS1-v1_5", hash: "SHA-256"},
        false,
        ["verify"],
    );
    chaves.set(jwk.kid, chave);
  }

  // Respeita o max-age do Google; cai para 1h se o header não vier
  const cc = r.headers.get("cache-control") || "";
  const m = cc.match(/max-age=(\d+)/);
  const ttl = m ? parseInt(m[1], 10) : 3600;
  cacheJwks = {chaves, expiraEm: agora + ttl * 1000};

  return chaves;
}

/**
 * Verifica um Firebase ID Token e devolve as claims já validadas.
 *
 * Valida: alg RS256, assinatura, iss, aud, exp, iat e sub.
 *
 * @param {string} token JWT recebido no header Authorization.
 * @param {string} projectId Projeto Firebase esperado.
 * @return {Promise<Object>} Payload verificado (sub, email, etc.).
 * @throws {ErroAuth} Se qualquer verificação falhar.
 */
export async function verificarIdToken(token, projectId) {
  if (!token || typeof token !== "string") throw new ErroAuth("token-ausente");

  const partes = token.split(".");
  if (partes.length !== 3) throw new ErroAuth("formato-invalido");

  const [cabecalhoB64, payloadB64, assinaturaB64] = partes;

  let cabecalho;
  let payload;
  try {
    cabecalho = base64UrlParaJson(cabecalhoB64);
    payload = base64UrlParaJson(payloadB64);
  } catch (_) {
    throw new ErroAuth("nao-decodificavel");
  }

  // O algoritmo precisa ser checado ANTES: aceitar "none" ou HMAC aqui
  // permitiria forjar tokens sem nenhuma chave privada.
  if (cabecalho.alg !== "RS256") throw new ErroAuth("alg-invalido");
  if (!cabecalho.kid) throw new ErroAuth("kid-ausente");

  // ── Assinatura ────────────────────────────────────────────────
  let chaves = await obterChaves();
  let chave = chaves.get(cabecalho.kid);
  if (!chave) {
    // Rotação de chaves: revalida o JWKS uma vez antes de rejeitar
    chaves = await obterChaves(true);
    chave = chaves.get(cabecalho.kid);
  }
  if (!chave) throw new ErroAuth("kid-desconhecido");

  const dados = new TextEncoder().encode(`${cabecalhoB64}.${payloadB64}`);
  const assinatura = base64UrlParaBytes(assinaturaB64);

  const valida = await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      chave,
      assinatura,
      dados,
  );
  if (!valida) throw new ErroAuth("assinatura-invalida");

  // ── Claims ────────────────────────────────────────────────────
  const agora = Math.floor(Date.now() / 1000);

  if (payload.aud !== projectId) throw new ErroAuth("aud-invalido");
  if (payload.iss !== `https://securetoken.google.com/${projectId}`) {
    throw new ErroAuth("iss-invalido");
  }
  if (typeof payload.exp !== "number" || payload.exp + FOLGA_RELOGIO < agora) {
    throw new ErroAuth("expirado");
  }
  if (typeof payload.iat !== "number" || payload.iat - FOLGA_RELOGIO > agora) {
    throw new ErroAuth("iat-futuro");
  }
  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new ErroAuth("sub-ausente");
  }

  return payload;
}

/**
 * Extrai o token do header Authorization.
 *
 * @param {Request} request Requisição recebida.
 * @return {?string} Token, ou null se o header não for um Bearer válido.
 */
export function extrairBearer(request) {
  const header = request.headers.get("Authorization") ||
    request.headers.get("authorization");
  if (!header) return null;
  const m = header.match(/^Bearer\s+(.+)$/i);
  if (!m) return null;
  const token = m[1].trim();
  return token.length > 0 ? token : null;
}
