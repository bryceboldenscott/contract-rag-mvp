-- Contract RAG MVP — Checkpoint C
-- Generic, fictional-data-only schema. No company-specific field list encoded here.
-- Embedding column/dimension intentionally deferred to Checkpoint H/I (see contract_chunks below).

CREATE EXTENSION IF NOT EXISTS vector;

-- =========================================================
-- contracts
-- Structured fictional contract metadata.
-- =========================================================
CREATE TABLE contracts (
    -- Core identifiers / classifications
    contract_id             TEXT PRIMARY KEY,
    contract_number         TEXT,
    contract_type           TEXT NOT NULL,
    status                  TEXT NOT NULL,
    prime_sub               TEXT NOT NULL,

    -- Fictional customer/agency, partner, and program metadata
    customer_agency          TEXT NOT NULL,
    partner_name             TEXT,
    program_name             TEXT,

    -- Effective / expiration dates
    effective_date           DATE NOT NULL,
    expiration_date          DATE NOT NULL,

    -- Synthetic financial values (kept separate, not collapsed into one field)
    ceiling_value             NUMERIC(14,2),
    obligated_value           NUMERIC(14,2),
    funded_value               NUMERIC(14,2),

    -- Fictional contact fields
    contact_name              TEXT,
    contact_email             TEXT,
    contact_phone             TEXT,

    -- Payment terms
    payment_terms             TEXT,

    -- Generic priority / security fields (free text — no real classification markings)
    priority_level             TEXT,
    security_level             TEXT,

    -- Modification tracking
    modification_id            TEXT,

    -- Base period
    base_period_start          DATE,
    base_period_end            DATE,

    -- Option Periods 1-9
    option_period_1_start      DATE,
    option_period_1_end        DATE,
    option_period_2_start      DATE,
    option_period_2_end        DATE,
    option_period_3_start      DATE,
    option_period_3_end        DATE,
    option_period_4_start      DATE,
    option_period_4_end        DATE,
    option_period_5_start      DATE,
    option_period_5_end        DATE,
    option_period_6_start      DATE,
    option_period_6_end        DATE,
    option_period_7_start      DATE,
    option_period_7_end        DATE,
    option_period_8_start      DATE,
    option_period_8_end        DATE,
    option_period_9_start      DATE,
    option_period_9_end        DATE,

    notes                       TEXT,

    -- Technical timestamps
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_contracts_dates
        CHECK (expiration_date >= effective_date),

    CONSTRAINT chk_contracts_ceiling_nonnegative
        CHECK (ceiling_value IS NULL OR ceiling_value >= 0),
    CONSTRAINT chk_contracts_obligated_nonnegative
        CHECK (obligated_value IS NULL OR obligated_value >= 0),
    CONSTRAINT chk_contracts_funded_nonnegative
        CHECK (funded_value IS NULL OR funded_value >= 0),

    CONSTRAINT chk_contracts_base_period_pair
        CHECK ((base_period_start IS NULL) = (base_period_end IS NULL)),

    CONSTRAINT chk_contracts_option1_pair
        CHECK ((option_period_1_start IS NULL) = (option_period_1_end IS NULL)),
    CONSTRAINT chk_contracts_option2_pair
        CHECK ((option_period_2_start IS NULL) = (option_period_2_end IS NULL)),
    CONSTRAINT chk_contracts_option3_pair
        CHECK ((option_period_3_start IS NULL) = (option_period_3_end IS NULL)),
    CONSTRAINT chk_contracts_option4_pair
        CHECK ((option_period_4_start IS NULL) = (option_period_4_end IS NULL)),
    CONSTRAINT chk_contracts_option5_pair
        CHECK ((option_period_5_start IS NULL) = (option_period_5_end IS NULL)),
    CONSTRAINT chk_contracts_option6_pair
        CHECK ((option_period_6_start IS NULL) = (option_period_6_end IS NULL)),
    CONSTRAINT chk_contracts_option7_pair
        CHECK ((option_period_7_start IS NULL) = (option_period_7_end IS NULL)),
    CONSTRAINT chk_contracts_option8_pair
        CHECK ((option_period_8_start IS NULL) = (option_period_8_end IS NULL)),
    CONSTRAINT chk_contracts_option9_pair
        CHECK ((option_period_9_start IS NULL) = (option_period_9_end IS NULL))
);

-- days_until_expiration is intentionally NOT a stored column — it must be derived
-- at query time, e.g.: SELECT expiration_date - CURRENT_DATE AS days_until_expiration ...

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contracts_set_updated_at
BEFORE UPDATE ON contracts
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- documents
-- Complete synthetic source-document text and source traceability.
-- =========================================================
CREATE TABLE documents (
    document_id       BIGSERIAL PRIMARY KEY,
    contract_id       TEXT NOT NULL REFERENCES contracts(contract_id) ON DELETE CASCADE,
    document_name     TEXT NOT NULL,
    document_type     TEXT,
    source_reference  TEXT,
    document_text     TEXT NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documents_contract_id ON documents(contract_id);

-- =========================================================
-- contract_chunks
-- Smaller searchable passages derived from synthetic documents.
-- =========================================================
CREATE TABLE contract_chunks (
    chunk_id       BIGSERIAL PRIMARY KEY,
    document_id    BIGINT NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
    contract_id    TEXT NOT NULL REFERENCES contracts(contract_id) ON DELETE CASCADE,
    chunk_index    INTEGER NOT NULL,
    chunk_text     TEXT NOT NULL,
    embedding      VECTOR(384),  -- BAAI/bge-small-en-v1.5, approved Checkpoint H3; normalized for cosine similarity
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_contract_chunks_index_nonnegative
        CHECK (chunk_index >= 0),

    CONSTRAINT uq_contract_chunks_document_index
        UNIQUE (document_id, chunk_index)
);

CREATE INDEX idx_contract_chunks_document_id ON contract_chunks(document_id);
CREATE INDEX idx_contract_chunks_contract_id ON contract_chunks(contract_id);
