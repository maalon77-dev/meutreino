<?php
// Script para adicionar a coluna "ordem" na tabela exercicios se ela não existir

try {
    // Conectar ao banco
    $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
    
    // Verificar conexão
    if ($mysqli->connect_error) {
        throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
    }
    
    // Definir charset
    $mysqli->set_charset('utf8');
    
    // Verificar se a coluna 'ordem' existe
    $result = $mysqli->query("SHOW COLUMNS FROM exercicios LIKE 'ordem'");
    
    if ($result->num_rows == 0) {
        // Coluna não existe, vamos criar
        $sql = "ALTER TABLE exercicios ADD COLUMN ordem INT DEFAULT NULL";
        
        if ($mysqli->query($sql) === TRUE) {
            echo json_encode(['sucesso' => true, 'mensagem' => 'Coluna ordem adicionada com sucesso!']);
        } else {
            echo json_encode(['erro' => 'Erro ao adicionar coluna: ' . $mysqli->error]);
        }
    } else {
        echo json_encode(['sucesso' => true, 'mensagem' => 'Coluna ordem já existe!']);
    }
    
    // Fechar conexão
    $mysqli->close();
    
} catch (Exception $e) {
    echo json_encode(['erro' => 'Erro: ' . $e->getMessage()]);
}
?> 