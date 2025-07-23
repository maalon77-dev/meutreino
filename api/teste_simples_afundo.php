<?php
// Teste simples da API com termo "afundo"
echo "=== TESTE DA API COM 'AFUNDO' ===\n";

$termo = 'afundo';
$categoria = 'Alongamento';

$url = "https://airfit.online/api/buscar_exercicios_global.php?termo=$termo&categoria=$categoria";

echo "URL: $url\n\n";

$response = file_get_contents($url);
$data = json_decode($response, true);

echo "Status: " . (isset($data['erro']) ? 'ERRO' : 'SUCESSO') . "\n";
echo "Total de exercícios: " . ($data['total_exercicios'] ?? 'N/A') . "\n";
echo "Termo de busca: " . ($data['termo_busca'] ?? 'N/A') . "\n";
echo "Categoria: " . ($data['categoria'] ?? 'N/A') . "\n";
echo "Tabela buscada: " . ($data['tabela_buscada'] ?? 'N/A') . "\n";

if (isset($data['exercicios']) && count($data['exercicios']) > 0) {
    echo "\nExercícios encontrados:\n";
    foreach ($data['exercicios'] as $ex) {
        echo "- " . $ex['nome_do_exercicio'] . " (Categoria: " . $ex['categoria'] . ", Grupo: " . $ex['grupo'] . ")\n";
    }
} else {
    echo "\nNenhum exercício encontrado.\n";
}

if (isset($data['erro'])) {
    echo "\nERRO: " . $data['erro'] . "\n";
}

echo "\n=== TESTE SEM CATEGORIA ===\n";
$url2 = "https://airfit.online/api/buscar_exercicios_global.php?termo=$termo";
echo "URL: $url2\n\n";

$response2 = file_get_contents($url2);
$data2 = json_decode($response2, true);

echo "Status: " . (isset($data2['erro']) ? 'ERRO' : 'SUCESSO') . "\n";
echo "Total de exercícios: " . ($data2['total_exercicios'] ?? 'N/A') . "\n";

if (isset($data2['exercicios']) && count($data2['exercicios']) > 0) {
    echo "\nExercícios encontrados:\n";
    foreach ($data2['exercicios'] as $ex) {
        echo "- " . $ex['nome_do_exercicio'] . " (Categoria: " . $ex['categoria'] . ", Grupo: " . $ex['grupo'] . ")\n";
    }
} else {
    echo "\nNenhum exercício encontrado.\n";
}
?> 