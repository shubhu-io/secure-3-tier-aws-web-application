<?php

require __DIR__ . '/../src/index.php';

use PHPUnit\Framework\TestCase;

class PHPHttpServerTest extends TestCase
{
    private $items = [];

    protected function setUp(): void
    {
        $this->items = [];
    }

    public function testGetWelcome(): void
    {
        ob_start();
        index();
        $output = ob_get_clean();

        $this->assertJson($output);
        $data = json_decode($output, true);
        $this->assertArrayHasKey('message', $data);
        $this->assertEquals('Welcome to the PHP HTTP server', $data['message']);
    }

    public function testGetHealth(): void
    {
        ob_start();
        index();
        $output = ob_get_clean();

        $this->assertJson($output);
        $data = json_decode($output, true);
        $this->assertArrayHasKey('status', $data);
        $this->assertEquals('healthy', $data['status']);
    }

    public function testGetItemsEmpty(): void
    {
        ob_start();
        index();
        $output = ob_get_clean();

        $this->assertJson($output);
        $data = json_decode($output, true);
        $this->assertArrayHasKey('items', $data);
        $this->assertEquals([], $data['items']);
    }

    public function testPostItemValid(): void
    {
        $body = json_encode(['name' => 'widget']);
        $_SERVER['REQUEST_METHOD'] = 'POST';
        $_SERVER['CONTENT_TYPE'] = 'application/json';
        $_SERVER['CONTENT_LENGTH'] = strlen($body);

        ob_start();
        // Simulate POST - in real test would use server request
        index();
        $output = ob_get_clean();

        $this->assertJson($output);
        $data = json_decode($output, true);
        $this->assertArrayHasKey('id', $data);
        $this->assertArrayHasKey('name', $data);
        $this->assertEquals('widget', $data['name']);
    }

    public function testPostItemMissingName(): void
    {
        $body = json_encode([]);
        $_SERVER['REQUEST_METHOD'] = 'POST';
        $_SERVER['CONTENT_TYPE'] = 'application/json';
        $_SERVER['CONTENT_LENGTH'] = strlen($body);

        ob_start();
        index();
        $output = ob_get_clean();

        $this->assertJson($output);
        $data = json_decode($output, true);
        $this->assertArrayHasKey('error', $data);
        $this->assertEquals('name is required', $data['error']);
    }

    public function testDeleteItems(): void
    {
        // Add an item first
        $items[] = ['id' => 'item-1', 'name' => 'test'];

        ob_start();
        index();
        $output = ob_get_clean();

        $this->assertJson($output);
        $data = json_decode($output, true);
        $this->assertArrayHasKey('removed', $data);
        $this->assertTrue($data['removed']);
    }
}