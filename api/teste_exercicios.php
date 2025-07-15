<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

echo "Iniciando teste...\n";

$id_treino = 164;

echo "Conectando ao banco...\n";

$conn = new mysqli('academia3322.mysql.dbaas.com.br', 'academia3322', 'vida1503A@', 'academia3322');

if ($conn->connect_error) {
    echo "Erro de conexão: " . $conn->connect_error . "\n";
    exit;
}

echo "Conexão OK!\n";

$sql = "SELECT * FROM exercicios WHERE id_treino = $id_treino";
echo "SQL: $sql\n";

$result = $conn->query($sql);

if (!$result) {
    echo "Erro na query: " . $conn->error . "\n";
    exit;
}

$dados = [];
while ($row = $result->fetch_assoc()) {
    $dados[] = $row;
}

echo "Exercícios encontrados: " . count($dados) . "\n";

if (count($dados) > 0) {
    echo "Primeiro exercício:\n";
    print_r($dados[0]);
}

echo "\nJSON final:\n";
echo json_encode($dados);

$conn->close();
?> 