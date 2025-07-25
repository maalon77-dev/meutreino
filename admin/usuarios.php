<?php
// Ativar exibição de erros e log
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', 'admin_error.log');

// Log de início
error_log("=== INÍCIO usuarios.php ===");

session_start();

// Verificar se está logado
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    error_log("Usuário não logado, redirecionando");
    header('Location: index.php');
    exit;
}

error_log("Usuário logado: " . $_SESSION['admin_nome']);

// Configurações do banco
$host = 'academia3322.mysql.dbaas.com.br';
$user = 'academia3322';
$pass = 'vida1503A@';
$db = 'academia3322';

error_log("Tentando conectar ao banco...");

$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8mb4");

if ($conn->connect_error) {
    error_log("Erro de conexão: " . $conn->connect_error);
    die("Erro de conexão: " . $conn->connect_error);
}

error_log("Conexão estabelecida com sucesso");

$message = '';
$message_type = '';

// Processar ações
if ($_POST) {
    $action = $_POST['action'] ?? '';
    
    if ($action === 'update_user') {
        error_log("Processando edição de usuário");
        
        $user_id = intval($_POST['user_id']);
        $nome = $_POST['nome'];
        $email = $_POST['email'];
        $nivel = $_POST['nivel'];
        $ativo = $_POST['ativo'];
        
        error_log("Dados recebidos - ID: $user_id, Nome: $nome, Email: $email, Nível: $nivel, Ativo: $ativo");
        
        // Verificar se as colunas existem
        $check_nivel = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
        $check_ativo = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'ativo'");
        
        error_log("Coluna nivel existe: " . ($check_nivel->num_rows > 0 ? 'SIM' : 'NÃO'));
        error_log("Coluna ativo existe: " . ($check_ativo->num_rows > 0 ? 'SIM' : 'NÃO'));
        
        if ($check_nivel->num_rows > 0 && $check_ativo->num_rows > 0) {
            $sql = "UPDATE usuarios SET nome = ?, email = ?, nivel = ?, ativo = ? WHERE id = ?";
            error_log("SQL: $sql");
            $stmt = $conn->prepare($sql);
            $stmt->bind_param('sssii', $nome, $email, $nivel, $ativo, $user_id);
        } elseif ($check_ativo->num_rows > 0) {
            $sql = "UPDATE usuarios SET nome = ?, email = ?, ativo = ? WHERE id = ?";
            error_log("SQL: $sql");
            $stmt = $conn->prepare($sql);
            $stmt->bind_param('ssii', $nome, $email, $ativo, $user_id);
        } else {
            $sql = "UPDATE usuarios SET nome = ?, email = ? WHERE id = ?";
            error_log("SQL: $sql");
            $stmt = $conn->prepare($sql);
            $stmt->bind_param('ssi', $nome, $email, $user_id);
        }
        
        if ($stmt && $stmt->execute()) {
            error_log("Usuário atualizado com sucesso");
            $message = 'Usuário atualizado com sucesso!';
            $message_type = 'success';
        } else {
            error_log("Erro ao atualizar usuário: " . $conn->error);
            $message = 'Erro ao atualizar usuário: ' . $conn->error;
            $message_type = 'danger';
        }
    } elseif ($action === 'delete_user') {
        $user_id = intval($_POST['user_id']);
        
        $stmt = $conn->prepare("DELETE FROM usuarios WHERE id = ?");
        $stmt->bind_param('i', $user_id);
        
        if ($stmt->execute()) {
            $message = 'Usuário excluído com sucesso!';
            $message_type = 'success';
        } else {
            $message = 'Erro ao excluir usuário: ' . $conn->error;
            $message_type = 'danger';
        }
    } elseif ($action === 'create_user') {
        $nome = $_POST['nome'];
        $email = $_POST['email'];
        $username = $_POST['username'];
        $password = $_POST['password'];
        $nivel = $_POST['nivel'];
        $telefone = $_POST['telefone'] ?? '';
        $sexo = $_POST['sexo'] ?? '';
        $idade = $_POST['idade'] ?? '';
        $peso = $_POST['peso'] ?? '';
        $altura = $_POST['altura'] ?? '';
        $meta_peso = $_POST['meta_peso'] ?? '';
        $criado_por = $_SESSION['admin_id'];
        
        // Verificar se email já existe
        $check_stmt = $conn->prepare("SELECT id FROM usuarios WHERE email = ?");
        $check_stmt->bind_param('s', $email);
        $check_stmt->execute();
        
        if ($check_stmt->get_result()->num_rows > 0) {
            $message = 'Email já cadastrado no sistema!';
            $message_type = 'danger';
        } else {
            // Verificar se as colunas existem
            $check_nivel = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
            $check_criado_por = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'criado_por'");
            $check_ativo = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'ativo'");
            $check_data_cadastro = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'data_cadastro'");
            
            if ($check_nivel->num_rows > 0 && $check_criado_por->num_rows > 0 && $check_ativo->num_rows > 0 && $check_data_cadastro->num_rows > 0) {
                // Todas as colunas existem
                $stmt = $conn->prepare("INSERT INTO usuarios (nome, email, username, password, nivel, telefone, sexo, idade, peso, altura, meta_peso, criado_por, ativo, data_cadastro) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, NOW())");
                $stmt->bind_param('sssssssssssi', $nome, $email, $username, $password, $nivel, $telefone, $sexo, $idade, $peso, $altura, $meta_peso, $criado_por);
            } elseif ($check_nivel->num_rows > 0 && $check_ativo->num_rows > 0 && $check_data_cadastro->num_rows > 0) {
                // Apenas nivel, ativo e data_cadastro existem
                $stmt = $conn->prepare("INSERT INTO usuarios (nome, email, username, password, nivel, telefone, sexo, idade, peso, altura, meta_peso, ativo, data_cadastro) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, NOW())");
                $stmt->bind_param('sssssssssss', $nome, $email, $username, $password, $nivel, $telefone, $sexo, $idade, $peso, $altura, $meta_peso);
            } elseif ($check_ativo->num_rows > 0 && $check_data_cadastro->num_rows > 0) {
                // Apenas ativo e data_cadastro existem
                $stmt = $conn->prepare("INSERT INTO usuarios (nome, email, username, password, telefone, sexo, idade, peso, altura, meta_peso, ativo, data_cadastro) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, NOW())");
                $stmt->bind_param('ssssssssss', $nome, $email, $username, $password, $telefone, $sexo, $idade, $peso, $altura, $meta_peso);
            } else {
                // Apenas colunas básicas existem
                $stmt = $conn->prepare("INSERT INTO usuarios (nome, email, username, password, telefone, sexo, idade, peso, altura, meta_peso) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                $stmt->bind_param('ssssssssss', $nome, $email, $username, $password, $telefone, $sexo, $idade, $peso, $altura, $meta_peso);
            }
            
            if ($stmt && $stmt->execute()) {
                $message = 'Usuário criado com sucesso!';
                $message_type = 'success';
            } else {
                $message = 'Erro ao criar usuário: ' . $conn->error;
                $message_type = 'danger';
            }
        }
    }
}

// Buscar usuários
$search = $_GET['search'] ?? '';
$nivel_filter = $_GET['nivel'] ?? '';

$where_conditions = [];
$params = [];
$types = '';

if ($search) {
    $where_conditions[] = "(nome LIKE ? OR email LIKE ?)";
    $search_param = "%$search%";
    $params[] = $search_param;
    $params[] = $search_param;
    $types .= 'ss';
}

if ($nivel_filter) {
    // Verificar se a coluna nivel existe antes de filtrar
    $check_nivel = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
    if ($check_nivel->num_rows > 0) {
        $where_conditions[] = "nivel = ?";
        $params[] = $nivel_filter;
        $types .= 's';
    }
}

$where_clause = '';
if (!empty($where_conditions)) {
    $where_clause = 'WHERE ' . implode(' AND ', $where_conditions);
}

error_log("Verificando colunas...");

// Verificar se as colunas existem
$check_nivel = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
$check_criado_por = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'criado_por'");
$check_ativo = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'ativo'");
$check_data_cadastro = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'data_cadastro'");

error_log("Coluna nivel existe: " . ($check_nivel->num_rows > 0 ? 'SIM' : 'NÃO'));
error_log("Coluna criado_por existe: " . ($check_criado_por->num_rows > 0 ? 'SIM' : 'NÃO'));
error_log("Coluna ativo existe: " . ($check_ativo->num_rows > 0 ? 'SIM' : 'NÃO'));
error_log("Coluna data_cadastro existe: " . ($check_data_cadastro->num_rows > 0 ? 'SIM' : 'NÃO'));

if ($check_nivel->num_rows > 0 && $check_criado_por->num_rows > 0 && $check_ativo->num_rows > 0 && $check_data_cadastro->num_rows > 0) {
    // Todas as colunas existem
    $sql = "SELECT u.id, u.nome, u.email, u.nivel, u.ativo, u.data_cadastro, u.criado_por, c.nome as criador_nome 
            FROM usuarios u 
            LEFT JOIN usuarios c ON u.criado_por = c.id 
            $where_clause 
            ORDER BY u.nome";
    error_log("Usando query com JOIN completo");
} elseif ($check_nivel->num_rows > 0 && $check_ativo->num_rows > 0 && $check_data_cadastro->num_rows > 0) {
    // Apenas nivel, ativo e data_cadastro existem
    $sql = "SELECT id, nome, email, nivel, ativo, data_cadastro, NULL as criado_por, NULL as criador_nome 
            FROM usuarios 
            $where_clause 
            ORDER BY nome";
    error_log("Usando query sem criado_por");
} elseif ($check_ativo->num_rows > 0 && $check_data_cadastro->num_rows > 0) {
    // Apenas ativo e data_cadastro existem
    $sql = "SELECT id, nome, email, 'USUARIO' as nivel, ativo, data_cadastro, NULL as criado_por, NULL as criador_nome 
            FROM usuarios 
            $where_clause 
            ORDER BY nome";
    error_log("Usando query sem nivel");
} else {
    // Apenas colunas básicas existem
    $sql = "SELECT id, nome, email, 'USUARIO' as nivel, 1 as ativo, NOW() as data_cadastro, NULL as criado_por, NULL as criador_nome 
            FROM usuarios 
            $where_clause 
            ORDER BY nome";
    error_log("Usando query básica");
}

error_log("SQL gerado: " . $sql);

error_log("Preparando statement...");
$stmt = $conn->prepare($sql);

if (!$stmt) {
    error_log("Erro ao preparar statement: " . $conn->error);
    $usuarios = [];
    $message = 'Erro na consulta: ' . $conn->error;
    $message_type = 'danger';
} else {
    error_log("Statement preparado com sucesso");
    
    if (!empty($params)) {
        error_log("Fazendo bind de " . count($params) . " parâmetros");
        $bind_result = $stmt->bind_param($types, ...$params);
        if (!$bind_result) {
            error_log("Erro ao fazer bind dos parâmetros");
        }
    }
    
    error_log("Executando query...");
    $execute_result = $stmt->execute();
    if (!$execute_result) {
        error_log("Erro ao executar query: " . $stmt->error);
        $usuarios = [];
        $message = 'Erro na consulta: ' . $stmt->error;
        $message_type = 'danger';
    } else {
        error_log("Query executada com sucesso");
        $result = $stmt->get_result();
        $usuarios = $result->fetch_all(MYSQLI_ASSOC);
        error_log("Dados obtidos: " . count($usuarios) . " usuários");
    }
}
?>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gerenciar Usuários - AirFit Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .sidebar {
            background: linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%);
            min-height: 100vh;
            color: white;
        }
        .sidebar .nav-link {
            color: rgba(255,255,255,0.8);
            padding: 12px 20px;
            border-radius: 8px;
            margin: 2px 0;
            transition: all 0.3s;
        }
        .sidebar .nav-link:hover,
        .sidebar .nav-link.active {
            color: white;
            background-color: rgba(255,255,255,0.1);
        }
        .main-content {
            padding: 30px;
        }
        .card {
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            border: none;
        }
        .navbar-brand {
            font-weight: 700;
            font-size: 1.5rem;
        }
        .badge-admin {
            background: linear-gradient(135deg, #EF4444 0%, #DC2626 100%);
        }
        .badge-profissional {
            background: linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%);
        }
        .badge-usuario {
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
        }
        .table th {
            border-top: none;
            font-weight: 600;
            color: #374151;
        }
        .btn-action {
            padding: 6px 12px;
            border-radius: 8px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container-fluid">
        <div class="row">
            <!-- Sidebar -->
            <div class="col-md-3 col-lg-2 px-0">
                <div class="sidebar p-3">
                    <div class="text-center mb-4">
                        <i class="fas fa-dumbbell fa-2x mb-2"></i>
                        <h5>AirFit Admin</h5>
                        <small>Painel Administrativo</small>
                    </div>
                    
                    <nav class="nav flex-column">
                        <a class="nav-link" href="dashboard.php">
                            <i class="fas fa-tachometer-alt me-2"></i> Dashboard
                        </a>
                        <a class="nav-link active" href="usuarios.php">
                            <i class="fas fa-users me-2"></i> Usuários
                        </a>
                        <a class="nav-link" href="treinos.php">
                            <i class="fas fa-dumbbell me-2"></i> Treinos
                        </a>
                        <a class="nav-link" href="exercicios.php">
                            <i class="fas fa-running me-2"></i> Exercícios
                        </a>
                        <a class="nav-link" href="metas.php">
                            <i class="fas fa-target me-2"></i> Metas
                        </a>
                        <a class="nav-link" href="relatorios.php">
                            <i class="fas fa-chart-bar me-2"></i> Relatórios
                        </a>
                        <a class="nav-link" href="configuracoes.php">
                            <i class="fas fa-cog me-2"></i> Configurações
                        </a>
                        <hr class="my-3">
                        <a class="nav-link" href="logout.php">
                            <i class="fas fa-sign-out-alt me-2"></i> Sair
                        </a>
                    </nav>
                </div>
            </div>

            <!-- Main Content -->
            <div class="col-md-9 col-lg-10">
                <!-- Navbar -->
                <nav class="navbar navbar-expand-lg navbar-light bg-white shadow-sm">
                    <div class="container-fluid">
                        <span class="navbar-brand">Gerenciar Usuários</span>
                        <div class="navbar-nav ms-auto">
                            <div class="nav-item dropdown">
                                <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown">
                                    <i class="fas fa-user-circle me-1"></i>
                                    <?php echo htmlspecialchars($_SESSION['admin_nome']); ?>
                                    <span class="badge bg-primary ms-1"><?php echo $_SESSION['admin_nivel']; ?></span>
                                </a>
                                <ul class="dropdown-menu">
                                    <li><a class="dropdown-item" href="perfil.php"><i class="fas fa-user me-2"></i>Perfil</a></li>
                                    <li><hr class="dropdown-divider"></li>
                                    <li><a class="dropdown-item" href="logout.php"><i class="fas fa-sign-out-alt me-2"></i>Sair</a></li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </nav>

                <div class="main-content">
                    <?php if ($message): ?>
                        <div class="alert alert-<?php echo $message_type; ?> alert-dismissible fade show" role="alert">
                            <i class="fas fa-<?php echo $message_type === 'success' ? 'check-circle' : 'exclamation-triangle'; ?> me-2"></i>
                            <?php echo htmlspecialchars($message); ?>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <?php endif; ?>

                    <!-- Filtros -->
                    <div class="card mb-4">
                        <div class="card-body">
                            <form method="GET" class="row g-3">
                                <div class="col-md-4">
                                    <label for="search" class="form-label">Buscar</label>
                                    <input type="text" class="form-control" id="search" name="search" 
                                           value="<?php echo htmlspecialchars($search); ?>" 
                                           placeholder="Nome ou email...">
                                </div>
                                <div class="col-md-3">
                                    <label for="nivel" class="form-label">Nível</label>
                                    <select class="form-select" id="nivel" name="nivel">
                                        <option value="">Todos os níveis</option>
                                        <option value="ADMIN" <?php echo $nivel_filter === 'ADMIN' ? 'selected' : ''; ?>>Admin</option>
                                        <option value="PROFISSIONAL" <?php echo $nivel_filter === 'PROFISSIONAL' ? 'selected' : ''; ?>>Profissional</option>
                                        <option value="USUARIO" <?php echo $nivel_filter === 'USUARIO' ? 'selected' : ''; ?>>Usuário</option>
                                    </select>
                                </div>
                                <div class="col-md-2">
                                    <label class="form-label">&nbsp;</label>
                                    <button type="submit" class="btn btn-primary w-100">
                                        <i class="fas fa-search me-1"></i> Filtrar
                                    </button>
                                </div>
                                <div class="col-md-2">
                                    <label class="form-label">&nbsp;</label>
                                    <a href="usuarios.php" class="btn btn-outline-secondary w-100">
                                        <i class="fas fa-times me-1"></i> Limpar
                                    </a>
                                </div>
                            </form>
                        </div>
                    </div>

                    <!-- Tabela de Usuários -->
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h5 class="card-title mb-0">
                                <i class="fas fa-users me-2"></i>Usuários (<?php echo count($usuarios); ?>)
                            </h5>
                            <?php if ($_SESSION['admin_nivel'] === 'ADMIN' || $_SESSION['admin_nivel'] === 'PROFISSIONAL'): ?>
                                <button class="btn btn-primary" onclick="showCreateUserModal()">
                                    <i class="fas fa-plus me-1"></i>Criar Usuário
                                </button>
                            <?php endif; ?>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th>ID</th>
                                            <th>Nome</th>
                                            <th>Email</th>
                                            <th>Nível</th>
                                            <th>Status</th>
                                            <th>Criado Por</th>
                                            <th>Data Cadastro</th>
                                            <th>Ações</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php foreach ($usuarios as $usuario): ?>
                                            <tr>
                                                <td><?php echo $usuario['id']; ?></td>
                                                <td>
                                                    <strong><?php echo htmlspecialchars($usuario['nome']); ?></strong>
                                                </td>
                                                <td><?php echo htmlspecialchars($usuario['email']); ?></td>
                                                <td>
                                                    <?php
                                                    $badge_class = '';
                                                    switch ($usuario['nivel']) {
                                                        case 'ADMIN':
                                                            $badge_class = 'badge-admin';
                                                            break;
                                                        case 'PROFISSIONAL':
                                                            $badge_class = 'badge-profissional';
                                                            break;
                                                        case 'USUARIO':
                                                            $badge_class = 'badge-usuario';
                                                            break;
                                                    }
                                                    ?>
                                                    <span class="badge <?php echo $badge_class; ?> text-white">
                                                        <?php echo $usuario['nivel']; ?>
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
                                                    <?php if ($usuario['criador_nome']): ?>
                                                        <span class="badge bg-info"><?php echo htmlspecialchars($usuario['criador_nome']); ?></span>
                                                    <?php else: ?>
                                                        <span class="text-muted">Sistema</span>
                                                    <?php endif; ?>
                                                </td>
                                                <td><?php echo date('d/m/Y H:i', strtotime($usuario['data_cadastro'])); ?></td>
                                                <td>
                                                    <button class="btn btn-sm btn-outline-primary btn-action" 
                                                            onclick="editUser({
                                                                id: <?php echo $usuario['id']; ?>,
                                                                nome: '<?php echo addslashes($usuario['nome']); ?>',
                                                                email: '<?php echo addslashes($usuario['email']); ?>',
                                                                nivel: '<?php echo $usuario['nivel'] ?? 'USUARIO'; ?>',
                                                                ativo: '<?php echo $usuario['ativo'] ?? '1'; ?>'
                                                            })">
                                                        <i class="fas fa-edit"></i>
                                                    </button>
                                                    <?php if ($usuario['id'] != $_SESSION['admin_id']): ?>
                                                        <button class="btn btn-sm btn-outline-danger btn-action" 
                                                                onclick="deleteUser(<?php echo $usuario['id']; ?>, '<?php echo htmlspecialchars($usuario['nome']); ?>')">
                                                            <i class="fas fa-trash"></i>
                                                        </button>
                                                    <?php endif; ?>
                                                </td>
                                            </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
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
                                <?php if ($_SESSION['admin_nivel'] === 'ADMIN'): ?>
                                    <option value="ADMIN">Admin</option>
                                    <option value="PROFISSIONAL">Profissional</option>
                                <?php endif; ?>
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

    <!-- Modal Confirmar Exclusão -->
    <div class="modal fade" id="deleteUserModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title text-danger">
                        <i class="fas fa-exclamation-triangle me-2"></i>Confirmar Exclusão
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p>Tem certeza que deseja excluir o usuário <strong id="delete_user_name"></strong>?</p>
                    <p class="text-muted">Esta ação não pode ser desfeita.</p>
                </div>
                <form method="POST">
                    <input type="hidden" name="action" value="delete_user">
                    <input type="hidden" name="user_id" id="delete_user_id">
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-danger">
                            <i class="fas fa-trash me-1"></i>Excluir
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Modal Criar Usuário -->
    <div class="modal fade" id="createUserModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-user-plus me-2"></i>Criar Novo Usuário
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="create_user">
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="create_nome" class="form-label">Nome Completo *</label>
                                    <input type="text" class="form-control" id="create_nome" name="nome" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="create_email" class="form-label">Email *</label>
                                    <input type="email" class="form-control" id="create_email" name="email" required>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="create_username" class="form-label">Username *</label>
                                    <input type="text" class="form-control" id="create_username" name="username" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="create_password" class="form-label">Senha *</label>
                                    <input type="password" class="form-control" id="create_password" name="password" required>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="create_nivel" class="form-label">Nível *</label>
                                    <select class="form-select" id="create_nivel" name="nivel" required>
                                        <option value="">Selecione...</option>
                                        <?php if ($_SESSION['admin_nivel'] === 'ADMIN'): ?>
                                            <option value="ADMIN">Admin</option>
                                            <option value="PROFISSIONAL">Profissional</option>
                                        <?php endif; ?>
                                        <option value="USUARIO">Usuário</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="create_telefone" class="form-label">Telefone</label>
                                    <input type="text" class="form-control" id="create_telefone" name="telefone">
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-4">
                                <div class="mb-3">
                                    <label for="create_sexo" class="form-label">Sexo</label>
                                    <select class="form-select" id="create_sexo" name="sexo">
                                        <option value="">Selecione...</option>
                                        <option value="masculino">Masculino</option>
                                        <option value="feminino">Feminino</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="mb-3">
                                    <label for="create_idade" class="form-label">Idade</label>
                                    <input type="number" class="form-control" id="create_idade" name="idade" min="1" max="120">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="mb-3">
                                    <label for="create_peso" class="form-label">Peso (kg)</label>
                                    <input type="number" class="form-control" id="create_peso" name="peso" step="0.1" min="0">
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="create_altura" class="form-label">Altura (cm)</label>
                                    <input type="number" class="form-control" id="create_altura" name="altura" min="0">
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="create_meta_peso" class="form-label">Meta de Peso (kg)</label>
                                    <input type="number" class="form-control" id="create_meta_peso" name="meta_peso" step="0.1" min="0">
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save me-1"></i>Criar Usuário
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
            document.getElementById('edit_nome').value = user.nome || '';
            document.getElementById('edit_email').value = user.email || '';
            document.getElementById('edit_nivel').value = user.nivel || 'USUARIO';
            document.getElementById('edit_ativo').value = user.ativo || '1';
            
            new bootstrap.Modal(document.getElementById('editUserModal')).show();
        }
        
        function deleteUser(userId, userName) {
            document.getElementById('delete_user_id').value = userId;
            document.getElementById('delete_user_name').textContent = userName;
            
            new bootstrap.Modal(document.getElementById('deleteUserModal')).show();
        }
        
        function showCreateUserModal() {
            new bootstrap.Modal(document.getElementById('createUserModal')).show();
        }
    </script>
</body>
</html> 