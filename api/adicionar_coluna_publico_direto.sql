-- =====================================================
-- SCRIPT PARA ADICIONAR COLUNA 'publico' NA TABELA 'treinos'
-- =====================================================

-- 1. Adicionar a coluna 'publico' na tabela treinos
ALTER TABLE treinos ADD COLUMN publico ENUM('0', '1') DEFAULT '0' AFTER nome_treino;

-- 2. Criar índice para otimizar consultas por treinos públicos
CREATE INDEX idx_treinos_publico ON treinos(publico);

-- 3. Atualizar treinos existentes para serem privados por padrão
UPDATE treinos SET publico = '0' WHERE publico IS NULL;

-- 4. Verificar se a coluna foi adicionada corretamente
DESCRIBE treinos;

-- 5. Verificar os dados atualizados
SELECT id, usuario_id, nome_treino, publico, ordem FROM treinos LIMIT 10;

-- =====================================================
-- EXPLICAÇÃO:
-- =====================================================
-- publico = '0' -> Treino privado (padrão para treinos do usuário)
-- publico = '1' -> Treino público (treino pronto disponível para todos)
-- ===================================================== 