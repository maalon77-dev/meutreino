<?php
header('Content-Type: application/json');

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db   = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $conn->connect_error]);
    exit;
}

$tabela = $_REQUEST['tabela'] ?? '';
$acao   = $_REQUEST['acao'] ?? '';

if (!$tabela || !$acao) {
    echo json_encode(['erro' => 'Tabela e ação são obrigatórias']);
    exit;
}

// Função para escapar campos
function esc($str) {
    return htmlspecialchars($str, ENT_QUOTES, 'UTF-8');
}

switch ($acao) {
    case 'listar':
        $sql = "SELECT * FROM `$tabela`";
        $result = $conn->query($sql);
        $dados = [];
        while ($row = $result->fetch_assoc()) {
            $dados[] = $row;
        }
        echo json_encode($dados);
        break;

    case 'buscar':
        $id = intval($_REQUEST['id'] ?? 0);
        $sql = "SELECT * FROM `$tabela` WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('i', $id);
        $stmt->execute();
        $res = $stmt->get_result();
        echo json_encode($res->fetch_assoc());
        break;

    case 'inserir':
        $dados = $_POST;
        unset($dados['tabela'], $dados['acao']);
        $campos = implode(',', array_map('esc', array_keys($dados)));
        $placeholders = implode(',', array_fill(0, count($dados), '?'));
        $tipos = str_repeat('s', count($dados));
        $sql = "INSERT INTO `$tabela` ($campos) VALUES ($placeholders)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($tipos, ...array_values($dados));
        $ok = $stmt->execute();
        echo json_encode(['sucesso' => $ok, 'id' => $conn->insert_id]);
        break;

    case 'atualizar':
        $id = intval($_POST['id'] ?? 0);
        $dados = $_POST;
        unset($dados['tabela'], $dados['acao'], $dados['id']);
        $set = implode(',', array_map(function($k){ return esc($k) . '=?'; }, array_keys($dados)));
        $tipos = str_repeat('s', count($dados)) . 'i';
        $sql = "UPDATE `$tabela` SET $set WHERE id=?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($tipos, ...array_values($dados), $id);
        $ok = $stmt->execute();
        echo json_encode(['sucesso' => $ok]);
        break;

    case 'deletar':
        $id = intval($_REQUEST['id'] ?? 0);
        $sql = "DELETE FROM `$tabela` WHERE id=?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('i', $id);
        $ok = $stmt->execute();
        echo json_encode(['sucesso' => $ok]);
        break;

    default:
        echo json_encode(['erro' => 'Ação não reconhecida']);
}

$conn->close();
?> 