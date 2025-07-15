<?php
// Configuração básica
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

// Conectar ao banco
$conn = new mysqli($host, $user, $pass, $db);

// Verificar conexão
if ($conn->connect_error) {
    echo json_encode(['erro' => 'Erro de conexão: ' . $conn->connect_error]);
    exit;
}

// Pegar parâmetros
$tabela = $_REQUEST['tabela'] ?? '';
$acao = $_REQUEST['acao'] ?? '';

// Verificar se é a ação corrigida listar_por_treino
if ($acao === 'listar_por_treino') {
    $id_treino = intval($_REQUEST['id_treino'] ?? 0);
    
    if ($id_treino === 0) {
        echo json_encode(['erro' => 'id_treino obrigatório']);
        exit;
    }
    
    // Query simples e direta
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
    exit;
}

// Verificar parâmetros obrigatórios para outras ações
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
        if (!$result) {
            echo json_encode(['erro' => $conn->error]);
            break;
        }
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

        if ($id === 0 || empty($dados)) {
            echo json_encode(['erro' => 'ID e dados para atualizar são obrigatórios']);
            break;
        }

        $set = implode(',', array_map(function($k){ return esc($k) . '=?'; }, array_keys($dados)));
        $tipos = str_repeat('s', count($dados)) . 'i';
        $sql = "UPDATE `$tabela` SET $set WHERE id=?";
        $stmt = $conn->prepare($sql);

        if (!$stmt) {
            echo json_encode(['erro' => 'Erro no prepare: ' . $conn->error]);
            break;
        }

        $params = array_merge(array_values($dados), [$id]);
        $stmt->bind_param($tipos, ...$params);
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

    case 'login':
        $email = $_POST['email'] ?? '';
        $senha = $_POST['senha'] ?? '';
        $sql = "SELECT * FROM `$tabela` WHERE email=? AND password=?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('ss', $email, $senha);
        $stmt->execute();
        $res = $stmt->get_result();
        $user = $res->fetch_assoc();
        if ($user) {
            echo json_encode(['sucesso' => true, 'usuario_id' => $user['id']]);
        } else {
            echo json_encode(['sucesso' => false, 'erro' => 'E-mail ou senha inválidos.']);
        }
        break;

    case 'historico_usuario':
        $usuario_id = intval($_REQUEST['usuario_id'] ?? 0);
        if ($usuario_id === 0) {
            echo json_encode(['erro' => 'usuario_id obrigatório']);
            break;
        }
        $sql = "SELECT * FROM `$tabela` WHERE usuario_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('i', $usuario_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $dados = [];
        while ($row = $result->fetch_assoc()) {
            $dados[] = $row;
        }
        echo json_encode($dados);
        break;

    case 'treinos_usuario':
        $usuario_id = intval($_REQUEST['usuario_id'] ?? 0);
        if ($usuario_id === 0) {
            echo json_encode(['erro' => 'usuario_id obrigatório']);
            break;
        }
        $sql = "SELECT * FROM `$tabela` WHERE usuario_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('i', $usuario_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $dados = [];
        while ($row = $result->fetch_assoc()) {
            $dados[] = $row;
        }
        echo json_encode($dados);
        break;

    case 'listar_todos':
        $sql = "SELECT * FROM `$tabela`";
        $result = $conn->query($sql);
        $dados = [];
        while ($row = $result->fetch_assoc()) {
            $dados[] = $row;
        }
        echo json_encode($dados);
        break;

    case 'listar_treinos_usuario':
        $usuario_id = intval($_REQUEST['usuario_id'] ?? 0);
        if ($usuario_id === 0) {
            echo json_encode(['erro' => 'usuario_id obrigatório']);
            break;
        }
        $sql = "SELECT t.*, COUNT(e.id) as total_exercicios 
                FROM treinos t 
                LEFT JOIN exercicios e ON t.id = e.id_treino 
                WHERE t.usuario_id = ? 
                GROUP BY t.id";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            echo json_encode(['erro' => 'Erro no prepare: ' . $conn->error]);
            break;
        }
        $stmt->bind_param('i', $usuario_id);
        $stmt->execute();
        $result = $stmt->get_result();
        if (!$result) {
            echo json_encode(['erro' => 'Erro na consulta: ' . $stmt->error]);
            break;
        }
        $dados = [];
        while ($row = $result->fetch_assoc()) {
            $dados[] = $row;
        }
        echo json_encode($dados);
        break;

    default:
        echo json_encode(['erro' => 'Ação não reconhecida']);
}

$conn->close();
?>