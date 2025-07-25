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
    
    // Teste 1: Busca por "rosca" (case-insensitive)
    echo "=== TESTE 1: Busca por 'rosca' ===\n";
    $termo_busca = 'rosca';
    $termo_busca_lower = '%' . strtolower($termo_busca) . '%';
    
    $query1 = "SELECT nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE ? ORDER BY nome_do_exercicio";
    $stmt1 = $mysqli->prepare($query1);
    $stmt1->bind_param('s', $termo_busca_lower);
    $stmt1->execute();
    $result1 = $stmt1->get_result();
    
    $exercicios_rosca = [];
    while ($row = $result1->fetch_assoc()) {
        $exercicios_rosca[] = $row;
    }
    
    echo "Exercícios encontrados com 'rosca': " . count($exercicios_rosca) . "\n";
    foreach ($exercicios_rosca as $exercicio) {
        echo "- " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 2: Busca por "martelo" (case-insensitive)
    echo "\n=== TESTE 2: Busca por 'martelo' ===\n";
    $termo_busca2 = 'martelo';
    $termo_busca_lower2 = '%' . strtolower($termo_busca2) . '%';
    
    $query2 = "SELECT nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE ? ORDER BY nome_do_exercicio";
    $stmt2 = $mysqli->prepare($query2);
    $stmt2->bind_param('s', $termo_busca_lower2);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    
    $exercicios_martelo = [];
    while ($row = $result2->fetch_assoc()) {
        $exercicios_martelo[] = $row;
    }
    
    echo "Exercícios encontrados com 'martelo': " . count($exercicios_martelo) . "\n";
    foreach ($exercicios_martelo as $exercicio) {
        echo "- " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 3: Verificar se há exercícios que contêm "rosca" mas não aparecem na busca
    echo "\n=== TESTE 3: Verificação manual ===\n";
    $query3 = "SELECT nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE nome_do_exercicio LIKE '%rosca%' OR nome_do_exercicio LIKE '%Rosca%' OR nome_do_exercicio LIKE '%ROSCA%' ORDER BY nome_do_exercicio";
    $result3 = $mysqli->query($query3);
    
    $exercicios_manual = [];
    while ($row = $result3->fetch_assoc()) {
        $exercicios_manual[] = $row;
    }
    
    echo "Exercícios encontrados manualmente com 'rosca': " . count($exercicios_manual) . "\n";
    foreach ($exercicios_manual as $exercicio) {
        echo "- " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Fechar conexões
    $stmt1->close();
    $stmt2->close();
    $mysqli->close();
    
    // Retornar resultados em JSON
    $response = [
        'teste_rosca' => [
            'termo_busca' => $termo_busca,
            'total_encontrados' => count($exercicios_rosca),
            'exercicios' => $exercicios_rosca
        ],
        'teste_martelo' => [
            'termo_busca' => $termo_busca2,
            'total_encontrados' => count($exercicios_martelo),
            'exercicios' => $exercicios_martelo
        ],
        'teste_manual' => [
            'total_encontrados' => count($exercicios_manual),
            'exercicios' => $exercicios_manual
        ]
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo "Erro: " . $e->getMessage();
}
?> 