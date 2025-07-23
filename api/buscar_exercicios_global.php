<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuração de erro
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Pegar parâmetros de busca
$termo_busca = $_GET['termo'] ?? '';
$categoria = $_GET['categoria'] ?? '';
$grupo = $_GET['grupo'] ?? '';

// Debug
error_log("=== BUSCA GLOBAL ===");
error_log("Termo de busca: $termo_busca");
error_log("Categoria: $categoria");
error_log("Grupo: $grupo");

// Validar se pelo menos um parâmetro foi fornecido
if (empty($termo_busca) && empty($categoria) && empty($grupo)) {
    // Se não há parâmetros, retornar todos os exercícios da tabela exercicios_admin
    error_log("Nenhum parâmetro fornecido, retornando todos os exercícios");
}

try {
    // Conectar ao banco
    $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
    
    // Verificar conexão
    if ($mysqli->connect_error) {
        throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
    }
    
    // Definir charset
    $mysqli->set_charset('utf8mb4');
    
    // Construir query dinamicamente
    $where_conditions = [];
    $params = [];
    $types = '';
    
    // Se termo de busca foi fornecido, buscar em múltiplos campos
    if (!empty($termo_busca)) {
        $termo_busca = '%' . $termo_busca . '%';
        $where_conditions[] = "(nome_do_exercicio LIKE ? OR descricao LIKE ? OR categoria LIKE ? OR grupo LIKE ?)";
        $params[] = $termo_busca;
        $params[] = $termo_busca;
        $params[] = $termo_busca;
        $params[] = $termo_busca;
        $types .= 'ssss';
    }
    
    // Se categoria foi fornecida
    if (!empty($categoria)) {
        $where_conditions[] = "categoria = ?";
        $params[] = $categoria;
        $types .= 's';
    }
    
    // Se grupo foi fornecido
    if (!empty($grupo)) {
        $where_conditions[] = "grupo = ?";
        $params[] = $grupo;
        $types .= 's';
    }
    
    // Montar query final - APENAS na tabela exercicios_admin
    $query = "SELECT * FROM exercicios_admin";
    if (!empty($where_conditions)) {
        $query .= " WHERE " . implode(' AND ', $where_conditions);
    }
    $query .= " ORDER BY nome_do_exercicio";
    
    error_log("Query final: $query");
    error_log("Parâmetros: " . print_r($params, true));
    
    // Preparar e executar consulta
    $stmt = $mysqli->prepare($query);
    
    if (!$stmt) {
        throw new Exception('Erro na preparação da consulta: ' . $mysqli->error);
    }
    
    // Bind dos parâmetros se houver
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    if (!$result) {
        throw new Exception('Erro na execução da consulta: ' . $stmt->error);
    }
    
    $exercicios = [];
    
    while ($row = $result->fetch_assoc()) {
        $exercicios[] = $row;
    }
    
    error_log("Total de exercícios encontrados na tabela exercicios_admin: " . count($exercicios));
    
    // Se não encontrou nada com termo de busca, tentar busca mais ampla
    if (empty($exercicios) && !empty($_GET['termo'])) {
        error_log("Nenhum resultado encontrado, tentando busca mais ampla...");
        
        $termo_amplo = '%' . $_GET['termo'] . '%';
        $query_amplo = "SELECT * FROM exercicios_admin WHERE nome_do_exercicio LIKE ? ORDER BY nome_do_exercicio";
        
        $stmt_amplo = $mysqli->prepare($query_amplo);
        $stmt_amplo->bind_param('s', $termo_amplo);
        $stmt_amplo->execute();
        $result_amplo = $stmt_amplo->get_result();
        
        $exercicios = [];
        while ($row = $result_amplo->fetch_assoc()) {
            $exercicios[] = $row;
        }
        
        error_log("Busca ampla encontrou: " . count($exercicios) . " exercícios");
        $stmt_amplo->close();
    }
    
    // Fechar conexão
    $stmt->close();
    $mysqli->close();
    
    // Retornar JSON
    $response = [
        'total_exercicios' => count($exercicios),
        'termo_busca' => $_GET['termo'] ?? '',
        'categoria' => $categoria,
        'grupo' => $grupo,
        'tabela_buscada' => 'exercicios_admin',
        'exercicios' => $exercicios
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    error_log("Erro: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['erro' => $e->getMessage()]);
}
?> 