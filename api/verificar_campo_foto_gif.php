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
    
    // 1. Verificar estrutura da tabela exercicios
    $sql_estrutura = "DESCRIBE exercicios";
    $result_estrutura = $mysqli->query($sql_estrutura);
    
    $campos = [];
    while ($row = $result_estrutura->fetch_assoc()) {
        $campos[] = $row;
    }
    
    // 2. Verificar se o campo foto_gif existe
    $tem_foto_gif = false;
    foreach ($campos as $campo) {
        if ($campo['Field'] === 'foto_gif') {
            $tem_foto_gif = true;
            break;
        }
    }
    
    // 3. Buscar alguns exercícios do treino 211 para ver os dados
    $sql_exercicios = "SELECT id, nome_do_exercicio, foto_gif, link_video, descricao, categoria, musculos FROM exercicios WHERE id_treino = 211 LIMIT 3";
    $result_exercicios = $mysqli->query($sql_exercicios);
    
    $exercicios = [];
    while ($row = $result_exercicios->fetch_assoc()) {
        $exercicios[] = $row;
    }
    
    // 4. Verificar se há outros campos relacionados a foto
    $campos_foto = [];
    foreach ($campos as $campo) {
        if (strpos($campo['Field'], 'foto') !== false || strpos($campo['Field'], 'gif') !== false) {
            $campos_foto[] = $campo;
        }
    }
    
    echo json_encode([
        'success' => true,
        'estrutura_tabela' => $campos,
        'tem_campo_foto_gif' => $tem_foto_gif,
        'campos_relacionados_foto' => $campos_foto,
        'exemplos_exercicios_treino_211' => $exercicios,
        'total_campos' => count($campos)
    ], JSON_UNESCAPED_UNICODE);
    
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