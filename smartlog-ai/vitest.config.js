import {defineConfig} from "vitest/config";

// Os testes de test/index.spec.js são de função pura (normalização do
// schema e seleção de contexto) e não tocam em API de Worker, então rodam
// no Node mesmo. O pool do workerd rejeita nome de teste com acento no
// header MF-Vitest-Source e inunda a saída de avisos.
//
// Para testes que precisem do runtime real (fetch handler, bindings):
//   npx vitest --config vitest.workers.config.js
export default defineConfig({
  test: {
    include: ["test/**/*.spec.js"],
  },
});
