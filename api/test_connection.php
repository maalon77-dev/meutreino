<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$servername = "academia3322.mysql.dbaas.com.br";
$username = "academia3322";
$password = "vida1503A@";
$dbname = "academia3322";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Testar se a tabela existe
    $stmt = $pdo->prepare("SHOW TABLES LIKE 'historico_treinos'");
    $stmt->execute();
    $table_exists = $stmt->rowCount() > 0;
    
    echo json_encode([
        "success" => true,
        "message" => "Conexão estabelecida com sucesso",
        "table_exists" => $table_exists
    ]);
    
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => $e->getMessage()
    ]);
}
?>
