<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "academia3322.mysql.dbaas.com.br";
$username = "academia3322";
$password = "vida1503A@";
$dbname = "academia3322";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Teste simples - buscar todos os registros da tabela historico_saldo
    $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM historico_saldo");
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'status' => 'success',
        'total_registros' => $result['total'],
        'message' => 'API funcionando corretamente'
    ]);
    
} catch(PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Erro de conexão: ' . $e->getMessage()
    ]);
}
?> 