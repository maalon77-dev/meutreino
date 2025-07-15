<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Pegar id_treino do parâmetro ou usar 164 como padrão
$id_treino = intval($_REQUEST['id_treino'] ?? 164);

// Teste de conexão com banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $conn->connect_error]);
    exit;
}

// Query para buscar exercícios
$sql = "SELECT * FROM exercicios WHERE id_treino = $id_treino";
$result = $conn->query($sql);

if (!$result) {
    echo json_encode(['erro' => 'Erro na query: ' . $conn->error]);
    exit;
}

$dados = [];
while ($row = $result->fetch_assoc()) {
    $dados[] = $row;
}

echo json_encode($dados);
$conn->close();
?> 