<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$id_treino = intval($_REQUEST['id_treino'] ?? 164);

$conn = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');

// Configurar charset para UTF-8
$conn->set_charset("utf8mb4");

if ($conn->connect_error) {
    die('Erro de conexão: ' . $conn->connect_error);
}

$sql = "SELECT * FROM exercicios WHERE id_treino = $id_treino";
$result = $conn->query($sql);

if (!$result) {
    die('Erro na query: ' . $conn->error);
}

$dados = [];
while ($row = $result->fetch_assoc()) {
    $dados[] = $row;
}

echo json_encode($dados, JSON_UNESCAPED_UNICODE);
$conn->close();
?> 