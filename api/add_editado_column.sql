-- Script para adicionar coluna 'editado' na tabela exercicios
-- Execute este script no banco de dados se a coluna ainda não existir

ALTER TABLE exercicios ADD COLUMN editado TINYINT(1) DEFAULT 1 COMMENT 'Indica se o exercício foi editado pelo usuário (0=não editado, 1=editado)';

-- Atualizar exercícios existentes para serem considerados como editados
UPDATE exercicios SET editado = 1 WHERE editado IS NULL; 