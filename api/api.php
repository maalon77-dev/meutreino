<?php
// Headers básicos
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Resto da API (código original)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

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

// Verificar parâmetros obrigatórios
if (!$acao) {
    echo json_encode(['erro' => 'Ação é obrigatória']);
    exit;
}

// Função para escapar campos
function esc($str) {
    return htmlspecialchars($str, ENT_QUOTES, 'UTF-8');
}

switch ($acao) {
    case 'listar_por_treino':
        $id_treino = intval($_REQUEST['id_treino'] ?? 0);
        if ($id_treino === 0) {
            echo json_encode(['erro' => 'id_treino obrigatório']);
            break;
        }
        $sql = "SELECT * FROM exercicios WHERE id_treino = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            echo json_encode(['erro' => 'Erro no prepare: ' . $conn->error]);
            break;
        }
        $stmt->bind_param('i', $id_treino);
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

    case 'listar':
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
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
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
        $id = intval($_REQUEST['id'] ?? 0);
        $sql = "SELECT * FROM `$tabela` WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('i', $id);
        $stmt->execute();
        $res = $stmt->get_result();
        echo json_encode($res->fetch_assoc());
        break;

    case 'inserir':
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
        
        try {
            $dados = $_POST;
            unset($dados['tabela'], $dados['acao']);
            
            if (empty($dados)) {
                echo json_encode(['erro' => 'Nenhum dado fornecido para inserção']);
                break;
            }
            
            // Validar e limpar os nomes dos campos
            $campos_validos = [];
            $valores = [];
            $tipos = '';
            
            foreach ($dados as $campo => $valor) {
                // Validar se o nome do campo é seguro
                if (preg_match('/^[a-zA-Z_][a-zA-Z0-9_]*$/', $campo)) {
                    $campos_validos[] = "`$campo`";
                    $valores[] = $valor;
                    $tipos .= 's';
                }
            }
            
            if (empty($campos_validos)) {
                echo json_encode(['erro' => 'Nenhum campo válido encontrado']);
                break;
            }
            
            $campos_str = implode(',', $campos_validos);
            $placeholders = implode(',', array_fill(0, count($valores), '?'));
            
            $sql = "INSERT INTO `$tabela` ($campos_str) VALUES ($placeholders)";
            
            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                echo json_encode(['erro' => 'Erro no prepare: ' . $conn->error]);
                break;
            }
            
            $stmt->bind_param($tipos, ...$valores);
            $ok = $stmt->execute();
            
            if ($ok) {
                echo json_encode(['sucesso' => true, 'id' => $conn->insert_id]);
            } else {
                echo json_encode(['erro' => 'Erro ao executar query: ' . $stmt->error]);
            }
            
        } catch (Exception $e) {
            echo json_encode(['erro' => 'Erro interno: ' . $e->getMessage()]);
        }
        break;

    case 'atualizar':
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
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
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
        $id = intval($_REQUEST['id'] ?? 0);
        $sql = "DELETE FROM `$tabela` WHERE id=?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('i', $id);
        $ok = $stmt->execute();
        echo json_encode(['sucesso' => $ok]);
        break;

    case 'login':
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
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
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
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
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
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
        if (!$tabela) {
            echo json_encode(['erro' => 'Tabela é obrigatória']);
            break;
        }
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

    case 'historico_treino_especifico':
        $usuario_id = intval($_REQUEST['usuario_id'] ?? 0);
        $treino_id = intval($_REQUEST['treino_id'] ?? 0);
        
        if ($usuario_id === 0) {
            echo json_encode(['erro' => 'usuario_id é obrigatório']);
            break;
        }
        
        // Se não foi especificado um treino_id, buscar todos os treinos do usuário
        if ($treino_id === 0) {
            // Buscar todos os treinos do usuário na tabela historico_treinos
            $sql_historico = "SELECT * FROM historico_treinos WHERE usuario_id = ? ORDER BY data_treino DESC";
            $stmt_historico = $conn->prepare($sql_historico);
            $stmt_historico->bind_param('i', $usuario_id);
            $stmt_historico->execute();
            $result_historico = $stmt_historico->get_result();
            
            $historico = [];
            while ($row = $result_historico->fetch_assoc()) {
                $historico[] = $row;
            }
            
            $resultado = [
                'historico' => $historico
            ];
            
            echo json_encode($resultado);
            break;
        }
        
        // Se foi especificado um treino_id, buscar histórico específico
        // Primeiro, buscar o nome do treino
        $sql_treino = "SELECT nome_treino FROM treinos WHERE id = ?";
        $stmt_treino = $conn->prepare($sql_treino);
        $stmt_treino->bind_param('i', $treino_id);
        $stmt_treino->execute();
        $result_treino = $stmt_treino->get_result();
        $treino = $result_treino->fetch_assoc();
        
        if (!$treino) {
            echo json_encode([
                'total_vezes' => 0,
                'ultima_vez' => null,
                'nome_treino' => null,
                'mensagem' => 'Treino não encontrado'
            ]);
            break;
        }
        
        $nome_treino = $treino['nome_treino'];
        
        // Buscar histórico na tabela historico_treinos
        $sql_historico = "SELECT * FROM historico_treinos WHERE usuario_id = ? AND nome_treino = ? ORDER BY data_treino DESC";
        $stmt_historico = $conn->prepare($sql_historico);
        $stmt_historico->bind_param('is', $usuario_id, $nome_treino);
        $stmt_historico->execute();
        $result_historico = $stmt_historico->get_result();
        
        $historico = [];
        while ($row = $result_historico->fetch_assoc()) {
            $historico[] = $row;
        }
        
        $total_vezes = count($historico);
        $ultima_vez = null;
        
        if ($total_vezes > 0) {
            $ultima_vez = $historico[0]['data_treino'];
        }
        
        $resultado = [
            'total_vezes' => $total_vezes,
            'ultima_vez' => $ultima_vez,
            'nome_treino' => $nome_treino,
            'historico' => $historico
        ];
        
        echo json_encode($resultado);
        break;

    default:
        echo json_encode(['erro' => 'Ação não reconhecida']);
}

$conn->close();
?>