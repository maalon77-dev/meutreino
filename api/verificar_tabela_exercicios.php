<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

// Conectar ao banco
$conn = new mysqli($host, $user, $pass, $db);

// Configurar charset para UTF-8
$conn->set_charset("utf8mb4");

// Verificar conexão
if ($conn->connect_error) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $conn->connect_error]);
    exit;
}

// Verificar estrutura da tabela exercicios
$sql = "DESCRIBE exercicios";
$result = $conn->query($sql);

if (!$result) {
    echo json_encode(['erro' => 'Erro ao verificar tabela: ' . $conn->error]);
    exit;
}

$colunas = [];
while ($row = $result->fetch_assoc()) {
    $colunas[] = $row;
}

// Verificar se existe a coluna distancia
$temDistancia = false;
foreach ($colunas as $coluna) {
    if ($coluna['Field'] === 'distancia') {
        $temDistancia = true;
        break;
    }
}

echo json_encode([
    'sucesso' => true,
    'estrutura_tabela' => $colunas,
    'tem_coluna_distancia' => $temDistancia,
    'total_colunas' => count($colunas)
]);

$conn->close();
?> 