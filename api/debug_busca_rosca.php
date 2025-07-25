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
    
    echo "=== INVESTIGAÇÃO DETALHADA DA BUSCA POR 'ROSCA' ===\n\n";
    
    // Teste 1: Verificar todos os exercícios que contêm "rosca" (qualquer variação)
    echo "=== TESTE 1: Todos os exercícios com 'rosca' (qualquer variação) ===\n";
    $query1 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE nome_do_exercicio LIKE '%rosca%' OR nome_do_exercicio LIKE '%Rosca%' OR nome_do_exercicio LIKE '%ROSCA%' ORDER BY nome_do_exercicio";
    $result1 = $mysqli->query($query1);
    
    $todos_com_rosca = [];
    while ($row = $result1->fetch_assoc()) {
        $todos_com_rosca[] = $row;
    }
    
    echo "Total encontrado com variações de 'rosca': " . count($todos_com_rosca) . "\n";
    foreach ($todos_com_rosca as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 2: Busca case-insensitive exata como na API
    echo "\n=== TESTE 2: Busca case-insensitive (como na API) ===\n";
    $termo_busca = 'rosca';
    $termo_busca_lower = '%' . strtolower($termo_busca) . '%';
    
    $query2 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE ? ORDER BY nome_do_exercicio";
    $stmt2 = $mysqli->prepare($query2);
    $stmt2->bind_param('s', $termo_busca_lower);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    
    $case_insensitive = [];
    while ($row = $result2->fetch_assoc()) {
        $case_insensitive[] = $row;
    }
    
    echo "Total encontrado com case-insensitive: " . count($case_insensitive) . "\n";
    foreach ($case_insensitive as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 3: Verificar se há diferença entre as duas buscas
    echo "\n=== TESTE 3: Comparação entre buscas ===\n";
    $ids_todos = array_column($todos_com_rosca, 'id');
    $ids_case_insensitive = array_column($case_insensitive, 'id');
    
    $diferenca = array_diff($ids_todos, $ids_case_insensitive);
    echo "IDs que estão em 'todos_com_rosca' mas não em 'case_insensitive': " . implode(', ', $diferenca) . "\n";
    
    $diferenca2 = array_diff($ids_case_insensitive, $ids_todos);
    echo "IDs que estão em 'case_insensitive' mas não em 'todos_com_rosca': " . implode(', ', $diferenca2) . "\n";
    
    // Teste 4: Verificar exercícios específicos que podem estar sendo perdidos
    echo "\n=== TESTE 4: Verificação de exercícios específicos ===\n";
    if (!empty($diferenca)) {
        foreach ($diferenca as $id) {
            $query4 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE id = ?";
            $stmt4 = $mysqli->prepare($query4);
            $stmt4->bind_param('i', $id);
            $stmt4->execute();
            $result4 = $stmt4->get_result();
            $row = $result4->fetch_assoc();
            echo "Exercício perdido - ID: " . $row['id'] . " | Nome: " . $row['nome_do_exercicio'] . "\n";
            echo "  - LOWER(nome): " . strtolower($row['nome_do_exercicio']) . "\n";
            echo "  - Contém 'rosca'? " . (strpos(strtolower($row['nome_do_exercicio']), 'rosca') !== false ? 'SIM' : 'NÃO') . "\n";
            $stmt4->close();
        }
    }
    
    // Teste 5: Verificar se há problemas com caracteres especiais
    echo "\n=== TESTE 5: Verificação de caracteres especiais ===\n";
    $query5 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE nome_do_exercicio LIKE '%rosca%' ORDER BY nome_do_exercicio";
    $result5 = $mysqli->query($query5);
    
    $com_rosca_minusculo = [];
    while ($row = $result5->fetch_assoc()) {
        $com_rosca_minusculo[] = $row;
    }
    
    echo "Total encontrado com 'rosca' minúsculo: " . count($com_rosca_minusculo) . "\n";
    foreach ($com_rosca_minusculo as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . "\n";
    }
    
    // Fechar conexões
    $stmt2->close();
    $mysqli->close();
    
    // Retornar resultados em JSON
    $response = [
        'todos_com_rosca' => [
            'total' => count($todos_com_rosca),
            'exercicios' => $todos_com_rosca
        ],
        'case_insensitive' => [
            'total' => count($case_insensitive),
            'exercicios' => $case_insensitive
        ],
        'diferenca' => [
            'perdidos' => array_values($diferenca),
            'adicionais' => array_values($diferenca2)
        ],
        'com_rosca_minusculo' => [
            'total' => count($com_rosca_minusculo),
            'exercicios' => $com_rosca_minusculo
        ]
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo "Erro: " . $e->getMessage();
}
?> 