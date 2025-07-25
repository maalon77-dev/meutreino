<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Configuração de erro
error_reporting(E_ALL);
ini_set('display_errors', 1);

try {
    // Conectar ao banco
    $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
    
    // Verificar conexão
    if ($mysqli->connect_error) {
        throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
    }
    
    // Definir charset
    $mysqli->set_charset('utf8mb4');
    
    // Teste 1: Busca case-insensitive por "rosca"
    echo "=== TESTE 1: Busca case-insensitive por 'rosca' ===\n";
    $termo_busca = 'rosca';
    $termo_busca_lower = '%' . strtolower($termo_busca) . '%';
    
    $query1 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE ? ORDER BY nome_do_exercicio";
    $stmt1 = $mysqli->prepare($query1);
    $stmt1->bind_param('s', $termo_busca_lower);
    $stmt1->execute();
    $result1 = $stmt1->get_result();
    
    $exercicios_rosca = [];
    while ($row = $result1->fetch_assoc()) {
        $exercicios_rosca[] = $row;
    }
    
    echo "Exercícios encontrados com 'rosca' (case-insensitive): " . count($exercicios_rosca) . "\n";
    foreach ($exercicios_rosca as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 2: Busca case-insensitive por "martelo"
    echo "\n=== TESTE 2: Busca case-insensitive por 'martelo' ===\n";
    $termo_busca2 = 'martelo';
    $termo_busca_lower2 = '%' . strtolower($termo_busca2) . '%';
    
    $query2 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE ? ORDER BY nome_do_exercicio";
    $stmt2 = $mysqli->prepare($query2);
    $stmt2->bind_param('s', $termo_busca_lower2);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    
    $exercicios_martelo = [];
    while ($row = $result2->fetch_assoc()) {
        $exercicios_martelo[] = $row;
    }
    
    echo "Exercícios encontrados com 'martelo' (case-insensitive): " . count($exercicios_martelo) . "\n";
    foreach ($exercicios_martelo as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 3: Verificar exercícios que contêm "rosca" mas não aparecem na busca case-insensitive
    echo "\n=== TESTE 3: Verificação de exercícios que contêm 'rosca' ===\n";
    $query3 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE nome_do_exercicio LIKE '%rosca%' OR nome_do_exercicio LIKE '%Rosca%' OR nome_do_exercicio LIKE '%ROSCA%' ORDER BY nome_do_exercicio";
    $result3 = $mysqli->query($query3);
    
    $exercicios_manual = [];
    while ($row = $result3->fetch_assoc()) {
        $exercicios_manual[] = $row;
    }
    
    echo "Exercícios encontrados manualmente com 'rosca': " . count($exercicios_manual) . "\n";
    foreach ($exercicios_manual as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 4: Verificar exercícios que contêm "martelo" mas não aparecem na busca case-insensitive
    echo "\n=== TESTE 4: Verificação de exercícios que contêm 'martelo' ===\n";
    $query4 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE nome_do_exercicio LIKE '%martelo%' OR nome_do_exercicio LIKE '%Martelo%' OR nome_do_exercicio LIKE '%MARTELO%' ORDER BY nome_do_exercicio";
    $result4 = $mysqli->query($query4);
    
    $exercicios_manual_martelo = [];
    while ($row = $result4->fetch_assoc()) {
        $exercicios_manual_martelo[] = $row;
    }
    
    echo "Exercícios encontrados manualmente com 'martelo': " . count($exercicios_manual_martelo) . "\n";
    foreach ($exercicios_manual_martelo as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 5: Verificar se há exercícios que contêm "rosca martelo" mas não aparecem na busca por "rosca"
    echo "\n=== TESTE 5: Verificação de exercícios com 'rosca martelo' ===\n";
    $query5 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE '%rosca%martelo%' OR LOWER(nome_do_exercicio) LIKE '%martelo%rosca%' ORDER BY nome_do_exercicio";
    $result5 = $mysqli->query($query5);
    
    $exercicios_rosca_martelo = [];
    while ($row = $result5->fetch_assoc()) {
        $exercicios_rosca_martelo[] = $row;
    }
    
    echo "Exercícios encontrados com 'rosca' e 'martelo': " . count($exercicios_rosca_martelo) . "\n";
    foreach ($exercicios_rosca_martelo as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Fechar conexões
    $stmt1->close();
    $stmt2->close();
    $mysqli->close();
    
    // Retornar resultados em JSON
    $response = [
        'teste_rosca_case_insensitive' => [
            'termo_busca' => $termo_busca,
            'total_encontrados' => count($exercicios_rosca),
            'exercicios' => $exercicios_rosca
        ],
        'teste_martelo_case_insensitive' => [
            'termo_busca' => $termo_busca2,
            'total_encontrados' => count($exercicios_martelo),
            'exercicios' => $exercicios_martelo
        ],
        'teste_rosca_manual' => [
            'total_encontrados' => count($exercicios_manual),
            'exercicios' => $exercicios_manual
        ],
        'teste_martelo_manual' => [
            'total_encontrados' => count($exercicios_manual_martelo),
            'exercicios' => $exercicios_manual_martelo
        ],
        'teste_rosca_martelo' => [
            'total_encontrados' => count($exercicios_rosca_martelo),
            'exercicios' => $exercicios_rosca_martelo
        ]
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo "Erro: " . $e->getMessage();
}
?> 