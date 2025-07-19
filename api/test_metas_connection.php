<?php
header('Content-Type: application/json; charset=utf-8');

// Configuração do banco de dados
$host = 'academia3322.mysql.dbaas.com.br';
$dbname = 'academia3322';
$username = 'academia3322';
$password = 'vida1503A@';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo json_encode([
        'sucesso' => true,
        'message' => 'Conexão com banco estabelecida com sucesso!',
        'host' => $host,
        'database' => $dbname,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch(PDOException $e) {
    echo json_encode([
        'erro' => true,
        'message' => 'Erro de conexão: ' . $e->getMessage(),
        'host' => $host,
        'database' => $dbname,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}
?> 