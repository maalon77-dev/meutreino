<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

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
    
    // Listar todas as tabelas
    $sql_tabelas = "SHOW TABLES";
    $result_tabelas = $mysqli->query($sql_tabelas);
    
    $tabelas = [];
    while ($row = $result_tabelas->fetch_array()) {
        $tabelas[] = $row[0];
    }
    
    // Verificar se exercicios_admin existe
    $tabela_existe = in_array('exercicios_admin', $tabelas);
    
    $resultado = [
        'success' => true,
        'tabelas_encontradas' => $tabelas,
        'exercicios_admin_existe' => $tabela_existe
    ];
    
    // Se a tabela existe, buscar alguns dados
    if ($tabela_existe) {
        $sql_contar = "SELECT COUNT(*) as total FROM exercicios_admin";
        $result_contar = $mysqli->query($sql_contar);
        $total = $result_contar->fetch_assoc()['total'];
        
        $sql_amostra = "SELECT id, nome_do_exercicio, foto_gif, link_video, descricao, categoria FROM exercicios_admin LIMIT 3";
        $result_amostra = $mysqli->query($sql_amostra);
        
        $amostra = [];
        while ($row = $result_amostra->fetch_assoc()) {
            $amostra[] = $row;
        }
        
        $resultado['total_exercicios_admin'] = $total;
        $resultado['amostra_exercicios_admin'] = $amostra;
    }
    
    echo json_encode($resultado, JSON_UNESCAPED_UNICODE);
    
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