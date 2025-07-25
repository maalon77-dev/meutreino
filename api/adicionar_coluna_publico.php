<?php
header('Content-Type: application/json; charset=utf-8');

// Configurações do banco de dados
$host = 'academia3322.mysql.dbaas.com.br';
$dbname = 'academia3322';
$username = 'academia3322';
$password = 'vida1503A@';

try {
    // Conexão com o banco
    $mysqli = new mysqli($host, $username, $password, $dbname);
    
    if ($mysqli->connect_error) {
        throw new Exception("Erro de conexão: " . $mysqli->connect_error);
    }
    
    $mysqli->set_charset("utf8mb4");
    
    // Verificar se a coluna já existe
    $sql_check = "SHOW COLUMNS FROM treinos LIKE 'publico'";
    $result = $mysqli->query($sql_check);
    
    if ($result->num_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Coluna "publico" já existe na tabela treinos'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        // Adicionar a coluna publico
        $sql_add_column = "ALTER TABLE treinos ADD COLUMN publico ENUM('0', '1') DEFAULT '0' AFTER nome_treino";
        
        if ($mysqli->query($sql_add_column)) {
            // Adicionar índice
            $sql_add_index = "CREATE INDEX idx_treinos_publico ON treinos(publico)";
            $mysqli->query($sql_add_index);
            
            echo json_encode([
                'success' => true,
                'message' => 'Coluna "publico" adicionada com sucesso na tabela treinos'
            ], JSON_UNESCAPED_UNICODE);
        } else {
            throw new Exception("Erro ao adicionar coluna: " . $mysqli->error);
        }
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
} finally {
    if (isset($mysqli)) {
        $mysqli->close();
    }
}
?> 