<?php
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

// Buscar estatísticas
$stats = [];

try {
    // Total de usuários
    $result = $conn->query("SELECT COUNT(*) as total FROM usuarios");
    if ($result) {
        $stats['usuarios'] = $result->fetch_assoc()['total'];
    } else {
        $stats['usuarios'] = 0;
    }

    // Total de treinos
    $result = $conn->query("SELECT COUNT(*) as total FROM treinos");
    if ($result) {
        $stats['treinos'] = $result->fetch_assoc()['total'];
    } else {
        $stats['treinos'] = 0;
    }

    // Total de exercícios
    $result = $conn->query("SELECT COUNT(*) as total FROM exercicios");
    if ($result) {
        $stats['exercicios'] = $result->fetch_assoc()['total'];
    } else {
        $stats['exercicios'] = 0;
    }

    // Total de metas
    $result = $conn->query("SELECT COUNT(*) as total FROM metas");
    if ($result) {
        $stats['metas'] = $result->fetch_assoc()['total'];
    } else {
        $stats['metas'] = 0;
    }

    // Usuários por nível
    $check_column = $conn->query("SHOW COLUMNS FROM usuarios LIKE 'nivel'");
    if ($check_column->num_rows > 0) {
        $result = $conn->query("SELECT nivel, COUNT(*) as total FROM usuarios GROUP BY nivel");
        $usuarios_por_nivel = [];
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $usuarios_por_nivel[$row['nivel']] = $row['total'];
            }
        }
    } else {
        // Se a coluna nivel não existe, criar dados padrão
        $usuarios_por_nivel = [
            'ADMIN' => 1,
            'PROFISSIONAL' => 0,
            'USUARIO' => $stats['usuarios'] - 1
        ];
    }
} catch (Exception $e) {
    // Em caso de erro, usar valores padrão
    $stats = [
        'usuarios' => 0,
        'treinos' => 0,
        'exercicios' => 0,
        'metas' => 0
    ];
    $usuarios_por_nivel = [
        'ADMIN' => 0,
        'PROFISSIONAL' => 0,
        'USUARIO' => 0
    ];
}
?>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - AirFit Admin</title>
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
        .stats-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            border: none;
            transition: transform 0.3s;
        }
        .stats-card:hover {
            transform: translateY(-5px);
        }
        .stats-icon {
            width: 60px;
            height: 60px;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            color: white;
        }
        .bg-primary-gradient {
            background: linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%);
        }
        .bg-success-gradient {
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
        }
        .bg-warning-gradient {
            background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%);
        }
        .bg-info-gradient {
            background: linear-gradient(135deg, #06B6D4 0%, #0891B2 100%);
        }
        .navbar-brand {
            font-weight: 700;
            font-size: 1.5rem;
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
                        <a class="nav-link active" href="dashboard.php">
                            <i class="fas fa-tachometer-alt me-2"></i> Dashboard
                        </a>
                        <a class="nav-link" href="usuarios.php">
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
                        <span class="navbar-brand">Dashboard</span>
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
                    <div class="row mb-4">
                        <div class="col-12">
                            <h2 class="mb-3">Visão Geral</h2>
                            <p class="text-muted">Bem-vindo ao painel administrativo do AirFit</p>
                        </div>
                    </div>

                    <!-- Stats Cards -->
                    <div class="row mb-4">
                        <div class="col-md-3 mb-3">
                            <div class="card stats-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-primary-gradient me-3">
                                            <i class="fas fa-users"></i>
                                        </div>
                                        <div>
                                            <h3 class="mb-0"><?php echo $stats['usuarios']; ?></h3>
                                            <p class="text-muted mb-0">Usuários</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="col-md-3 mb-3">
                            <div class="card stats-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-success-gradient me-3">
                                            <i class="fas fa-dumbbell"></i>
                                        </div>
                                        <div>
                                            <h3 class="mb-0"><?php echo $stats['treinos']; ?></h3>
                                            <p class="text-muted mb-0">Treinos</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="col-md-3 mb-3">
                            <div class="card stats-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-warning-gradient me-3">
                                            <i class="fas fa-running"></i>
                                        </div>
                                        <div>
                                            <h3 class="mb-0"><?php echo $stats['exercicios']; ?></h3>
                                            <p class="text-muted mb-0">Exercícios</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="col-md-3 mb-3">
                            <div class="card stats-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-info-gradient me-3">
                                            <i class="fas fa-target"></i>
                                        </div>
                                        <div>
                                            <h3 class="mb-0"><?php echo $stats['metas']; ?></h3>
                                            <p class="text-muted mb-0">Metas</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Charts Row -->
                    <div class="row">
                        <div class="col-md-6 mb-4">
                            <div class="card">
                                <div class="card-header">
                                    <h5 class="card-title mb-0">
                                        <i class="fas fa-chart-pie me-2"></i>Usuários por Nível
                                    </h5>
                                </div>
                                <div class="card-body">
                                    <canvas id="usersChart" width="400" height="200"></canvas>
                                </div>
                            </div>
                        </div>
                        
                        <div class="col-md-6 mb-4">
                            <div class="card">
                                <div class="card-header">
                                    <h5 class="card-title mb-0">
                                        <i class="fas fa-chart-line me-2"></i>Atividade Recente
                                    </h5>
                                </div>
                                <div class="card-body">
                                    <p class="text-muted">Gráfico de atividade será implementado aqui</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        // Gráfico de usuários por nível
        const ctx = document.getElementById('usersChart').getContext('2d');
        new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['ADMIN', 'PROFISSIONAL', 'USUARIO'],
                datasets: [{
                    data: [
                        <?php echo $usuarios_por_nivel['ADMIN'] ?? 0; ?>,
                        <?php echo $usuarios_por_nivel['PROFISSIONAL'] ?? 0; ?>,
                        <?php echo $usuarios_por_nivel['USUARIO'] ?? 0; ?>
                    ],
                    backgroundColor: [
                        '#EF4444',
                        '#3B82F6',
                        '#10B981'
                    ],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    </script>
</body>
</html> 