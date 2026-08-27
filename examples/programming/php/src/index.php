<?php

header('Content-Type: application/json');

$items = [];

$requestMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$requestUri = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);

switch ($requestMethod) {
    case 'GET':
        if ($requestUri === '/' || $requestUri === '') {
            http_response_code(200);
            echo json_encode(['message' => 'Welcome to the PHP HTTP server']);
            exit;
        }

        if ($requestUri === '/health') {
            http_response_code(200);
            echo json_encode(['status' => 'healthy']);
            exit;
        }

        if ($requestUri === '/items') {
            http_response_code(200);
            echo json_encode(['items' => $items]);
            exit;
        }

        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
        exit;

    case 'POST':
        if ($requestUri === '/items') {
            $body = file_get_contents('php://input');
            $data = json_decode($body, true);

            if (json_last_error() !== JSON_ERROR_NONE || !isset($data['name'])) {
                http_response_code(400);
                echo json_encode(['error' => 'name is required']);
                exit;
            }

            $id = 'item-' . uniqid();
            $items[$id] = ['id' => $id, 'name' => $data['name']];

            http_response_code(201);
            echo json_encode(['id' => $id, 'name' => $data['name']]);
            exit;
        }

        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
        exit;

    case 'DELETE':
        if ($requestUri === '/items') {
            $items = [];
            http_response_code(200);
            echo json_encode(['removed' => true]);
            exit;
        }

        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
        exit;

    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        exit;
}