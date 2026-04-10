#!/usr/bin/env python3
import json
import os
import time
from pathlib import Path
from datetime import datetime
from urllib import request, error

BASE = Path(__file__).resolve().parents[1]
OUT = BASE / "agents" / "out"
OUT.mkdir(parents=True, exist_ok=True)

CFG = json.loads((BASE / "agents" / "config" / "models.json").read_text(encoding="utf-8"))
PROMPTS = {
    "editorial_planner": (BASE / "agents" / "prompts" / "editorial_planner.md").read_text(encoding="utf-8"),
    "post_writer": (BASE / "agents" / "prompts" / "post_writer.md").read_text(encoding="utf-8"),
    "youtube_script": (BASE / "agents" / "prompts" / "youtube_script.md").read_text(encoding="utf-8"),
    "fact_checker": (BASE / "agents" / "prompts" / "fact_checker.md").read_text(encoding="utf-8"),
}

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
API_KEY = os.getenv("OPENROUTER_API_KEY", "").strip()


def call_openrouter(model: str, system_prompt: str, user_prompt: str, timeout_sec: int = 60) -> str:
    body = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        "temperature": 0.6,
    }
    data = json.dumps(body).encode("utf-8")
    req = request.Request(
        OPENROUTER_URL,
        data=data,
        method="POST",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://ia-para-todos.local",
            "X-Title": "IA para Todos Agents",
        },
    )
    with request.urlopen(req, timeout=timeout_sec) as resp:
        raw = resp.read().decode("utf-8")
    payload = json.loads(raw)
    content = payload["choices"][0]["message"]["content"].strip()
    if not content:
        raise RuntimeError("empty_response")
    return content


def call_with_fallback(agent_name: str, system_prompt: str, user_prompt: str):
    models = [CFG["primary"], *CFG.get("fallbacks", [])]
    attempts = int(CFG.get("retry", {}).get("attempts", 3))
    backoff = CFG.get("retry", {}).get("backoff_seconds", [1, 2, 5])

    if not API_KEY:
        return {
            "agent": agent_name,
            "model": "simulation",
            "status": "ok",
            "content": f"[SIMULAÇÃO] {agent_name} executado sem OPENROUTER_API_KEY.",
            "attempt_log": [{"model": "simulation", "attempt": 1, "error": None}],
        }

    attempt_log = []
    for model in models:
        for i in range(attempts):
            try:
                content = call_openrouter(model, system_prompt, user_prompt)
                attempt_log.append({"model": model, "attempt": i + 1, "error": None})
                return {
                    "agent": agent_name,
                    "model": model,
                    "status": "ok",
                    "content": content,
                    "attempt_log": attempt_log,
                }
            except (error.HTTPError, error.URLError, TimeoutError, RuntimeError, KeyError, json.JSONDecodeError) as e:
                msg = str(e)
                attempt_log.append({"model": model, "attempt": i + 1, "error": msg})
                if i < attempts - 1:
                    time.sleep(backoff[min(i, len(backoff) - 1)])
                else:
                    # troca de modelo ao esgotar tentativas
                    pass
    return {
        "agent": agent_name,
        "model": None,
        "status": "failed",
        "content": "Falha em todos os modelos configurados.",
        "attempt_log": attempt_log,
    }


def main():
    topic = "IA no trabalho público sem complicação"
    audience = "público não técnico, servidores e iniciantes"
    now = datetime.now()

    conversation = []

    planner_user = f"Tema: {topic}\nPúblico: {audience}\nObjetivo: gerar pauta acionável para esta semana."
    planner = call_with_fallback("editorial_planner", PROMPTS["editorial_planner"], planner_user)
    conversation.append({"from": "editorial_planner", "to": "post_writer", "message": planner["content"][:500]})

    writer_user = (
        "Use a pauta abaixo para escrever o artigo principal.\n\n"
        f"PAUTA:\n{planner['content']}"
    )
    writer = call_with_fallback("post_writer", PROMPTS["post_writer"], writer_user)
    conversation.append({"from": "post_writer", "to": "youtube_script", "message": writer["content"][:500]})

    yt_user = (
        "Converta o artigo abaixo em roteiro de vídeo curto.\n\n"
        f"ARTIGO:\n{writer['content']}"
    )
    youtube = call_with_fallback("youtube_script", PROMPTS["youtube_script"], yt_user)
    conversation.append({"from": "youtube_script", "to": "fact_checker", "message": youtube["content"][:500]})

    checker_user = (
        "Revise os dois materiais abaixo e devolva correções finais.\n\n"
        f"ARTIGO:\n{writer['content']}\n\nROTEIRO:\n{youtube['content']}"
    )
    checker = call_with_fallback("fact_checker", PROMPTS["fact_checker"], checker_user)

    result = {
        "timestamp": now.isoformat(),
        "topic": topic,
        "model_policy": CFG,
        "agents": {
            "editorial_planner": planner,
            "post_writer": writer,
            "youtube_script": youtube,
            "fact_checker": checker,
        },
        "conversation": conversation,
    }

    stamp = now.strftime("%Y%m%d_%H%M%S")
    human_time = now.strftime("%d/%m/%Y %H:%M")
    out_json = OUT / f"run_{stamp}.json"
    out_md = OUT / f"run_{stamp}.md"

    out_json.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    out_md.write_text(
        "\n\n".join([
            "# Execução de agentes",
            "## Resumo",
            f"- Tema: {topic}",
            f"- Data e hora: {human_time}",
            f"- ID da execução: {stamp}",
            "## Artigo para blog",
            writer["content"],
            "## Roteiro para YouTube",
            youtube["content"],
            "## Revisão final",
            checker["content"],
        ]),
        encoding="utf-8",
    )

    print(str(out_json))
    print(str(out_md))


if __name__ == "__main__":
    main()
