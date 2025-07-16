-- Criar tabela para histórico de treinos
CREATE TABLE IF NOT EXISTS historico_treinos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    nome_treino VARCHAR(255) NOT NULL,
    tempo_total INT NOT NULL COMMENT 'Tempo total em segundos',
    km_percorridos DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Quilômetros percorridos',
    data_treino DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_data_treino (data_treino)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 