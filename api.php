<?php
header("Content-Type: application/json");

$input = json_decode(file_get_contents("php://input"), true);
$license = $input['license'] ?? '';
$ip = $input['ip'] ?? '';

// Log the received data
file_put_contents("debug.txt", "Received: License=$license, IP=$ip\n", FILE_APPEND);

try {
    $pdo = new PDO('mysql:host=localhost;dbname=iplock;charset=utf8', 'root', ''); ## YOUR SQL CONNEXION
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $pdo->prepare("SELECT * FROM licenses WHERE license = ?");
    $stmt->execute([$license]);
    $row = $stmt->fetch();

    if ($row) {
        if (empty($row['ip'])) {
            // If IP is missing, assign it
            $update = $pdo->prepare("UPDATE licenses SET ip = ? WHERE license = ?");
            $update->execute([$ip, $license]);
            echo json_encode(["status" => "OK", "message" => "IP successfully assigned to the license."]);
            file_put_contents("debug.txt", "IP assigned to the license: $license\n", FILE_APPEND);
        } elseif ($row['ip'] !== $ip) {
            // IP mismatch, notify the user
            echo json_encode(["status" => "KO", "message" => "IP mismatch detected. Please contact the administrator to change the IP."]);
            file_put_contents("debug.txt", "IP mismatch: License $license, Current IP: " . $row['ip'] . " - New IP: $ip\n", FILE_APPEND);
        } else {
            // IP is correct
            echo json_encode(["status" => "OK", "message" => "License and IP are valid."]);
            file_put_contents("debug.txt", "License $license is valid with correct IP.\n", FILE_APPEND);
        }
    } else {
        // If the license doesn't exist, insert it with the IP
        $insert = $pdo->prepare("INSERT INTO licenses (license, ip) VALUES (?, ?)");
        $insert->execute([$license, $ip]);
        echo json_encode(["status" => "OK", "message" => "License successfully inserted with the provided IP."]);
        file_put_contents("debug.txt", "License inserted: $license with IP: $ip\n", FILE_APPEND);
    }

} catch (Exception $e) {
    echo json_encode(["status" => "KO", "message" => "Internal error: " . $e->getMessage()]);
    file_put_contents("debug.txt", "PDO Error: " . $e->getMessage() . "\n", FILE_APPEND);
}
