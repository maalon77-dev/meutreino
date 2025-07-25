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
    
    // 1. Verificar se a tabela exercicios_admin existe
    $sql_verificar_tabela = "SHOW TABLES LIKE 'exercicios_admin'";
    $result_verificar = $mysqli->query($sql_verificar_tabela);
    
    $tabela_existe = $result_verificar->num_rows > 0;
    
    // 2. Se a tabela existe, buscar alguns registros
    $exercicios_admin = [];
    if ($tabela_existe) {
        $sql_buscar = "SELECT id, nome_do_exercicio, foto_gif, link_video, descricao, categoria, musculos FROM exercicios_admin LIMIT 10";
        $result_buscar = $mysqli->query($sql_buscar);
        
        while ($row = $result_buscar->fetch_assoc()) {
            $exercicios_admin[] = $row;
        }
    }
    
    // 3. Buscar alguns exercícios da tabela exercicios para comparar
    $sql_exercicios = "SELECT id, nome_do_exercicio, foto_gif, link_video, descricao, categoria, musculos FROM exercicios WHERE id_treino = 211 LIMIT 5";
    $result_exercicios = $mysqli->query($sql_exercicios);
    
    $exercicios = [];
    while ($row = $result_exercicios->fetch_assoc()) {
        $exercicios[] = $row;
    }
    
    // 4. Testar busca específica
    $teste_busca = [];
    if ($tabela_existe && !empty($exercicios)) {
        $nome_teste = $exercicios[0]['nome_do_exercicio'] ?? '';
        if (!empty($nome_teste)) {
            $sql_teste = "SELECT * FROM exercicios_admin WHERE nome_do_exercicio = ?";
            $stmt_teste = $mysqli->prepare($sql_teste);
            $stmt_teste->bind_param("s", $nome_teste);
            $stmt_teste->execute();
            $result_teste = $stmt_teste->get_result();
            $teste_busca = $result_teste->fetch_assoc();
            $stmt_teste->close();
        }
    }
    
    echo json_encode([
        'success' => true,
        'tabela_exercicios_admin_existe' => $tabela_existe,
        'total_exercicios_admin' => count($exercicios_admin),
        'exemplos_exercicios_admin' => $exercicios_admin,
        'exemplos_exercicios_treino_211' => $exercicios,
        'teste_busca_nome' => $exercicios[0]['nome_do_exercicio'] ?? 'N/A',
        'resultado_teste_busca' => $teste_busca ?: 'Nenhum resultado encontrado'
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