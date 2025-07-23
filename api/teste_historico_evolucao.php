<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

// Conectar ao banco
$conn = new mysqli($host, $user, $pass, $db);

// Configurar charset para UTF-8
$conn->set_charset("utf8mb4");

// Verificar conexão
if ($conn->connect_error) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $conn->connect_error]);
    exit;
}
    
    // Verificar se a tabela existe
    $sql = "SHOW TABLES LIKE 'historico_evolucao'";
    $result = $conn->query($sql);
    $tabelaExiste = $result->num_rows > 0;
    
    if (!$tabelaExiste) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Tabela historico_evolucao não existe. Execute o SQL primeiro.',
            'sql_para_executar' => file_get_contents('create_historico_evolucao_table.sql')
        ]);
        exit;
    }
    
    // Verificar estrutura da tabela
    $sql = "DESCRIBE historico_evolucao";
    $result = $conn->query($sql);
    $colunas = [];
    while ($row = $result->fetch_assoc()) {
        $colunas[] = $row;
    }
    
    // Contar registros
    $sql = "SELECT COUNT(*) as total FROM historico_evolucao";
    $result = $conn->query($sql);
    $total = $result->fetch_assoc()['total'];
    
    echo json_encode([
        'sucesso' => true,
        'mensagem' => 'Tabela historico_evolucao existe e está funcionando',
        'estrutura' => $colunas,
        'total_registros' => $total
    ]);
?> 