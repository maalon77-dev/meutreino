<?php
// Configurações do banco de dados
$host = 'academia3322.mysql.dbaas.com.br';
$dbname = 'academia3322';
$username = 'academia3322';
$password = 'vida1503A@';

echo "Iniciando processo de adição da coluna 'publico'...\n";

try {
    // Conexão com o banco
    $mysqli = new mysqli($host, $username, $password, $dbname);
    
    if ($mysqli->connect_error) {
        throw new Exception("Erro de conexão: " . $mysqli->connect_error);
    }
    
    echo "Conexão estabelecida com sucesso!\n";
    $mysqli->set_charset("utf8mb4");
    
    // Verificar se a coluna já existe
    echo "Verificando se a coluna 'publico' já existe...\n";
    $sql_check = "SHOW COLUMNS FROM treinos LIKE 'publico'";
    $result = $mysqli->query($sql_check);
    
    if ($result->num_rows > 0) {
        echo "✅ Coluna 'publico' já existe na tabela treinos\n";
    } else {
        echo "Coluna 'publico' não encontrada. Adicionando...\n";
        
        // Adicionar a coluna publico
        $sql_add_column = "ALTER TABLE treinos ADD COLUMN publico ENUM('0', '1') DEFAULT '0' AFTER nome_treino";
        
        if ($mysqli->query($sql_add_column)) {
            echo "✅ Coluna 'publico' adicionada com sucesso!\n";
            
            // Adicionar índice
            echo "Adicionando índice para otimização...\n";
            $sql_add_index = "CREATE INDEX idx_treinos_publico ON treinos(publico)";
            if ($mysqli->query($sql_add_index)) {
                echo "✅ Índice criado com sucesso!\n";
            } else {
                echo "⚠️ Erro ao criar índice: " . $mysqli->error . "\n";
            }
            
            // Atualizar treinos existentes para serem privados por padrão
            echo "Atualizando treinos existentes...\n";
            $sql_update = "UPDATE treinos SET publico = '0' WHERE publico IS NULL";
            if ($mysqli->query($sql_update)) {
                echo "✅ Treinos existentes atualizados para privados!\n";
            } else {
                echo "⚠️ Erro ao atualizar treinos: " . $mysqli->error . "\n";
            }
            
        } else {
            throw new Exception("Erro ao adicionar coluna: " . $mysqli->error);
        }
    }
    
    // Verificar estrutura final
    echo "\nEstrutura atual da tabela treinos:\n";
    $sql_structure = "DESCRIBE treinos";
    $result_structure = $mysqli->query($sql_structure);
    
    while ($row = $result_structure->fetch_assoc()) {
        echo "- " . $row['Field'] . " (" . $row['Type'] . ")\n";
    }
    
    echo "\n🎉 Processo concluído com sucesso!\n";
    
} catch (Exception $e) {
    echo "❌ Erro: " . $e->getMessage() . "\n";
} finally {
    if (isset($mysqli)) {
        $mysqli->close();
        echo "Conexão fechada.\n";
    }
}
?> 