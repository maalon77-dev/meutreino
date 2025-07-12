<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$conn = new mysqli("academia3322.mysql.dbaas.com.br", "academia3322", "vida1503A@", "academia3322");

if ($conn->connect_error) {
    die(json_encode(['sucesso' => false, 'erro' => 'Falha na conexão com o banco']));
}

$input = json_decode(file_get_contents('php://input'), true);
$acao = $input['acao'] ?? '';

if ($acao === 'login') {
    $email = $input['email'] ?? '';
    $senha = $input['senha'] ?? '';
    
    if (empty($email) || empty($senha)) {
        echo json_encode(['sucesso' => false, 'erro' => 'E-mail e senha são obrigatórios']);
        exit;
    }
    
    $stmt = $conn->prepare("SELECT id, nome, email FROM usuarios WHERE email = ? AND senha = ?");
    $stmt->bind_param("ss", $email, $senha);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $usuario = $result->fetch_assoc();
        echo json_encode([
            'sucesso' => true,
            'usuario_id' => $usuario['id'],
            'nome' => $usuario['nome'],
            'email' => $usuario['email']
        ]);
    } else {
        echo json_encode(['sucesso' => false, 'erro' => 'E-mail ou senha inválidos']);
    }
    
    $stmt->close();
} elseif ($acao === 'cadastro') {
    $nome = $input['nome'] ?? '';
    $email = $input['email'] ?? '';
    $senha = $input['senha'] ?? '';
    
    if (empty($nome) || empty($email) || empty($senha)) {
        echo json_encode(['sucesso' => false, 'erro' => 'Todos os campos são obrigatórios']);
        exit;
    }
    
    // Verificar se o e-mail já existe
    $stmt = $conn->prepare("SELECT id FROM usuarios WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        echo json_encode(['sucesso' => false, 'erro' => 'E-mail já cadastrado']);
        $stmt->close();
        exit;
    }
    $stmt->close();
    
    // Inserir novo usuário
    $stmt = $conn->prepare("INSERT INTO usuarios (nome, email, senha) VALUES (?, ?, ?)");
    $stmt->bind_param("sss", $nome, $email, $senha);
    
    if ($stmt->execute()) {
        $usuario_id = $conn->insert_id;
        echo json_encode([
            'sucesso' => true,
            'usuario_id' => $usuario_id,
            'mensagem' => 'Usuário cadastrado com sucesso'
        ]);
    } else {
        echo json_encode(['sucesso' => false, 'erro' => 'Erro ao cadastrar usuário']);
    }
    
    $stmt->close();
} else {
    echo json_encode(['sucesso' => false, 'erro' => 'Ação não reconhecida']);
}

$conn->close();
?>