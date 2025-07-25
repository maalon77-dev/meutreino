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
    
    // 2. Buscar um exercício do treino 211 para teste
    $sql_exercicio_teste = "SELECT * FROM exercicios WHERE id_treino = 211 LIMIT 1";
    $result_exercicio = $mysqli->query($sql_exercicio_teste);
    $exercicio_teste = $result_exercicio->fetch_assoc();
    
    $resultado = [
        'success' => true,
        'tabela_exercicios_admin_existe' => $tabela_existe,
        'exercicio_teste' => $exercicio_teste
    ];
    
    // 3. Se a tabela existe, testar busca
    if ($tabela_existe && $exercicio_teste) {
        $nome_exercicio = $exercicio_teste['nome_do_exercicio'] ?? '';
        
        // Busca exata
        $sql_buscar_exato = "SELECT * FROM exercicios_admin WHERE nome_do_exercicio = ? LIMIT 1";
        $stmt_exato = $mysqli->prepare($sql_buscar_exato);
        $stmt_exato->bind_param("s", $nome_exercicio);
        $stmt_exato->execute();
        $result_exato = $stmt_exato->get_result();
        $dados_exato = $result_exato->fetch_assoc();
        $stmt_exato->close();
        
        // Busca flexível
        $sql_buscar_flexivel = "SELECT * FROM exercicios_admin WHERE nome_do_exercicio LIKE ? LIMIT 1";
        $stmt_flexivel = $mysqli->prepare($sql_buscar_flexivel);
        $nome_flexivel = '%' . $nome_exercicio . '%';
        $stmt_flexivel->bind_param("s", $nome_flexivel);
        $stmt_flexivel->execute();
        $result_flexivel = $stmt_flexivel->get_result();
        $dados_flexivel = $result_flexivel->fetch_assoc();
        $stmt_flexivel->close();
        
        // Listar alguns exercícios da tabela admin para comparação
        $sql_listar_admin = "SELECT id, nome_do_exercicio FROM exercicios_admin LIMIT 5";
        $result_listar = $mysqli->query($sql_listar_admin);
        $lista_admin = [];
        while ($row = $result_listar->fetch_assoc()) {
            $lista_admin[] = $row;
        }
        
        $resultado['busca_exata'] = $dados_exato ?: 'Nenhum resultado';
        $resultado['busca_flexivel'] = $dados_flexivel ?: 'Nenhum resultado';
        $resultado['lista_exercicios_admin'] = $lista_admin;
        $resultado['nome_buscado'] = $nome_exercicio;
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