# Contract RAG MVP

A fully local Retrieval-Augmented Generation pipeline that answers questions about a contract portfolio, with every claim cited back to the evidence it came from, and that declines to answer when the evidence isn't there.

Built as an internship prototype on entirely synthetic data: generated contracts and documents, no real organisations, customers, contracts or credentials.

> **Showcase only.** The prototype's source stays private. This repo describes how it works, with a small mocked sample that runs anywhere. Not accepting contributions.

## Pipeline

```
question
   │
   ├─ contract-ID filter     CTR-#### tokens → structured filter, not search text
   ├─ semantic search        BGE-small embeddings → pgvector cosine top-k
   ├─ evidence package       rows → {evidence: [E1..E5]}
   ├─ controlled prompt      fixed rules: evidence only, cite everything, refuse if unsupported
   └─ local generation       Gemma 3 4B via Ollama
   │
answer with [E#] citations, shown beside the evidence it cites
```

- **Storage:** PostgreSQL + pgvector: `contracts` → `documents` → `contract_chunks` ([sql/schema.sql](sql/schema.sql), built for the synthetic dataset)
- **Embeddings:** `BAAI/bge-small-en-v1.5`, 384-dim
- **Generation:** Gemma 3 4B on Ollama, entirely local. No cloud LLM, no API key, and no network call leaves the machine.
- **Data:** synthetic contracts and documents, generated and validated by script

## Stack

| Layer | Technology |
|---|---|
| Language | Python 3 |
| Database | PostgreSQL + pgvector |
| Embeddings | sentence-transformers (PyTorch) · `BAAI/bge-small-en-v1.5`, 384-dim · NumPy |
| LLM | Gemma 3 4B via Ollama's local HTTP API |
| DB access | psycopg2 |
| Synthetic data | Python `csv` + openpyxl (CSV / XLSX) |

## Try the mocked sample

[`sample/mini_rag.py`](sample/mini_rag.py) follows the same design with stand-ins: a toy vector search in place of BGE + pgvector, a stub in place of the LLM, and six invented documents. Plain Python, no dependencies.

```bash
python sample/mini_rag.py "When does CTR-0002 expire?"
# CTR-0002 runs from 2024-06-01 and expires on 2027-05-31. No extension options are included. [E1]

python sample/mini_rag.py "What is the budget for CTR-0003?"
# The evidence is insufficient to answer this question.

python sample/mini_rag.py --show-prompt "Who is the vendor on CTR-0001?"   # prints the controlled prompt too
```

## Evaluation

Built in checkpoints (A–K), each verified and written up before moving on. The 20-question evaluation keeps retrieval and generation scores deliberately separate:

| | Result |
|---|---|
| Retrieval behaved as expected | 14/20 (70%) |
| Structured filter respected | 5/5 |
| Generation followed controlled-prompt rules | 20/20 |
| Unsupported factual claims observed | 0/20 |
| Correct refusals on unanswerable questions | 2/2 |

Known limitations were measured and written up rather than hidden:

- **ID-string hijacking:** "…for contract CTR-0012" pulled boilerplate that repeats the ID, which is why IDs became a structured filter
- **Template ties:** identical template sentences across contracts embed identically
- **Intermittent citation misattribution** by Gemma 3 4B. A prompt fix was tested, measured, and rejected because it didn't help.
- **Latency:** 13–33 s per answer on a 4 GB-VRAM laptop GPU

## Built with Claude Code

Developed with [Claude Code](https://claude.com/claude-code), one planned and verified checkpoint at a time.

---

Bryce Bolden-Scott · [bryceboldenscott.com](https://bryceboldenscott.com)
