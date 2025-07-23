<?php
// Teste da API de salvar premio
echo "=== TESTE DA API SALVAR PREMIO ===\n";

// Teste 1: Salvar premio Águia (sem peso)
echo "\n1. Testando salvar premio Águia (sem peso):\n";

$url = "https://airfit.online/api/salvar_premio_v2.php";
$data = [
    'usuario_id' => 1, // Usar um ID válido
    'nome_animal' => 'Águia',
    'emoji_animal' => '🦅',
    'peso_animal' => 0.0,
    'peso_total_levantado' => 0.0,
    'data_conquista' => date('Y-m-d H:i:s'),
    'nome_treino' => 'Treino de Teste',
];

$options = [
    'http' => [
        'header' => "Content-type: application/json\r\n",
        'method' => 'POST',
        'content' => json_encode($data)
    ]
];

$context = stream_context_create($options);
$result = file_get_contents($url, false, $context);

echo "Status: " . (isset($http_response_header) ? $http_response_header[0] : 'N/A') . "\n";
echo "Resposta: $result\n";

$response = json_decode($result, true);
if ($response) {
    echo "Sucesso: " . ($response['sucesso'] ?? 'N/A') . "\n";
    if (isset($response['erro'])) {
        echo "Erro: " . $response['erro'] . "\n";
    }
}

// Teste 2: Buscar premios do usuário
echo "\n2. Testando buscar premios do usuário:\n";

$url2 = "https://airfit.online/api/salvar_premio_v2.php?usuario_id=1";
$result2 = file_get_contents($url2);

echo "Status: " . (isset($http_response_header) ? $http_response_header[0] : 'N/A') . "\n";
echo "Resposta: $result2\n";

$response2 = json_decode($result2, true);
if ($response2) {
    echo "Sucesso: " . ($response2['sucesso'] ?? 'N/A') . "\n";
    echo "Total de premios: " . ($response2['total'] ?? 'N/A') . "\n";
    if (isset($response2['erro'])) {
        echo "Erro: " . $response2['erro'] . "\n";
    }
}

// Teste 3: Verificar estrutura da tabela
echo "\n3. Verificando estrutura da tabela:\n";

try {
    $mysqli = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');
    
    if ($mysqli->connect_error) {
        throw new Exception('Erro de conexão: ' . $mysqli->connect_error);
    }
    
    $mysqli->set_charset('utf8mb4');
    
    // Verificar se a tabela existe
    $result = $mysqli->query("SHOW TABLES LIKE 'premios_conquistados'");
    if ($result->num_rows > 0) {
        echo "✅ Tabela premios_conquistados existe\n";
        
        // Verificar estrutura da tabela
        $result2 = $mysqli->query("DESCRIBE premios_conquistados");
        echo "Estrutura da tabela:\n";
        while ($row = $result2->fetch_assoc()) {
            echo "- {$row['Field']}: {$row['Type']} ({$row['Null']})\n";
        }
        
        // Verificar registros existentes
        $result3 = $mysqli->query("SELECT COUNT(*) as total FROM premios_conquistados");
        $row = $result3->fetch_assoc();
        echo "Total de premios na tabela: {$row['total']}\n";
        
    } else {
        echo "❌ Tabela premios_conquistados não existe\n";
    }
    
    $mysqli->close();
    
} catch (Exception $e) {
    echo "❌ Erro: " . $e->getMessage() . "\n";
}
?> 