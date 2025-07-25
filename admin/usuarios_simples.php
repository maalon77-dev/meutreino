<?php
// Ativar exibição de erros
error_reporting(E_ALL);
ini_set('display_errors', 1);

session_start();

// Verificar se está logado
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    header('Location: index.php');
    exit;
}

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8mb4");

$message = '';
$message_type = '';

// Buscar usuários de forma simples
try {
    $sql = "SELECT id, nome, email FROM usuarios ORDER BY nome LIMIT 10";
    $result = $conn->query($sql);
    
    if ($result) {
        $usuarios = $result->fetch_all(MYSQLI_ASSOC);
    } else {
        $usuarios = [];
        $message = 'Erro na consulta: ' . $conn->error;
        $message_type = 'danger';
    }
} catch (Exception $e) {
    $usuarios = [];
    $message = 'Erro: ' . $e->getMessage();
    $message_type = 'danger';
}
?>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Usuários Simples - AirFit Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-4">
        <h1>Usuários Simples</h1>
        
        <?php if ($message): ?>
            <div class="alert alert-<?php echo $message_type; ?>">
                <?php echo htmlspecialchars($message); ?>
            </div>
        <?php endif; ?>
        
        <div class="card">
            <div class="card-header">
                <h5>Lista de Usuários (<?php echo count($usuarios); ?>)</h5>
            </div>
            <div class="card-body">
                <?php if (count($usuarios) > 0): ?>
                    <table class="table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Nome</th>
                                <th>Email</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($usuarios as $usuario): ?>
                                <tr>
                                    <td><?php echo $usuario['id']; ?></td>
                                    <td><?php echo htmlspecialchars($usuario['nome']); ?></td>
                                    <td><?php echo htmlspecialchars($usuario['email']); ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php else: ?>
                    <p class="text-muted">Nenhum usuário encontrado.</p>
                <?php endif; ?>
            </div>
        </div>
        
        <div class="mt-3">
            <a href="dashboard.php" class="btn btn-primary">Voltar ao Dashboard</a>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html> 