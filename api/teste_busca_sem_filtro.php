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
    
    echo "=== TESTE: Busca por 'rosca' SEM filtro de categoria ===\n\n";
    
    // Teste 1: Busca por "rosca" sem filtro de categoria
    echo "=== TESTE 1: Busca por 'rosca' sem filtro ===\n";
    $termo_busca = 'rosca';
    $termo_busca_lower = '%' . strtolower($termo_busca) . '%';
    
    $query1 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE ? ORDER BY nome_do_exercicio";
    $stmt1 = $mysqli->prepare($query1);
    $stmt1->bind_param('s', $termo_busca_lower);
    $stmt1->execute();
    $result1 = $stmt1->get_result();
    
    $todos_rosca = [];
    while ($row = $result1->fetch_assoc()) {
        $todos_rosca[] = $row;
    }
    
    echo "Total encontrado com 'rosca' sem filtro: " . count($todos_rosca) . "\n";
    foreach ($todos_rosca as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 2: Busca por "rosca" com filtro de categoria "Calistenia"
    echo "\n=== TESTE 2: Busca por 'rosca' com filtro 'Calistenia' ===\n";
    $categoria = 'Calistenia';
    
    $query2 = "SELECT id, nome_do_exercicio, categoria, grupo FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE ? AND LOWER(categoria) = LOWER(?) ORDER BY nome_do_exercicio";
    $stmt2 = $mysqli->prepare($query2);
    $stmt2->bind_param('ss', $termo_busca_lower, $categoria);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    
    $rosca_calistenia = [];
    while ($row = $result2->fetch_assoc()) {
        $rosca_calistenia[] = $row;
    }
    
    echo "Total encontrado com 'rosca' e categoria 'Calistenia': " . count($rosca_calistenia) . "\n";
    foreach ($rosca_calistenia as $exercicio) {
        echo "- ID: " . $exercicio['id'] . " | " . $exercicio['nome_do_exercicio'] . " (Categoria: " . $exercicio['categoria'] . ", Grupo: " . $exercicio['grupo'] . ")\n";
    }
    
    // Teste 3: Verificar todas as categorias que têm exercícios com "rosca"
    echo "\n=== TESTE 3: Categorias com exercícios 'rosca' ===\n";
    $query3 = "SELECT DISTINCT categoria, COUNT(*) as total FROM exercicios_admin WHERE LOWER(nome_do_exercicio) LIKE ? GROUP BY categoria ORDER BY categoria";
    $stmt3 = $mysqli->prepare($query3);
    $stmt3->bind_param('s', $termo_busca_lower);
    $stmt3->execute();
    $result3 = $stmt3->get_result();
    
    $categorias_com_rosca = [];
    while ($row = $result3->fetch_assoc()) {
        $categorias_com_rosca[] = $row;
    }
    
    echo "Categorias com exercícios 'rosca':\n";
    foreach ($categorias_com_rosca as $cat) {
        echo "- " . $cat['categoria'] . ": " . $cat['total'] . " exercícios\n";
    }
    
    // Fechar conexões
    $stmt1->close();
    $stmt2->close();
    $stmt3->close();
    $mysqli->close();
    
    // Retornar resultados em JSON
    $response = [
        'todos_rosca' => [
            'total' => count($todos_rosca),
            'exercicios' => $todos_rosca
        ],
        'rosca_calistenia' => [
            'total' => count($rosca_calistenia),
            'exercicios' => $rosca_calistenia
        ],
        'categorias_com_rosca' => $categorias_com_rosca
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo "Erro: " . $e->getMessage();
}
?> 