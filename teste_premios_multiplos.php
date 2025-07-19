<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Configurações do banco de dados
$servername = "academia3322.mysql.dbaas.com.br";
$username = "academia3322";
$password = "vida1503A@";
$dbname = "academia3322";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $e->getMessage()]);
    exit;
}

// Teste: Salvar 5 gorilas
$usuario_id = 3;
$nome_animal = "Gorila";
$emoji_animal = "🦍";
$peso_animal = 200.0;
$peso_total_levantado = 1000.0;
$data_conquista = date('Y-m-d H:i:s');
$nome_treino = "Teste";

$salvos = 0;
$erros = 0;

for ($i = 0; $i < 5; $i++) {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO premios_conquistados 
            (usuario_id, nome_animal, emoji_animal, peso_animal, peso_total_levantado, data_conquista, nome_treino) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $usuario_id,
            $nome_animal,
            $emoji_animal,
            $peso_animal,
            $peso_total_levantado,
            $data_conquista,
            $nome_treino
        ]);
        
        $salvos++;
        echo "✅ Gorila $salvos salvo com sucesso\n";
        
    } catch(PDOException $e) {
        $erros++;
        echo "❌ Erro ao salvar gorila: " . $e->getMessage() . "\n";
    }
}

echo "\n📊 Resultado: $salvos salvos, $erros erros\n";

// Verificar quantos gorilas existem no banco
try {
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as total FROM premios_conquistados 
        WHERE usuario_id = ? AND nome_animal = ?
    ");
    
    $stmt->execute([$usuario_id, $nome_animal]);
    $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "📈 Total de $nome_animal no banco: " . $resultado['total'] . "\n";
    
} catch(PDOException $e) {
    echo "❌ Erro ao contar: " . $e->getMessage() . "\n";
}

echo json_encode([
    'sucesso' => true,
    'salvos' => $salvos,
    'erros' => $erros,
    'total_no_banco' => $resultado['total'] ?? 0
]);
?> 