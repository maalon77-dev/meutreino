<?php
// Ativar exibição de erros
error_reporting(E_ALL);
ini_set('display_errors', 1);

session_start();

// Simular session de admin
$_SESSION['admin_logged_in'] = true;
$_SESSION['admin_id'] = 1;
$_SESSION['admin_nome'] = 'Teste';
$_SESSION['admin_nivel'] = 'ADMIN';

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8mb4");

$message = '';
$message_type = '';

// Processar edição se POST
if ($_POST && isset($_POST['action']) && $_POST['action'] === 'update_user') {
    echo "<h3>🔄 Processando Edição:</h3>";
    
    $user_id = intval($_POST['user_id']);
    $nome = $_POST['nome'];
    $email = $_POST['email'];
    $nivel = $_POST['nivel'];
    $ativo = $_POST['ativo'];
    
    echo "ID: $user_id<br>";
    echo "Nome: $nome<br>";
    echo "Email: $email<br>";
    echo "Nível: $nivel<br>";
    echo "Ativo: $ativo<br><br>";
    
    // Verificar se as colunas existem
    $check_nivel = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
    $check_ativo = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'ativo'");
    
    echo "Coluna nivel existe: " . ($check_nivel->num_rows > 0 ? 'SIM' : 'NÃO') . "<br>";
    echo "Coluna ativo existe: " . ($check_ativo->num_rows > 0 ? 'SIM' : 'NÃO') . "<br><br>";
    
    if ($check_nivel->num_rows > 0 && $check_ativo->num_rows > 0) {
        $sql = "UPDATE usuarios SET nome = ?, email = ?, nivel = ?, ativo = ? WHERE id = ?";
        echo "SQL: $sql<br>";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('sssii', $nome, $email, $nivel, $ativo, $user_id);
    } elseif ($check_ativo->num_rows > 0) {
        $sql = "UPDATE usuarios SET nome = ?, email = ?, ativo = ? WHERE id = ?";
        echo "SQL: $sql<br>";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('ssii', $nome, $email, $ativo, $user_id);
    } else {
        $sql = "UPDATE usuarios SET nome = ?, email = ? WHERE id = ?";
        echo "SQL: $sql<br>";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('ssi', $nome, $email, $user_id);
    }
    
    if ($stmt && $stmt->execute()) {
        echo "✅ Usuário atualizado com sucesso!<br>";
        $message = 'Usuário atualizado com sucesso!';
        $message_type = 'success';
    } else {
        echo "❌ Erro ao atualizar usuário: " . $conn->error . "<br>";
        $message = 'Erro ao atualizar usuário: ' . $conn->error;
        $message_type = 'danger';
    }
}

// Buscar usuários
$sql = "SELECT id, nome, email, nivel, ativo FROM usuarios ORDER BY nome LIMIT 5";
$result = $conn->query($sql);
$usuarios = $result->fetch_all(MYSQLI_ASSOC);
?>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teste de Edição - AirFit Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-4">
        <h1>Teste de Edição de Usuários</h1>
        
        <?php if ($message): ?>
            <div class="alert alert-<?php echo $message_type; ?>">
                <?php echo htmlspecialchars($message); ?>
            </div>
        <?php endif; ?>
        
        <div class="card">
            <div class="card-header">
                <h5>Usuários para Teste</h5>
            </div>
            <div class="card-body">
                <?php if (count($usuarios) > 0): ?>
                    <table class="table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Nome</th>
                                <th>Email</th>
                                <th>Nível</th>
                                <th>Status</th>
                                <th>Ações</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($usuarios as $usuario): ?>
                                <tr>
                                    <td><?php echo $usuario['id']; ?></td>
                                    <td><?php echo htmlspecialchars($usuario['nome']); ?></td>
                                    <td><?php echo htmlspecialchars($usuario['email']); ?></td>
                                    <td>
                                        <span class="badge bg-primary">
                                            <?php echo $usuario['nivel'] ?? 'N/A'; ?>
                                        </span>
                                    </td>
                                    <td>
                                        <?php if ($usuario['ativo']): ?>
                                            <span class="badge bg-success">Ativo</span>
                                        <?php else: ?>
                                            <span class="badge bg-danger">Inativo</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <button class="btn btn-sm btn-outline-primary" 
                                                onclick="editUser(<?php echo htmlspecialchars(json_encode($usuario)); ?>)">
                                            <i class="fas fa-edit"></i> Editar
                                        </button>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php else: ?>
                    <p class="text-muted">Nenhum usuário encontrado.</p>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <!-- Modal Editar Usuário -->
    <div class="modal fade" id="editUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-edit me-2"></i>Editar Usuário
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="update_user">
                        <input type="hidden" name="user_id" id="edit_user_id">
                        
                        <div class="mb-3">
                            <label for="edit_nome" class="form-label">Nome</label>
                            <input type="text" class="form-control" id="edit_nome" name="nome" required>
                        </div>
                        
                        <div class="mb-3">
                            <label for="edit_email" class="form-label">Email</label>
                            <input type="email" class="form-control" id="edit_email" name="email" required>
                        </div>
                        
                        <div class="mb-3">
                            <label for="edit_nivel" class="form-label">Nível</label>
                            <select class="form-select" id="edit_nivel" name="nivel" required>
                                <option value="ADMIN">Admin</option>
                                <option value="PROFISSIONAL">Profissional</option>
                                <option value="USUARIO">Usuário</option>
                            </select>
                        </div>
                        
                        <div class="mb-3">
                            <label for="edit_ativo" class="form-label">Status</label>
                            <select class="form-select" id="edit_ativo" name="ativo" required>
                                <option value="1">Ativo</option>
                                <option value="0">Inativo</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save me-1"></i>Salvar
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function editUser(user) {
            console.log('Editando usuário:', user);
            
            document.getElementById('edit_user_id').value = user.id;
            document.getElementById('edit_nome').value = user.nome;
            document.getElementById('edit_email').value = user.email;
            document.getElementById('edit_nivel').value = user.nivel || 'USUARIO';
            document.getElementById('edit_ativo').value = user.ativo || '1';
            
            new bootstrap.Modal(document.getElementById('editUserModal')).show();
        }
    </script>
</body>
</html> 