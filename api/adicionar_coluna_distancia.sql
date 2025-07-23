-- Adicionar coluna distancia na tabela exercicios se não existir
ALTER TABLE exercicios ADD COLUMN IF NOT EXISTS distancia DECIMAL(10,2) DEFAULT 0.00; 