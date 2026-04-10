# Agentes (IA para Todos)

Aqui ficam “agentes” no sentido prático: **prompts padronizados + um runner** para automatizar tarefas recorrentes do projeto.

## O que existe aqui
- `prompts/`: prompts por função
- `config/`: lista de modelos e regras de fallback (para quando um modelo cair)

## Agentes previstos (MVP)
1) `editorial_planner`: gera pauta semanal e calendário
2) `post_writer`: rascunho de post com estrutura do blog
3) `youtube_script`: roteiro curto com CTA e capítulos
4) `fact_checker`: checklist de validação + “o que checar fora da IA”

## Próximo passo
Conectar isso a um runner (Python) que:
- tenta o modelo A
- se der timeout/5xx/rate-limit, troca para o modelo B
- salva saída em `docs/out/`
