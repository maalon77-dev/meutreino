-- Adicionar coluna 'publico' na tabela treinos
ALTER TABLE treinos ADD COLUMN publico ENUM('0', '1') DEFAULT '0' AFTER nome_treino;

-- Adicionar índice para melhorar performance das consultas
CREATE INDEX idx_treinos_publico ON treinos(publico);

-- Comentário sobre a coluna
-- 0 = treino privado (padrão)
-- 1 = treino público (pronto) 